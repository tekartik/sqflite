import org.gradle.api.tasks.compile.JavaCompile

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
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

allprojects {
    tasks.withType<JavaCompile>().configureEach {
        options.compilerArgs.addAll(
            listOf(
                "-Xlint:unchecked",
                "-Xlint:deprecation",
                "-Xlint:cast",
                "-Xlint:classfile",
                "-Xlint:divzero",
                "-Xlint:empty",
                "-Xlint:fallthrough",
                "-Xlint:finally",
                "-Xlint:overrides",
                "-Xlint:path",
                "-Xlint:processing",
                "-Xlint:rawtypes",
                "-Xlint:try"
            )
        )
    }
}