package dev.cloudsync.cloudsync

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

// A FragmentActivity: BiometricPrompt needs one.
class MainActivity : FlutterFragmentActivity() {
    private val worker = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dev.cloudsync/biometric").setMethodCallHandler(Biometric(this))
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dev.cloudsync/core").setMethodCallHandler { call, result ->
            when (call.method) {
                // Starts the core (if needed) and returns where the UI connects.
                "start" -> worker.execute {
                    try {
                        val e = Core.start(this)
                        runCatching { CoreService.start(this) }
                        runOnUiThread { result.success(mapOf("socket" to e.socket, "token" to e.token)) }
                    } catch (t: Throwable) {
                        runOnUiThread { result.error("core", t.message, null) }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
