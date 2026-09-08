import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keyProperties = Properties()
val keyPropertiesFile = rootProject.file("key.properties")
val releaseTaskRequested = gradle.startParameter.taskNames.any { taskName ->
    taskName.contains("release", ignoreCase = true)
}

if (keyPropertiesFile.exists()) {
    keyPropertiesFile.inputStream().use(keyProperties::load)
} else if (releaseTaskRequested) {
    throw GradleException(
        "Missing android/key.properties. Copy android/key.properties.example and configure the release upload keystore.",
    )
}

fun Properties.requireValue(key: String): String =
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
        if (keyPropertiesFile.exists()) {
            create("release") {
                keyAlias = keyProperties.requireValue("keyAlias")
                keyPassword = keyProperties.requireValue("keyPassword")
                storeFile = file(keyProperties.requireValue("storeFile"))
                storePassword = keyProperties.requireValue("storePassword")
            }
        }
    }

    buildTypes {
        release {
            if (keyPropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

flutter {
    source = "../.."
}
