// Denna fil definierar byggkonfigurationen för din app-modul (Android).
// Den är skriven i Kotlin DSL.

plugins {
    // Standard Android-applikationsplugin
    id("com.android.application")
    // Kotlin Android-plugin för att stödja Kotlin-kod
    kotlin("android")
    // Flutter Gradle Plugin, måste appliceras efter Android- och Kotlin-plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Plugin för att registrera Flutter-plugins
    id("dev.flutter.flutter-plugin-registrant") // Lade till detta plugin
    // Firebase Google Services plugin. Denna läser din google-services.json-fil.
    // VIKTIGT: Se till att du har placerat google-services.json i android/app/
    id("com.google.gms.google-services")
}

android {
    // Konfigurerar Android SDK-versioner och standardinställningar för din app.
    // Anpassa dessa värden baserat på ditt projekts krav.
    namespace = "com.example.ittisal2_new" // Ditt unika paketnamn för det nya projektet
    compileSdk = 34 // Den Android SDK-version som används för att kompilera din app

    defaultConfig {
        // Minsta Android SDK-version som din app stöder
        minSdk = 24 // Ändrad från 21 till 24 för Jitsi Meet och moderna Firebase-krav
        // Mål-Android SDK-version för din app
        targetSdk = 34
        // Version av din applikationskod (helttal)
        versionCode = 1
        // Visningsversion av din app (sträng)
        versionName = "1.0.0"
        // Ditt unika applikations-ID (paketnamn)
        applicationId = "com.example.ittisal2_new" // SE TILL ATT DETTA MATCHAR DITT FIREBASE-PROJEKT
    }

    // Konfigurerar byggtyper (t.ex. debug, release)
    buildTypes {
        release {
            // Anger om appen är felsökbar (false för release)
            isDebuggable = false
            // Anger om kodoptimering ska tillämpas (true för release)
            isMinifyEnabled = true
            // Anger filen för ProGuard/R8-regler för kodoptimering
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            // Anger om appen är felsökbar (true för debug)
            isDebuggable = true
            // Anger om kodoptimering ska tillämpas (false för debug)
            isMinifyEnabled = false
        }
    }
}

flutter {
    // Anger sökvägen till din Flutter SDK
    source = rootProject.layout.projectDirectory.dir("../..")
}

dependencies {
    // Firebase SDK:er som din app behöver för att kommunicera med Firebase-tjänster.
    // Vi använder Firebase Bill of Materials (BOM) för att hantera versioner konsekvent.
    // VIKTIGT: Använd den senaste BOM-versionen som Firebase Console rekommenderar.
    // Just nu är 33.1.0 en aktuell version, men dubbelkolla alltid i Firebase Console.
    implementation(platform("com.google.firebase:firebase-bom:33.1.0"))

    // Lägg till specifika Firebase-tjänster som din app använder.
    // - firebase-analytics-ktx: För Google Analytics (rekommenderas av Firebase)
    implementation("com.google.firebase:firebase-analytics-ktx")
    // - firebase-auth-ktx: För Firebase Authentication (användarhantering)
    implementation("com.google.firebase:firebase-auth-ktx")
    // - firebase-firestore-ktx: För Cloud Firestore (databasen)
    implementation("com.google.firebase:firebase-firestore-ktx")

    // Jitsi Meet SDK-beroende
    implementation("org.jitsi.meet:sdk:11.3.0") // Lade till Jitsi Meet SDK

    // Om du använder andra Firebase-tjänster, lägg till dem här:
    // implementation("com.google.firebase:firebase-database-ktx") // För Realtime Database
    // implementation("com.google.firebase:firebase-storage-ktx")    // För Cloud Storage

    // Dina andra befintliga beroenden från Flutter-plugins kommer också att finnas här.
    // Exempel:
    // implementation("androidx.work:work-runtime-ktx:2.7.0")
    // implementation(kotlin("stdlib-jdk8"))
}
