plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // ✅ Plugin de Firebase
}

android {
    namespace = "com.muni.incidencias"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        // 👇 Identificador único de tu app (debe coincidir con Firebase)
        applicationId = "com.muni.incidencias"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // 🔧 Por ahora usa la misma config que debug, hasta tener firma propia
            signingConfig = signingConfigs.getByName("debug")
            // Opcional: minify si deseas optimizar builds release
            // isMinifyEnabled = true
            // proguardFiles(
            //     getDefaultProguardFile("proguard-android-optimize.txt"),
            //     "proguard-rules.pro"
            // )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

flutter {
    source = "../.."
}

dependencies {
    // 🔥 Firebase BOM (versión recomendada)
    implementation(platform("com.google.firebase:firebase-bom:33.3.0"))

    // 🔹 Firebase Core (inicialización)
    implementation("com.google.firebase:firebase-analytics")

    // Opcional: otros módulos que usarás (ya controlados por pubspec.yaml)
    // implementation("com.google.firebase:firebase-auth")
    // implementation("com.google.firebase:firebase-firestore")
    // implementation("com.google.firebase:firebase-storage")
}
