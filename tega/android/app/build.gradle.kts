plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

val keyProperties = Properties()
val keyPropertiesFile = rootProject.file("android/key.properties")
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

android {
    namespace = "com.tega"
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
        applicationId = "com.sandspace.tega"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keyPropertiesFile.exists()) {
            val storeFileProp = keyProperties["storeFile"] as String?
            val storePasswordProp = keyProperties["storePassword"] as String?
            val keyAliasProp = keyProperties["keyAlias"] as String?
            val keyPasswordProp = keyProperties["keyPassword"] as String?
            
            // Only create release signing config if all properties are valid
            if (storeFileProp != null && storePasswordProp != null && 
                keyAliasProp != null && keyPasswordProp != null) {
                val keystoreFile = file(storeFileProp)
                if (keystoreFile.exists()) {
                    create("release") {
                        storeFile = keystoreFile
                        storePassword = storePasswordProp
                        keyAlias = keyAliasProp
                        keyPassword = keyPasswordProp
                    }
                }
            }
        }
    }

    buildTypes {
        getByName("release") {
            // Only use release signing if it exists and is properly configured
            val releaseSigningConfig = signingConfigs.findByName("release")
            if (releaseSigningConfig != null) {
                signingConfig = releaseSigningConfig
            }
            // If release signing is not configured, it will use debug signing by default
            
            // Configure native library stripping
            ndk {
                debugSymbolLevel = "FULL"
            }
        }
    }
    
    // Configure packaging options to handle native libraries
    packaging {
        jniLibs {
            useLegacyPackaging = false
        }
    }
}

flutter {
    source = "../.."

4}
