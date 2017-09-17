package com.pymag.dsl

import com.pymag.dsl.Docker

def call() {
    node {
        stage("Build and put into container") {
            echo "GIT"
            git branch: 'master', url: 'https://github.com/psiinon/bodgeit.git'
            echo "MKDIR"
            sh 'mkdir -p $WORKSPACE/build/WEB-INF/classes'
            echo "ANT"
            withAnt(installation: 'pipeline-ant') {
                sh 'ant build test'
            }
        }
        stage("Run container") {
            def docker_is = new Docker(this, "bodgeit").IsDockerInstalled
            echo "${docker_is}"
            if (docker_is)
                sh 'sudo docker run -d -v $WORKSPACE/bodgeit/build/bodgeit.war:/usr/local/tomcat/webapps/bodgeit.war --name bodgeit -p 8181:8080 tomcat'
            else
                echo "Docker is not installed"
        }
    }
}
