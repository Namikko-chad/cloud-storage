package dev.cloudsync.cloudsync

import android.content.Context
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyPermanentlyInvalidatedException
import android.security.keystore.KeyProperties
import android.util.Base64
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricManager.Authenticators.BIOMETRIC_STRONG
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * Unlock by fingerprint: the vault password is sealed with an AES-GCM key in
 * the Android Keystore that can be used only right after a strong biometric
 * check. The key is dropped by the system when a new fingerprint is enrolled,
 * then the password has to be entered again. Only the ciphertext is stored
 * (app-private preferences); the plaintext never leaves this call and Dart.
 */
class Biometric(private val activity: FragmentActivity) : MethodChannel.MethodCallHandler {
    private val prefs = activity.getSharedPreferences("biometric", Context.MODE_PRIVATE)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            // available: the phone has a strong biometric enrolled; enabled: a password is saved.
            "status" -> result.success(mapOf("available" to available(), "enabled" to enabled()))
            "enable" -> enable(call.argument<String>("password") ?: "", call.argument<String>("title") ?: "", call.argument<String>("cancel") ?: "", result)
            "unlock" -> unlock(call.argument<String>("title") ?: "", call.argument<String>("cancel") ?: "", result)
            "disable" -> {
                disable()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun available() =
        BiometricManager.from(activity).canAuthenticate(BIOMETRIC_STRONG) == BiometricManager.BIOMETRIC_SUCCESS

    private fun enabled() = prefs.contains(DATA) && prefs.contains(IV)

    private fun disable() {
        prefs.edit().clear().apply()
        runCatching { keyStore().deleteEntry(KEY) }
    }

    private fun enable(password: String, title: String, cancel: String, result: MethodChannel.Result) {
        if (password.isEmpty()) return result.error("args", "empty password", null)
        val cipher = try {
            runCatching { keyStore().deleteEntry(KEY) }
            Cipher.getInstance(TRANSFORM).apply { init(Cipher.ENCRYPT_MODE, newKey()) }
        } catch (t: Throwable) {
            return result.error("keystore", t.message, null)
        }
        prompt(cipher, title, cancel, result) { c ->
            val data = c.doFinal(password.toByteArray(Charsets.UTF_8))
            prefs.edit()
                .putString(DATA, Base64.encodeToString(data, Base64.NO_WRAP))
                .putString(IV, Base64.encodeToString(c.iv, Base64.NO_WRAP))
                .apply()
            true
        }
    }

    private fun unlock(title: String, cancel: String, result: MethodChannel.Result) {
        val data = prefs.getString(DATA, null)
        val iv = prefs.getString(IV, null)
        if (data == null || iv == null) return result.error("disabled", "no saved password", null)
        val cipher = try {
            val key = keyStore().getKey(KEY, null) as? SecretKey ?: throw KeyPermanentlyInvalidatedException()
            Cipher.getInstance(TRANSFORM).apply {
                init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(128, Base64.decode(iv, Base64.NO_WRAP)))
            }
        } catch (_: KeyPermanentlyInvalidatedException) {
            disable()
            return result.error("invalidated", "fingerprints changed", null)
        } catch (t: Throwable) {
            return result.error("keystore", t.message, null)
        }
        prompt(cipher, title, cancel, result) { c ->
            String(c.doFinal(Base64.decode(data, Base64.NO_WRAP)), Charsets.UTF_8)
        }
    }

    private fun prompt(cipher: Cipher, title: String, cancel: String, result: MethodChannel.Result, done: (Cipher) -> Any) {
        val info = BiometricPrompt.PromptInfo.Builder()
            .setTitle(title)
            .setNegativeButtonText(cancel)
            .setAllowedAuthenticators(BIOMETRIC_STRONG)
            .build()
        val cb = object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationSucceeded(r: BiometricPrompt.AuthenticationResult) {
                try {
                    result.success(done(r.cryptoObject?.cipher ?: cipher))
                } catch (t: Throwable) {
                    result.error("crypto", t.message, null)
                }
            }

            override fun onAuthenticationError(code: Int, msg: CharSequence) {
                val canceled = code == BiometricPrompt.ERROR_USER_CANCELED ||
                    code == BiometricPrompt.ERROR_NEGATIVE_BUTTON ||
                    code == BiometricPrompt.ERROR_CANCELED
                result.error(if (canceled) "canceled" else "error", msg.toString(), null)
            }
            // onAuthenticationFailed: a finger that doesn't match; the prompt stays and lets the user retry.
        }
        BiometricPrompt(activity, ContextCompat.getMainExecutor(activity), cb)
            .authenticate(info, BiometricPrompt.CryptoObject(cipher))
    }

    private fun keyStore() = KeyStore.getInstance(STORE).apply { load(null) }

    private fun newKey(): SecretKey {
        val spec = KeyGenParameterSpec.Builder(KEY, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(256)
            .setUserAuthenticationRequired(true)
            .setInvalidatedByBiometricEnrollment(true)
            .apply {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    setUserAuthenticationParameters(0, KeyProperties.AUTH_BIOMETRIC_STRONG)
                }
            }
            .build()
        return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, STORE).run {
            init(spec)
            generateKey()
        }
    }

    companion object {
        private const val STORE = "AndroidKeyStore"
        private const val KEY = "cloudsync.unlock"
        private const val TRANSFORM = "AES/GCM/NoPadding"
        private const val DATA = "data"
        private const val IV = "iv"
    }
}
