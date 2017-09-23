package com.pymag.dsl

def call(body) {
    def config = [:]
    body.resolveStrategy = Closure.DELEGATE_FIRST
    body.delegate = config
    body()

    node {
        ansiColor('xterm') {
            stage("Build and put into container") {
                echo "\\e[31;1m++++++++ GIT ++++++++\e[0m"
                git branch: 'master', url: 'https://github.com/psiinon/bodgeit.git'
                echo "\\e[31;1m++++++++ MKDIR ++++++++\e[0m"
                sh 'mkdir -p $WORKSPACE/build/WEB-INF/classes'
                echo "\\e[31;1m++++++++ ANT ++++++++\\e[0m"
                withAnt(installation: "${config.anttool}") {
                    sh 'ant build test'
                }
                archiveArtifacts artifacts: 'build/bodgeit.war', fingerprint: true, onlyIfSuccessful: true
            }
        }
    }
}
