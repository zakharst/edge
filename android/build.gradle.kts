allprojects {
    repositories {
        google()
        mavenCentral()
    }
    // Pin a single androidx.work version across ALL modules (incl. the workmanager
    // plugin). workmanager_android 0.10.9 requires androidx.work 2.9.0+ (stopReason,
    // periodicityInfo), and app/build.gradle.kts implements work-runtime-ktx:2.9.1.
    // Forcing 2.9.1 guarantees consistent runtime and resolves Kotlin compiler errors.
    configurations.all {
        resolutionStrategy {
            force("androidx.work:work-runtime:2.9.1")
            force("androidx.work:work-runtime-ktx:2.9.1")
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
