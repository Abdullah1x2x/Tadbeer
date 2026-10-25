import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Opt-in escape hatch for LOCAL release testing only (never for store uploads):
//   TADBEER_ALLOW_DEBUG_SIGNING=true flutter run --release
//   flutter build apk --release --android-project-arg=tadbeer.allowDebugSigning=true
val allowDebugSigning =
    (project.findProperty("tadbeer.allowDebugSigning") as String?)?.toBoolean() == true ||
        System.getenv("TADBEER_ALLOW_DEBUG_SIGNING")?.toBoolean() == true

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.tadbeer.app"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.tadbeer.app"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Never ship a debug-signed release by accident.
            // Without key.properties the release build fails (see the check
            // at the bottom of this file) unless allowDebugSigning is set.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else if (allowDebugSigning) {
                signingConfigs.getByName("debug")
            } else {
                null
            }
        }
    }

    dependenciesInfo {
        // Required by F-Droid / IzzyOnDroid: excludes Google's encrypted dependency blob from APKs
        includeInApk = false
        // Retains dependency metadata in Android App Bundles (.aab) for Google Play Console
        includeInBundle = true
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// Fail fast when a release artifact is requested without a real signing key.
gradle.taskGraph.whenReady {
    val buildsRelease = allTasks.any { task ->
        task.project == project &&
            (task.name.startsWith("assemble") || task.name.startsWith("bundle")) &&
            task.name.contains("Release")
    }
    if (buildsRelease && !keystorePropertiesFile.exists() && !allowDebugSigning) {
        throw GradleException(
            "Release signing key not found: android/key.properties is missing. " +
                "Create it (see README) or, for local testing only, set " +
                "TADBEER_ALLOW_DEBUG_SIGNING=true."
        )
    }
}
