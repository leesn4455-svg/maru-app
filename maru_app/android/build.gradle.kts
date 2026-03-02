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
    
    // [완벽 해결] "이미 평가됨" 에러를 피하기 위해 evaluationDependsOn 위로 위치를 옮겼습니다!
    afterEvaluate {
        val android = extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        android?.compileSdkVersion(36)
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}