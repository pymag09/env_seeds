package pymag.dsl

def call() {
    if (new IsDockerInstalled().check) {

        git url: "https://github.com/psiinon/bodgeit.git"
        sh 'mkdir -p $WORKSPACE/build/WEB-INF/classes'
        withAnt(installation: 'ant-latest') {
            sh:
            ant build test
        }
        sh 'docker run -d -v /var/lib/jenkins/workspace/bodgeit/build/bodgeit.war:/usr/local/tomcat/webapps/bodgeit.war --name bodgeit -p 8181:8080 tomcat'
    }
}