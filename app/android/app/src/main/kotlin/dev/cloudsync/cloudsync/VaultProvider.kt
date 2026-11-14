package dev.cloudsync.cloudsync

import android.content.Context
import android.database.Cursor
import android.database.MatrixCursor
import android.os.CancellationSignal
import android.os.Handler
import android.os.HandlerThread
import android.os.ParcelFileDescriptor
import android.os.ProxyFileDescriptorCallback
import android.os.storage.StorageManager
import android.provider.DocumentsContract.Document
import android.provider.DocumentsContract.Root
import android.provider.DocumentsProvider
import android.system.ErrnoException
import android.system.OsConstants
import android.webkit.MimeTypeMap
import dev.cloudsync.mobilebind.Mobilebind
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.FileNotFoundException

/**
 * Shows the vault in the system file picker ("Files") and to other apps.
 * Document ids are vault paths. Reads stream from the core and download
 * only the chunks asked for; a write takes the vault's write lock (so other
 * devices see the file as open), goes to a temp file and is uploaded when
 * the app closes it.
 */
class VaultProvider : DocumentsProvider() {
    private val io by lazy { Handler(HandlerThread("vault-io").apply { start() }.looper) }

    override fun onCreate(): Boolean = true

    private fun ensureCore() {
        val c = context ?: return
        Core.start(c)
    }

    override fun queryRoots(projection: Array<out String>?): Cursor {
        ensureCore()
        val c = MatrixCursor(projection ?: ROOT_COLUMNS)
        val unlocked = Mobilebind.unlocked()
        c.newRow().apply {
            add(Root.COLUMN_ROOT_ID, "vault")
            add(Root.COLUMN_DOCUMENT_ID, "/")
            add(Root.COLUMN_TITLE, "CloudSync")
            add(Root.COLUMN_SUMMARY, context!!.getString(if (unlocked) R.string.vault_root_unlocked else R.string.vault_root_locked))
            add(Root.COLUMN_ICON, R.mipmap.ic_launcher)
            add(Root.COLUMN_FLAGS, if (unlocked) Root.FLAG_SUPPORTS_CREATE or Root.FLAG_SUPPORTS_IS_CHILD else 0)
        }
        c.setNotificationUri(context!!.contentResolver, android.provider.DocumentsContract.buildRootsUri(authority(context!!)))
        return c
    }

    override fun queryDocument(documentId: String, projection: Array<out String>?): Cursor {
        ensureCore()
        val c = MatrixCursor(projection ?: DOC_COLUMNS)
        if (documentId == "/" && !Mobilebind.unlocked()) {
            addRow(c, JSONObject().put("path", "/").put("name", "CloudSync").put("dir", true))
            return c
        }
        addRow(c, JSONObject(call { Mobilebind.stat(documentId) }))
        return c
    }

    override fun queryChildDocuments(parentId: String, projection: Array<out String>?, sortOrder: String?): Cursor {
        ensureCore()
        val c = MatrixCursor(projection ?: DOC_COLUMNS)
        if (Mobilebind.unlocked()) {
            val list = JSONArray(call { Mobilebind.list(parentId) })
            for (i in 0 until list.length()) addRow(c, list.getJSONObject(i))
        }
        c.setNotificationUri(
            context!!.contentResolver,
            android.provider.DocumentsContract.buildChildDocumentsUri(authority(context!!), parentId),
        )
        return c
    }

    override fun isChildDocument(parentId: String, documentId: String): Boolean =
        parentId == "/" || documentId.startsWith("$parentId/")

    override fun openDocument(documentId: String, mode: String, signal: CancellationSignal?): ParcelFileDescriptor {
        ensureCore()
        if (mode == "r") return openRead(documentId)
        val ctx = context!!
        call { Mobilebind.lock(documentId) } // fails if open on another device
        val tmp = File.createTempFile("edit-", ".tmp", ctx.cacheDir)
        val exists = runCatching { Mobilebind.stat(documentId) }.isSuccess
        if (exists && !mode.contains('t')) {
            tmp.delete()
            call { Mobilebind.download(documentId, tmp.absolutePath) }
        }
        val pfdMode = ParcelFileDescriptor.parseMode(mode)
        return ParcelFileDescriptor.open(tmp, pfdMode, io) { err ->
            try {
                if (err == null && pfdMode != ParcelFileDescriptor.MODE_READ_ONLY) {
                    Mobilebind.putFile(documentId, tmp.absolutePath)
                }
            } catch (_: Exception) {
                // The core keeps nothing here; the edit is in tmp until next time.
                return@open
            } finally {
                Mobilebind.unlock(documentId)
            }
            tmp.delete()
        }
    }

