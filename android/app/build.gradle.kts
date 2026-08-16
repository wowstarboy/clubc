plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.myapp"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.jamiiclub.app"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ONGEZA HII BLOK YA SIGNING CONFIGS
    signingConfigs {
        create("release") {
            keyAlias = "star_alias"
            keyPassword = "12345678"
            storeFile = file("star.jks")
            storePassword = "12345678"
        }
    }

    buildTypes {
        release {
            // BADILISHA HAPA: Tumia release badala ya debug
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

subprojects {
    project.tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile::class) {
        kotlinOptions {
            jvmTarget = "1.8"
        }
    }
}

flutter {
    source = "../.."
}
