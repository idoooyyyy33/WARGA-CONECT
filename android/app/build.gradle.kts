plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
<<<<<<< HEAD
    namespace = "com.example.warga_conect_pt2"
=======
<<<<<<< HEAD
    namespace = "com.example.warga_conect_pt2"
=======
    namespace = "com.example.wargaconnect_ui"
>>>>>>> 74c196e45a5cdab8638cf41ea827a7b1cb319211
>>>>>>> c69e2c959f7e5b18b7f44f1ce2e59fab823a5f5b
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
<<<<<<< HEAD
        applicationId = "com.example.warga_conect_pt2"
=======
<<<<<<< HEAD
        applicationId = "com.example.warga_conect_pt2"
=======
        applicationId = "com.example.wargaconnect_ui"
>>>>>>> 74c196e45a5cdab8638cf41ea827a7b1cb319211
>>>>>>> c69e2c959f7e5b18b7f44f1ce2e59fab823a5f5b
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
