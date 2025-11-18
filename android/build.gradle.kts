import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Plugin de Google Services (para conectar con Firebase)
        classpath("com.google.gms:google-services:4.4.2")

        // Plugin de Gradle para Flutter (necesario)
        classpath("com.android.tools.build:gradle:8.5.2")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 🔧 Ajuste opcional para cambiar carpeta de compilación
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
    project.evaluationDependsOn(":app")
}

// 🔥 Limpieza del proyecto
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
