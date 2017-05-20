freeStyleJob('zap-example') {
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
