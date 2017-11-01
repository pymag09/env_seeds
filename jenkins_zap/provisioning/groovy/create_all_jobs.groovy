// Global variables
def top_folder_name="bodgeit-pipeline"
def pipeline_name="bodgeit-delivery-pipeline"
def build_step_name="bodgeit-build"
def deploy_step_name="bodgeit-deploy"
def test_step_name="bodgeit-zap"

// Top level folder
folder("${top_folder_name}") {
    displayName("${top_folder_name}")
    description('Delivery pipeline for bodgeit site')
}

// Entry point. Delivery pipeline
pipelineJob("${top_folder_name}/${pipeline_name}") {
    displayName("${pipeline_name}")
    definition {
        cps {
            script('''
node{
    stage("Build bodgeut from sources code using Ant"){
        build \'''' + "${top_folder_name}/${build_step_name}" + '''\'
    }
    stage("Deploy bodgeit in docker containter"){
        build job: \'''' + "${top_folder_name}/${deploy_step_name}" + '''\', parameters: [string(name: 'upstream_job', value: \'''' + "${top_folder_name}/${build_step_name}" + '''\')]
    }
    stage("Run security test"){
        build \'''' + "${top_folder_name}/${test_step_name}" + '''\'
    }
}
'''
)
            sandbox(sandbox=false)

        }
    }
}

// Build job
pipelineJob("${top_folder_name}/${build_step_name}") {
    displayName("${build_step_name}")
    definition {
        cps {
            script('''
@Library('bodgeit') _

BuildBodgeit{
    anttool = "ant-latest"
}
'''
)
            sandbox(sandbox=false)

        }
    }
}
// Deploy job
pipelineJob("${top_folder_name}/${deploy_step_name}") {
    displayName("${deploy_step_name}")
    definition {
        cps {
            script('''
@Library("bodgeit") _

node('master'){
    properties([buildDiscarder(logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '2')), [$class: 'CopyArtifactPermissionProperty', projectNames: '*'], parameters([string(defaultValue: '', description: 'Job name to take artefact from', name: 'upstream_job')]), pipelineTriggers([])])
    step([$class: 'CopyArtifact', filter: 'build/bodgeit.war', fingerprintArtifacts: true, flatten: true, projectName: "${params.upstream_job}"])
}

RDocker{
    command = 'docker run -d -v $WORKSPACE/build/bodgeit.war:/usr/local/tomcat/webapps/bodgeit.war --name bodgeit -p 8181:8080 tomcat'
}

'''
)
            sandbox(sandbox=false)

        }
    }
}
// Security test job
freeStyleJob("${top_folder_name}/${test_step_name}") {
    logRotator(-1,2,-1,-1)
    authenticationToken('VANDHRV73hbc5dsj')
    steps {
        zapBuilder {
            startZAPFirst(false)
            zapHost("localhost")
            zapPort("9090")
            zaproxy {
                autoInstall(true)
                toolUsed("zap-2.6.0")
                zapHome("/var/lib/jenkins/ZAP")
                alertFilters("")
                loggedOutIndicator("")
                jdk("InheritFromJob")
                timeout(60)
                zapSettingsDir("/var/lib/jenkins/ZAP")
                loadSession("")
                autoLoadSession(false)
                sessionFilename("bodgeit")
                removeExternalSites(false)
                internalSites("")
                contextName("zap \${BUILD_ID}")
                includedURL("http://localhost:8181/bodgeit.*")
                excludedURL("")
                authMode(true)
                username("zap@test.com")
                password("test123")
                loggedInIndicator(".*\\Qlogout=\\E.*")
                authMethod("FORM_BASED")
                loginURL("http://localhost:8181/bodgeit/login.jsp")
                usernameParameter("username")
                passwordParameter("password")
                extraPostData("")
                authScript("")
                authScriptParams {}
                targetURL("http://localhost:8181/bodgeit/")
                spiderScanURL(true)
                spiderScanRecurse(true)
                spiderScanSubtreeOnly(false)
                spiderScanMaxChildrenToCrawl(0)
                ajaxSpiderURL(false)
                ajaxSpiderInScopeOnly(false)
                activeScanURL(true)
                activeScanRecurse(true)
                activeScanPolicy("Default Policy")
                generateReports(true)
                selectedReportMethod("DEFAULT_REPORT")
                deleteReports(true)
                reportFilename("JENKINS_ZAP_VULNERABILITY_REPORT_\${BUILD_ID}")
                selectedReportFormats(["xml", "html"])
                selectedExportFormats(["xml", "json"])
                exportreportTitle("")
                exportreportBy("")
                exportreportFor("")
                exportreportScanDate("")
                exportreportReportDate("")
                exportreportScanVersion("")
                exportreportReportVersion("")
                exportreportReportDescription("")
                exportreportAlertHigh(false)
                exportreportAlertMedium(false)
                exportreportAlertLow(false)
                exportreportAlertInformational(false)
                exportreportCWEID(false)
                exportreportWASCID(false)
                exportreportDescription(false)
                exportreportOtherInfo(false)
                exportreportSolution(false)
                exportreportReference(false)
                exportreportRequestHeader(false)
                exportreportResponseHeader(false)
                exportreportRequestBody(false)
                exportreportResponseBody(false)
                jiraCreate(false)
                jiraProjectKey("")
                jiraAssignee("")
                jiraAlertHigh(false)
                jiraAlertMedium(false)
                jiraAlertLow(false)
                jiraFilterIssuesByResourceType(false)
                cmdLinesZAP {
                    zapCmdLine {
                        cmdLineOption("-host")
                        cmdLineValue("localhost")
                    }
                    zapCmdLine {
                        cmdLineOption("-port")
                        cmdLineValue("9090")
                    }
                    zapCmdLine {
                        cmdLineOption("-dir")
                        cmdLineValue("/var/lib/jenkins/ZAP")
                    }
                    zapCmdLine {
                        cmdLineOption("-config")
                        cmdLineValue("database.compact=true")
                    }

                }
            }
        }
    }
    publishers {
        archiveArtifacts('reports/*')
        publishHtml {
            report('reports') {
                reportName('HTML Report')
                reportFiles('JENKINS_ZAP_VULNERABILITY_REPORT_${BUILD_ID}.html')
                keepAll()
                allowMissing()
                alwaysLinkToLastBuild()
            }
        }
    }
}
