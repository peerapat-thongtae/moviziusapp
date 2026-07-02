import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Optional release signing config. Present in CI (written from GitHub Secrets)
// and can be created locally; falls back to debug signing when absent so
// `flutter run --release` keeps working without a keystore.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.wbz.movizius"
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.wbz.movizius"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Required by the auth0_flutter plugin's manifest (redirect intent-filter).
        // Not a secret - the Auth0 domain is public (visible in every login URL) - so
        // it's safe to duplicate here from .env's AUTH0_DOMAIN; Gradle can't read
        // Dart's .env at build time.
        //
        // Using a custom scheme (not "https") so the redirect back into the app
        // doesn't depend on Android App Links verification. The plugin's bundled
        // intent-filter has no android:autoVerify, so Chrome won't honor an
        // unverified https deep link on Auth0's server-initiated redirect after
        // login - it just loads the callback URL as a normal page and 404s.
        manifestPlaceholders["auth0Domain"] = "dev-dxsfu1ajem7xnzwi.us.auth0.com"
        manifestPlaceholders["auth0Scheme"] = "com.wbz.movizius"
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Use the release keystore when key.properties is present (CI / local
            // release builds); otherwise fall back to debug signing.
            signingConfig = if (keystorePropertiesFile.exists())
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
