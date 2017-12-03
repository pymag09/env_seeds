class JobRoot {
    final protected String top_folder_name="bodgeit-pipeline"
    final protected String pipeline_name="bodgeit-delivery-pipeline"
    final protected String build_step_name="bodgeit-build"
    final protected String deploy_step_name="bodgeit-deploy"
    final protected String test_step_name="bodgeit-zap"
    final protected String sonar_job_name="SonarQube"
    protected def dslFactory

    public void build() {
        DSLcode()
    }
}
class PipelineDSLTemplate extends JobRoot {
    final protected Closure DSLcode = {
        dslFactory.pipelineJob("${top_folder_name}/${job_name}") {
            displayName("${job_name}")
            definition {
                cps {
                    script(inlineScript)
                    sandbox(sandbox=false)
                }
            }
        }
    }
}
class MainPipelineJob extends PipelineDSLTemplate {
    final String job_name = pipeline_name
    final protected Closure DSLcode = {
        dslFactory.pipelineJob("${top_folder_name}/${job_name}") {
            displayName("${job_name}")
            parameters {
              booleanParam {
                  name("run_parallel")
                  defaultValue(true)
                  description("Run tests in parallel")
              }
              booleanParam {
                  name("run_sonar")
                  defaultValue(true)
                  description("Run Sonar tests")
              }
            }
            definition {
                cps {
                    script(inlineScript)
                    sandbox(sandbox=false)
                }
            }
        }
    }
    final private String inlineScript = '''@Library("bodgeit") _

import com.pymag.dsl.Engine

Engine e = new Engine(params)

def builds = [:]
    builds['zap'] = {
      stage("Deploy bodgeit in docker containter and start ZAP"){
          build job: 'bodgeit-pipeline/bodgeit-deploy', parameters: [string(name: 'upstream_job', value: 'bodgeit-pipeline/bodgeit-build')]
      }
    }
    if (e.includeSonarTests()) {
        builds['sonar'] = {
          stage("Run Sonar job"){
              build 'bodgeit-pipeline/SonarQube'
          }
        }
    }
    node{
    stage("Build bodgeit from source code using Ant"){
        build 'bodgeit-pipeline/bodgeit-build'
    }
    if (e.parallelEnabled())
        stage("Run tests in parallel") {
            parallel builds
        }
    else {
        stage("Run test sequentaly"){
            builds.each{ it.value() }
        }
    }
}

'''
  MainPipelineJob(def dslFactory){ this.dslFactory = dslFactory }
}
class BuildJob extends PipelineDSLTemplate {
    final String job_name = build_step_name
    final private String inlineScript = '''
@Library('bodgeit') _

BuildBodgeit{
    anttool = "ant-latest"
}
'''
  BuildJob(def dslFactory){ this.dslFactory = dslFactory }
}
class DeployJob extends PipelineDSLTemplate {
    final String job_name = deploy_step_name
    final private String inlineScript = '''@Library("bodgeit") _

node('master'){
    properties([buildDiscarder(logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '2')), [$class: 'CopyArtifactPermissionProperty', projectNames: '*'], parameters([string(defaultValue: '', description: 'Job name to take artefact from', name: 'upstream_job')]), pipelineTriggers([])])
    step([$class: 'CopyArtifact', filter: 'build/bodgeit.war', fingerprintArtifacts: true, flatten: true, projectName: "${params.upstream_job}"])
}
node("master"){
    stage("run security tests"){
         docker.image('tomcat').withRun('--name bodgeit -v $WORKSPACE/build/bodgeit.war:/usr/local/tomcat/webapps/bodgeit.war -p 8181:8080') {
             build 'bodgeit-pipeline/bodgeit-zap'
        }
    }
}
'''
  DeployJob(def dslFactory) { this.dslFactory = dslFactory }
}

class SonarJob extends JobRoot {
  final String job_name = sonar_job_name
  final private Closure DSLcode = {
    dslFactory.freeStyleJob("${top_folder_name}/${sonar_job_name}") {
      logRotator(-1, 2, -1, -1)
      scm {
        git {
          remote {
              name('origin')
              url('https://github.com/psiinon/bodgeit.git')
          }
        }
        steps {
            shell('mkdir -p $WORKSPACE/build/WEB-INF/classes')
            ant {
              targets(['build'])
              antInstallation('ant-latest')
            }
            sonarRunnerBuilder {
              additionalArguments('')
              installationName('docker-sonar')
              javaOpts('')
              jdk('')
              project('')
              properties('''sonar.projectKey=b3c23d987bc0fc35e054f54d1e913793afcd7e13
sonar.projectName=bodgeit
sonar.projectVersion=1.0.0
sonar.projectDescription=Static analysis for the bodgeit
sonar.sources=$WORKSPACE
sonar.java.binaries=$WORKSPACE/build/WEB-INF/classes/
sonar.language=java
sonar.sourceEncoding=UTF-8
              ''')
              sonarScannerName('sonar-latest')
              task('')
            }
        }
      }
    }
  }
SonarJob(def dslFactory) { this.dslFactory = dslFactory }
}

class RunZAPJob extends JobRoot {
    final String job_name = test_step_name
    final private Closure DSLcode = {
        dslFactory.freeStyleJob("${top_folder_name}/${test_step_name}") {
            logRotator(-1, 2, -1, -1)
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
    }
  RunZAPJob(def dslFactory) { this.dslFactory = dslFactory }
}
class TopFolder extends JobRoot {
    final private Closure DSLcode = {
        dslFactory.folder("${top_folder_name}") {
            displayName("${top_folder_name}")
            description('Delivery pipeline for bodgeit site')
        }
    }
    TopFolder(def dslFactory) { this.dslFactory = dslFactory }
}

def jobs = [new TopFolder(this),
            new MainPipelineJob(this),
            new BuildJob(this),
            new DeployJob(this),
            new RunZAPJob(this),
            new SonarJob(this)]
jobs.each { it.build() }
