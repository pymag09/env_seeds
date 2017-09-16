package pymag.dsl

import pymag.dsl.Docker


def call() {
    node {
        stage("Build and put into container") {
            echo "GIT"
            git branch: 'master', url: 'https://github.com/psiinon/bodgeit.git'
            //        checkout([$class: 'GitSCM',
            //                  branches: [[name: '*/master']],
            //                  doGenerateSubmoduleConfigurations: false,
            //                  extensions: [[$class: 'CleanCheckout']],
            //                  submoduleCfg: [],
            //                  userRemoteConfigs: [[credentialsId: 'git-credentials', url: 'https://github.com/psiinon/bodgeit.git']]
            //        ])
            echo "MKDIR"
            sh 'mkdir -p $WORKSPACE/build/WEB-INF/classes'
            echo "ANT"
            withAnt(installation: 'ant-latest') {
                sh:
                ant build test
            }
        }
        stage("Run container") {
            def dockeris = new Docker().IsDockerInstalled
            if (dockeris)
                sh 'docker run -d -v /var/lib/jenkins/workspace/bodgeit/build/bodgeit.war:/usr/local/tomcat/webapps/bodgeit.war --name bodgeit -p 8181:8080 tomcat'
        }
    }
}