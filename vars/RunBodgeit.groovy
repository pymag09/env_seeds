package pymag.dsl

import pymag.dsl.Docker

@NonCPS
def call() {
    def dockeris = new Docker().IsDockerInstalled
    println "BUILDING...."
    stage("Build and put into container") {
        echo "BUILDING..."
        git url: "https://github.com/psiinon/bodgeit.git"
        sh 'mkdir -p $WORKSPACE/build/WEB-INF/classes'
        withAnt(installation: 'ant-latest') {
            sh:
            ant build test
        }
    }
    stage("Run container") {
        if (dockeris)
            sh 'docker run -d -v /var/lib/jenkins/workspace/bodgeit/build/bodgeit.war:/usr/local/tomcat/webapps/bodgeit.war --name bodgeit -p 8181:8080 tomcat'
    }
}