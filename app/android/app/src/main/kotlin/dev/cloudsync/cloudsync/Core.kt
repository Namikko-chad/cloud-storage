package dev.cloudsync.cloudsync

import android.content.Context
import android.provider.DocumentsContract
import dev.cloudsync.mobilebind.Listener
import dev.cloudsync.mobilebind.Mobilebind
import java.io.File

/**
 * The Go core (gomobile AAR) runs in this process. Start is idempotent:
 * the activity, the foreground service and the documents provider all call
 * it, whoever comes first starts the core.
 */
object Core {
    data class Endpoint(val socket: String, val token: String)

    @Volatile private var endpoint: Endpoint? = null

    @Synchronized
    fun start(context: Context): Endpoint {
        endpoint?.let { return it }
        val app = context.applicationContext
        val dir = File(app.filesDir, "cloudsync").apply { mkdirs() }
        // A unix socket path must stay under ~100 bytes: keep it short.
        val socket = File(app.filesDir, "cs.sock").absolutePath
        val token = Mobilebind.start(dir.absolutePath, app.cacheDir.absolutePath, socket)
        Mobilebind.setListener(object : Listener {
            override fun onEvent(kind: Long, message: String?) {
                // Tree or state changed: the system file picker refreshes.
                if (kind == 1L || kind == 2L) {
                    val r = app.contentResolver
                    r.notifyChange(DocumentsContract.buildRootsUri(VaultProvider.authority(app)), null)
                    r.notifyChange(DocumentsContract.buildChildDocumentsUri(VaultProvider.authority(app), "/"), null, 0)
                }
            }
        })
        return Endpoint(socket, token).also { endpoint = it }
    }
}
