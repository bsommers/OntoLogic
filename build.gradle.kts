plugins {
    java
    id("org.jetbrains.kotlin.jvm") version "1.9.24"
}

allprojects {
    repositories {
        mavenCentral()
    }
}

tasks.register<Exec>("lintOntology") {
    group = "verification"
    description = "Runs the Haskell-based linter to check for logical contradictions."
    
    // Calls the Haskell binary with the linter flag
    // Assuming ontologic-exe is in PATH or built via stack
    commandLine("stack", "exec", "ontologic-exe", "--", "--input", "${rootDir}/logic/fleet.logic", "--target", "lint")
    
    // Stop the build if the linter finds errors
    isIgnoreExitValue = false 
}

tasks.register<Exec>("generateJavaModels") {
    group = "ontology"
    description = "Generates Java POJOs from FOL logic files."
    dependsOn("lintOntology")
    
    // Generate into models-java source set
    commandLine("stack", "exec", "ontologic-exe", "--", "-i", "${rootDir}/logic/fleet.logic", "-t", "java", "-o", "${rootDir}/models-java/src/generated/java")
}

subprojects {
    apply(plugin = "java")

    tasks.withType<JavaCompile> {
        if (project.name == "models-java") {
            dependsOn(":generateJavaModels")
        }
    }
    
    configure<JavaPluginExtension> {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
        kotlinOptions {
            jvmTarget = "17"
        }
    }
}

