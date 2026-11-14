import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing: android/key.properties (storeFile, storePassword, keyAlias,
// keyPassword) or the same values in CS_KEYSTORE / CS_KEYSTORE_PASSWORD /
// CS_KEY_ALIAS / CS_KEY_PASSWORD (CI). Without them release builds use the debug key.
val keyProps = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}
fun signing(prop: String, env: String): String? = keyProps.getProperty(prop) ?: System.getenv(env)
val releaseStore = signing("storeFile", "CS_KEYSTORE")

android {
    namespace = "dev.cloudsync.cloudsync"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "dev.cloudsync.cloudsync"
        // openProxyFileDescriptor (streamed reads in the documents provider).
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseStore != null) {
            create("release") {
                storeFile = file(releaseStore)
                storePassword = signing("storePassword", "CS_KEYSTORE_PASSWORD")
                keyAlias = signing("keyAlias", "CS_KEY_ALIAS")
                keyPassword = signing("keyPassword", "CS_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(if (releaseStore != null) "release" else "debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(files("libs/cloudsync.aar"))
    // Unlock by fingerprint (Biometric.kt); AppCompat for its dialog on Android 8.
    implementation("androidx.biometric:biometric:1.1.0")
    implementation("androidx.appcompat:appcompat:1.7.0")
}
