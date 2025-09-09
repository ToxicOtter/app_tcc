plugins {
    id("com.android.application")
    id("kotlin-android")
    // O plugin do Flutter deve vir depois dos plugins Android e Kotlin
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.app_tcc_new"

    // use o compileSdk do Flutter, se preferir:
    // compileSdk = flutter.compileSdkVersion
    compileSdk = 36

    // Se o template do Flutter criou esta linha, mantenha:
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.app_tcc_new"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        // compatibilidade do bytecode
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        // ✅ habilita desugaring
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    buildTypes {
        release {
            // Assinatura: ajuste depois para sua keystore de release
            signingConfig = signingConfigs.getByName("debug")
            // Opcional:
            // isMinifyEnabled = true
            // isShrinkResources = true
        }
    }
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8")

    // ✅ desugaring (ajuste a versão se necessário)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation(platform("com.google.firebase:firebase-bom:34.2.0"))
    implementation("com.google.firebase:firebase-analytics")
}

flutter {
    source = "../.."
}
