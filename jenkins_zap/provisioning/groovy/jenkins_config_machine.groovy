import org.jenkinsci.plugins.workflow.libs.*
import jenkins.plugins.git.GitSCMSource
import hudson.tools.*;
import hudson.tasks.Ant.AntInstaller;
import hudson.tasks.Ant.AntInstallation;
import jenkins.model.Jenkins;
import hudson.model.FreeStyleProject;
import hudson.tools.InstallSourceProperty;
import hudson.tools.ZipExtractionInstaller;
import com.cloudbees.jenkins.plugins.customtools.*;
import com.synopsys.arc.jenkinsci.plugins.customtools.*;
import com.synopsys.arc.jenkinsci.plugins.customtools.versions.*;
import com.cwctravel.hudson.plugins.extended_choice_parameter.*;
import org.jenkinsci.plugins.authorizeproject.strategy.*;
import org.jenkinsci.plugins.authorizeproject.*;
import jenkins.security.QueueItemAuthenticatorConfiguration;


import hudson.model.Descriptor;
import hudson.model.Saveable;
import hudson.tools.*;

def configureAythStrategy(){
	GlobalQueueItemAuthenticator auth = new GlobalQueueItemAuthenticator(new TriggeringUsersAuthorizationStrategy())
	QueueItemAuthenticatorConfiguration.get().authenticators.add(auth)
}

def configureCustomTool()
{
	List<InstallSourceProperty> ispap = new ArrayList<>();
	List<ZipExtractionInstaller> zeiai = new ArrayList<>();
	LabelSpecifics[] lsa = new LabelSpecifics[1];

	ZipExtractionInstaller zei = new ZipExtractionInstaller("", "https://github.com/zaproxy/zaproxy/releases/download/2.6.0/ZAP_2.6.0_Linux.tar.gz","ZAP_2.6.0");
	zeiai.add(zei);
	InstallSourceProperty isp = new InstallSourceProperty(zeiai);
	ispap.add(isp);
	lsa[0] = new LabelSpecifics("","","");
	ExtendedChoiceParameterDefinition ecpd = new ExtendedChoiceParameterDefinition("", 
																				   "", 
																				   "", 
																				   "", 
																				   "", 
																				   "", 
																				   "", 
																				   "", 
																				   "", 
																				   "", 
																				   "", 
																				   "", 
																				   "", 
																				   "", 
																				   "", 
																				   "", 
																				   "", 
																				   "", 
																				   "", 
																				   "", 
																				   "", 
																				   "", 
																				   "", 
																				   "", 
																				   "", 
																				   "", 
																				   false, 
																				   false, 
																				   5, 
																				   "", 
																				   "");
	ToolVersionConfig tvc = new ToolVersionConfig(ecpd);

	CustomTool ct = new CustomTool("zap-2.6.0", "", ispap, "", lsa, tvc, "");


	def instance = Jenkins.getInstance()
	def pipeline_lib = instance.getDescriptor("com.cloudbees.jenkins.plugins.customtools.CustomTool")
	List<CustomTool> custom_tool_array = new ArrayList<>()
	custom_tool_array.add(ct)
	pipeline_lib.setInstallations((CustomTool[])custom_tool_array)
	pipeline_lib.save()
	instance.save()
}

def createSeedJob()
{
	job = Jenkins.instance.createProject(FreeStyleProject, 'seed-job')
	builder = new javaposse.jobdsl.plugin.ExecuteDslScripts()
	builder.setTargets("jobs/**/*.groovy")
	job.buildersList.add(builder)
	job.logRotator = new hudson.tasks.LogRotator ( -1, 2, -1, -1)
	job.save()
}


def configureGlobalPipelineLib() {
	def instance = Jenkins.getInstance()
	def pipeline_lib = instance.getDescriptor("org.jenkinsci.plugins.workflow.libs.GlobalLibraries")

	List<LibraryConfiguration> libraries = new ArrayList<>()
	GitSCMSource gitsource = new GitSCMSource("https://github.com/pymag09/local_env.git")
	SCMSourceRetriever ssr = new SCMSourceRetriever(gitsource)
	LibraryConfiguration lc = new LibraryConfiguration("bodgeit", ssr)
	lc.setDefaultVersion("jenkins_dsl")
	libraries.add(lc)
	pipeline_lib.setLibraries(libraries)
	pipeline_lib.save()
	instance.save()
}


def configureAntTool(){
	def instance = Jenkins.getInstance()
	def desc_AntTool = instance.getDescriptor("hudson.tasks.Ant")

	def antInstaller = new AntInstaller("1.10.1")
	def installSourceProperty = new InstallSourceProperty([antInstaller])
	def ant_inst = new AntInstallation("ant-latest","",[installSourceProperty])
	def ant_installations = desc_AntTool.getInstallations()
	ant_installations += ant_inst
	desc_AntTool.setInstallations((AntInstallation[]) ant_installations)
	desc_AntTool.save()
	instance.save()
}

configureAythStrategy()
configureAntTool()
configureCustomTool()
configureGlobalPipelineLib()
createSeedJob()
