// android/build.gradle.kts (Projekt-nivå)
// Denna fil definierar byggkonfigurationen för hela ditt Android-projekt.
// Den är skriven i Kotlin DSL.

// Detta block hanterar konfigurationen av plugins som används i hela projektet.
// DETTA MÅSTE VARA DET FÖRSTA BLOCKET I FILEN.
pluginManagement {
    repositories {
        // Gradle Plugin Portal är standard för de flesta Gradle-plugins.
        gradlePluginPortal()
        // Google Maven-repository för Android-specifika plugins och beroenden.
        google()
        // Maven Central är ett stort repository för Java/Kotlin-bibliotek.
        mavenCentral()
        // Detta är den viktiga raden för Flutter-plugins.
        // Den pekar på den lokala katalogen där Flutter genererar plugin-registreringen.
        maven { url = uri("../.flutter-plugins/android/") }
    }
}

// Detta block definierar var Gradle ska söka efter plugins och beroenden som behövs för byggprocessen.
buildscript {
    repositories {
        google()       // Google:s Maven-repository för Android-specifika beroenden.
        mavenCentral() // Maven Central: Ett stort repository för Java/Kotlin-bibliotek.
    }
    // Definierar beroenden som behövs för att bygga projektet självt (t.ex. Gradle-plugins).
    dependencies {
        // Firebase Google Services plugin. Denna är nödvändig för att din app ska kunna anvnda Firebase.
        // VIKTIGT: Anvnd den version som Firebase Console rekommenderar (t.ex. 4.4.2).
        classpath("com.google.gms:google-services:4.4.2")

        // Dessa r standardplugins fr Android Gradle Plugin och Kotlin Gradle Plugin.
        // De br redan finnas i din fil, men se till att versionerna matchar ditt projekt.
        // Om de saknas, uncommenta dem och justera versionerna vid behov.
        // classpath("com.android.tools.build:gradle:8.1.2") // Exempel, anpassa till din version
        // classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.8.0") // Exempel, anpassa till din version
    }
}

// Konfigurerar repositories fr alla underprojekt i ditt Android-projekt.
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Definierar en ny byggkatalog fr att undvika konflikter med Flutter's byggkatalog.
// Denna del av koden r specifik fr Flutter-projekt.
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

// Konfigurerar underprojekt fr att skerstlla korrekt byggordning.
subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    // Skerstller att ':app' modulen utvrderas innan andra underprojekt.
    project.evaluationDependsOn(":app")
}

// Definierar en 'clean'-uppgift fr att rensa byggkatalogerna.
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
