package com.pymag.dsl

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
    }
}
