package pymag.dsl

import pymag.dsl.Docker

@NonCPS
def call() {
    node(){
        def dockeris = new Docker().IsDockerInstalled
        println "BUILDING...."
        stage("Build and put into container") {
            if (dockeris) {
                echo "BUILDING..."
                git url: "https://github.com/psiinon/bodgeit.git"
                sh 'mkdir -p $WORKSPACE/build/WEB-INF/classes'
                withAnt(installation: 'ant-latest') {
                    sh:
                    ant build test
                }
            } else {
                println "Docker is not installed"
            }
        }
        stage("Run container") {
            if (dockeris)
                sh 'docker run -d -v /var/lib/jenkins/workspace/bodgeit/build/bodgeit.war:/usr/local/tomcat/webapps/bodgeit.war --name bodgeit -p 8181:8080 tomcat'
        }
    }
}