import com.android.build.gradle.LibraryExtension

allprojects {
    repositories {
        google()
        mavenCentral()
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

// AGP 8+ requires namespace in every Android library module.
// Some third-party plugins in pub cache may still omit it.
subprojects {
    plugins.withId("com.android.library") {
        extensions.configure<LibraryExtension>("android") {
            if (namespace == null) {
                val sanitizedName = project.name.replace('-', '_')
                val fallbackGroup = project.group.toString()
                namespace = if (fallbackGroup.isNotBlank() && fallbackGroup != "unspecified") {
                    "$fallbackGroup.$sanitizedName"
                } else {
                    "com.radiaudio.thirdparty.$sanitizedName"
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
