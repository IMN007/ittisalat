// android/build.gradle.kts (Projekt-nivå)
// Denna fil definierar byggkonfigurationen för hela ditt Android-projekt.
// Den är skriven i Kotlin DSL.

buildscript {
    // Definierar var Gradle ska söka efter plugins och beroenden som behövs för byggprocessen.
    repositories {
        google()       // Google:s Maven-repository för Android-specifika beroenden.
        mavenCentral() // Maven Central: Ett stort repository för Java/Kotlin-bibliotek.
    }
    // Definierar beroenden som behövs för att bygga projektet självt (t.ex. Gradle-plugins).
    dependencies {
        // Firebase Google Services plugin. Denna är nödvändig för att din app ska kunna använda Firebase.
        // VIKTIGT: Använd den version som Firebase Console rekommenderar (t.ex. 4.4.2).
        classpath("com.google.gms:google-services:4.4.2")

        // Dessa är standardplugins för Android Gradle Plugin och Kotlin Gradle Plugin.
        // De bör redan finnas i din fil, men se till att versionerna matchar ditt projekt.
        // Om de saknas, uncommenta dem och justera versionerna vid behov.
        // classpath("com.android.tools.build:gradle:8.1.2") // Exempel, anpassa till din version
        // classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.8.0") // Exempel, anpassa till din version
    }
}

// Konfigurerar repositories för alla underprojekt i ditt Android-projekt.
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Definierar en ny byggkatalog för att undvika konflikter med Flutter's byggkatalog.
// Denna del av koden är specifik för Flutter-projekt.
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

// Konfigurerar underprojekt för att säkerställa korrekt byggordning.
subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    // Säkerställer att ':app' modulen utvärderas innan andra underprojekt.
    project.evaluationDependsOn(":app")
}

// Definierar en 'clean'-uppgift för att rensa byggkatalogerna.
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}