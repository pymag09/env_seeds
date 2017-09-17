package pymag.dsl

import pymag.dsl.Docker

@NonCPS
def call() {
    node {
        stage("Build and put into container") {
            echo "GIT"
            git branch: 'master', url: 'https://github.com/psiinon/bodgeit.git'
            echo "MKDIR"
            sh 'mkdir -p $WORKSPACE/build/WEB-INF/classes'
            echo "ANT"
            withAnt(installation: 'pipeline-ant') {
                //sh 'ant build test'
                sh 'ant build'
            }
        }
        stage("Run container") {
            def dockeris = new Docker().IsDockerInstalled
            if (dockeris)
                sh 'docker run -d -v $WORKSPACE/bodgeit/build/bodgeit.war:/usr/local/tomcat/webapps/bodgeit.war --name bodgeit -p 8181:8080 tomcat'
        }
    }
}