plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The workflow of releases hands over the key of the releases (ADR 0020).
// Without it a release build signs with the debug key, so that `flutter run
// --release` and the APK of every pull request still build.
val releaseKeystore: String? = System.getenv("BIRKA_KEYSTORE")

// Flutter builds its engine and the app only for `--target-platform`, arm64 in
// `make build-apk`, while the plugins bring libraries for more ABIs. An APK
// with those would install on a phone that cannot start it (ADR 0020).
val targetAbis: List<String>? =
    (findProperty("target-platform") as String?)?.split(",")?.map {
        when (it) {
            "android-arm" -> "armeabi-v7a"
            "android-arm64" -> "arm64-v8a"
            "android-x64" -> "x86_64"
            else -> throw GradleException("Unknown platform of Flutter: $it")
        }
    }

android {
    namespace = "io.github.artemchikolaev.birka"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // The plugin of notifications schedules with java.time (ADR 0025).
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "io.github.artemchikolaev.birka"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseKeystore != null) {
            create("release") {
                storeFile = file(releaseKeystore)
                storePassword = System.getenv("BIRKA_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("BIRKA_KEY_ALIAS")
                keyPassword = System.getenv("BIRKA_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                signingConfigs.getByName(if (releaseKeystore != null) "release" else "debug")
            // The plugin of notifications keeps its reminders through Gson,
            // whose classes R8 must leave as they are (ADR 0025).
            proguardFiles("proguard-rules.pro")
            // The plugin of Flutter has put its default ABIs here already.
            if (targetAbis != null) {
                ndk.abiFilters.clear()
                ndk.abiFilters += targetAbis
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