    private fun openRead(path: String): ParcelFileDescriptor {
        val size = JSONObject(call { Mobilebind.stat(path) }).optLong("size")
        val sm = context!!.getSystemService(StorageManager::class.java)
        return sm.openProxyFileDescriptor(ParcelFileDescriptor.MODE_READ_ONLY, object : ProxyFileDescriptorCallback() {
            override fun onGetSize(): Long = size

            override fun onRead(offset: Long, n: Int, data: ByteArray): Int {
                try {
                    val got = Mobilebind.readAt(path, offset, n.toLong())
                    System.arraycopy(got, 0, data, 0, got.size)
                    return got.size
                } catch (e: Exception) {
                    throw ErrnoException("read", OsConstants.EIO)
                }
            }

            override fun onRelease() {}
        }, io)
    }

    override fun createDocument(parentId: String, mimeType: String, displayName: String): String {
        val path = (if (parentId == "/") "" else parentId) + "/" + displayName.replace('/', '_')
        if (mimeType == Document.MIME_TYPE_DIR) {
            call { Mobilebind.mkdir(path) }
        } else {
            val empty = File.createTempFile("new-", ".tmp", context!!.cacheDir)
            try {
                call { Mobilebind.putFile(path, empty.absolutePath) }
            } finally {
                empty.delete()
            }
        }
        return path
    }

    override fun deleteDocument(documentId: String) {
        call { Mobilebind.remove(documentId) }
    }

    override fun renameDocument(documentId: String, displayName: String): String {
        val parent = documentId.substringBeforeLast('/', "")
        val to = "$parent/${displayName.replace('/', '_')}"
        call { Mobilebind.rename(documentId, to) }
        return to
    }

    private fun addRow(c: MatrixCursor, e: JSONObject) {
        val dir = e.optBoolean("dir")
        val name = e.optString("name")
        val mime = if (dir) Document.MIME_TYPE_DIR else mimeOf(name)
        var flags = Document.FLAG_SUPPORTS_DELETE or Document.FLAG_SUPPORTS_RENAME
        flags = flags or if (dir) Document.FLAG_DIR_SUPPORTS_CREATE else Document.FLAG_SUPPORTS_WRITE
        if (e.optString("path") == "/") flags = if (Mobilebind.unlocked()) Document.FLAG_DIR_SUPPORTS_CREATE else 0
        c.newRow().apply {
            add(Document.COLUMN_DOCUMENT_ID, e.optString("path"))
            add(Document.COLUMN_DISPLAY_NAME, name)
            add(Document.COLUMN_MIME_TYPE, mime)
            add(Document.COLUMN_SIZE, if (dir) null else e.optLong("size"))
            add(Document.COLUMN_LAST_MODIFIED, e.optLong("mtime_ms").takeIf { it > 0 })
            add(Document.COLUMN_FLAGS, flags)
        }
    }

    private fun mimeOf(name: String): String {
        val ext = name.substringAfterLast('.', "").lowercase()
        return MimeTypeMap.getSingleton().getMimeTypeFromExtension(ext) ?: "application/octet-stream"
    }

    private fun <T> call(f: () -> T): T = try {
        f()
    } catch (e: Exception) {
        throw FileNotFoundException(e.message)
    }

    companion object {
        fun authority(context: Context) = "${context.packageName}.documents"

        private val ROOT_COLUMNS = arrayOf(
            Root.COLUMN_ROOT_ID, Root.COLUMN_DOCUMENT_ID, Root.COLUMN_TITLE, Root.COLUMN_SUMMARY,
            Root.COLUMN_ICON, Root.COLUMN_FLAGS,
        )
        private val DOC_COLUMNS = arrayOf(
            Document.COLUMN_DOCUMENT_ID, Document.COLUMN_DISPLAY_NAME, Document.COLUMN_MIME_TYPE,
            Document.COLUMN_SIZE, Document.COLUMN_LAST_MODIFIED, Document.COLUMN_FLAGS,
        )
    }
}
