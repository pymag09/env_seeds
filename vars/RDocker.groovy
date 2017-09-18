package com.pymag.dsl

import com.pymag.dsl.Docker

def call(body) {
    def config = [:]
    body.resolveStrategy = Closure.DELEGATE_FIRST
    body.delegate = config
    body()
    def container_name = config.command.split(" -").findAll({ it =~ /-name / }).last().split(" ").last()
    Docker d = new Docker("container_name")
    // docker run -d -v $WORKSPACE/bodgeit/build/bodgeit.war:/usr/local/tomcat/webapps/bodgeit.war --name bodgeit -p 8181:8080 tomcat
    node {
        stage("Run container ${container_name}") {
            if (d.IsContainerNotRunnig())
                sh "sudo ${config.command}"
            else {
                echo "Conteiner is running. Restart it."
                sh "sudo docker stop ${container_name}"
                sh "sudo docker start ${container_name}"
            }
        }
    }
}

