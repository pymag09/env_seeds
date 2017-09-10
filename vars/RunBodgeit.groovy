package pymag.dsl

import pymag.dsl.Docker

@NonCPS
def call(body) {

//    def config = [:]
//    body.resolveStrategy = Closure.DELEGATE_FIRST
//    body.delegate = config
//    body()

    def dockeris=new Docker().IsDockerInstalled
    println "BUILDING...."
    stage("Build bodgeit") {
        if (dockeris) {
            echo "BUILDING..."
            git url: "https://github.com/psiinon/bodgeit.git"
            sh 'mkdir -p $WORKSPACE/build/WEB-INF/classes'
            withAnt(installation: 'ant-latest') {
                sh:
                ant build test
            }
        } else { println "Docker is not installed"}
    }
    stage("Create container") {
        if (dockeris)
            sh 'docker run -d -v /var/lib/jenkins/workspace/bodgeit/build/bodgeit.war:/usr/local/tomcat/webapps/bodgeit.war --name bodgeit -p 8181:8080 tomcat'
    }
}