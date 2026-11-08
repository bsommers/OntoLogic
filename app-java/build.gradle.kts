plugins {
    java
    application
}

dependencies {
    implementation(project(":models-java"))
    implementation("jakarta.validation:jakarta.validation-api:3.0.2")
    runtimeOnly("org.hibernate.validator:hibernate-validator:8.0.1.Final")
    runtimeOnly("org.glassfish:jakarta.el:4.0.2")
}

application {
    mainClass.set("com.ontologic.app.Main")
}
