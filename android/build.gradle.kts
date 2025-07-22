// android/build.gradle.kts (Projekt-niv�)
// Denna fil definierar byggkonfigurationen f�r hela ditt Android-projekt.
// Den �r skriven i Kotlin DSL.

buildscript {
    // Definierar var Gradle ska s�ka efter plugins och beroenden som beh�vs f�r byggprocessen.
    repositories {
        google()       // Google:s Maven-repository f�r Android-specifika beroenden.
        mavenCentral() // Maven Central: Ett stort repository f�r Java/Kotlin-bibliotek.
    }
    // Definierar beroenden som beh�vs f�r att bygga projektet sj�lvt (t.ex. Gradle-plugins).
    dependencies {
        // Firebase Google Services plugin. Denna �r n�dv�ndig f�r att din app ska kunna anv�nda Firebase.
        // VIKTIGT: Anv�nd den version som Firebase Console rekommenderar (t.ex. 4.4.2).
        classpath("com.google.gms:google-services:4.4.2")

        // Dessa �r standardplugins f�r Android Gradle Plugin och Kotlin Gradle Plugin.
        // De b�r redan finnas i din fil, men se till att versionerna matchar ditt projekt.
        // Om de saknas, uncommenta dem och justera versionerna vid behov.
        // classpath("com.android.tools.build:gradle:8.1.2") // Exempel, anpassa till din version
        // classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.8.0") // Exempel, anpassa till din version
    }
}

// Konfigurerar repositories f�r alla underprojekt i ditt Android-projekt.
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Definierar en ny byggkatalog f�r att undvika konflikter med Flutter's byggkatalog.
// Denna del av koden �r specifik f�r Flutter-projekt.
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

// Konfigurerar underprojekt f�r att s�kerst�lla korrekt byggordning.
subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    // S�kerst�ller att ':app' modulen utv�rderas innan andra underprojekt.
    project.evaluationDependsOn(":app")
}

// Definierar en 'clean'-uppgift f�r att rensa byggkatalogerna.
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}