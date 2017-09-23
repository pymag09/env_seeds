package com.pymag.dsl

def call(body) {
    def config = [:]
    body.resolveStrategy = Closure.DELEGATE_FIRST
    body.delegate = config
    body()

    node {
        ansiColor('xterm') {
            stage("\u001B[31;1mBuild and put into container\u001B[0m") {
                echo "\u001B[31;1m++++++++ GIT ++++++++\u001B[0m"
                git branch: 'master', url: 'https://github.com/psiinon/bodgeit.git'
                echo "\u001B[31;1m++++++++ MKDIR ++++++++\u001B[0m"
                sh 'mkdir -p $WORKSPACE/build/WEB-INF/classes'
                echo "\u001B[31;1m++++++++ ANT ++++++++\u001B[0m"
                withAnt(installation: "${config.anttool}") {
                    sh 'ant build test'
                }
                archiveArtifacts artifacts: 'build/bodgeit.war', fingerprint: true, onlyIfSuccessful: true
            }
        }
    }
}
