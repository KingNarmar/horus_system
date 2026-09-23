import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val signingProperties = Properties()
val signingPropertiesFile = rootProject.file("key.properties")
val releaseTaskRequested = gradle.startParameter.taskNames.any { taskName ->
    taskName.contains("release", ignoreCase = true)
}

if (signingPropertiesFile.exists()) {
    signingPropertiesFile.inputStream().use(signingProperties::load)
} else if (releaseTaskRequested) {
    throw GradleException(
        "Missing android/key.properties. Copy android/key.properties.example and configure the release upload keystore.",
    )
}

fun Properties.requireSigningValue(key: String): String =
    getProperty(key)?.takeIf { it.isNotBlank() }
        ?: throw GradleException("Missing '$key' in android/key.properties.")

android {
    namespace = "com.kingnarmar.horus"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.kingnarmar.horus"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (signingPropertiesFile.exists()) {
            create("release") {
                keyAlias = signingProperties.requireSigningValue("keyAlias")
                keyPassword = signingProperties.requireSigningValue("keyPassword")
                storeFile = file(signingProperties.requireSigningValue("storeFile"))
                storePassword = signingProperties.requireSigningValue("storePassword")
            }
        }
    }

    buildTypes {
        release {
            if (signingPropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

flutter {
    source = "../.."
}
