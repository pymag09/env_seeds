#!/bin/bash


install_pkgs(){
	echo "Install packages"
	sudo apt-get install -y mc docker.io openjdk-8-jdk daemon wget jq	
}

download_install_jenkins(){
	echo "jenkins download"
	[[ ! -f /root/jenkins.deb ]] && wget -O /root/jenkins.deb "https://pkg.jenkins.io/debian-stable/binary/jenkins_2.7.4_all.deb"
	[[ $(apt-cache show jenkins | grep -c "ok installed") -eq 0 ]] && dpkg -i /root/jenkins.deb	
	[[ ! -f /etc/sudoers.d/jenkins ]] && echo "jenkins ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/jenkins
}

prepare_plugins_and_workspace(){
	[[ ! -f /var/lib/jenkins/com.cloudbees.jenkins.plugins.customtools.CustomTool.xml ]] && \
	cp /vagrant/config/com.cloudbees.jenkins.plugins.customtools.CustomTool.xml /var/lib/jenkins && \
	cp /vagrant/config/jenkins.security.QueueItemAuthenticatorConfiguration.xml /var/lib/jenkins && \
	echo "Creating workspace folder..."
	[[ ! -d /var/lib/jenkins/workspace/seed-job/jobs ]] && \
	mkdir -p /var/lib/jenkins/workspace/seed-job/jobs && \
	cp /vagrant/provisioning/groovy/bodgeit_folder.groovy /var/lib/jenkins/workspace/seed-job/jobs/bodgeit_folder.groovy && \
	chown -R jenkins:jenkins /var/lib/jenkins/workspace
}

get_crumb(){
	for next in 0 1 2 3 4 5 6 7 8 9; do
		if [[ $(curl -I http://localhost:8080/info | grep -c Forbidden) -eq 1 ]]; then
			break
		fi
		sleep 30
	done
	if [[ -f /var/lib/jenkins/wizard_completed ]]; then
		curl --user "admin:admin" -s http://localhost:8080/crumbIssuer/api/json | jq -r .crumb
	else
		curl --user "admin:$1" -s http://localhost:8080/crumbIssuer/api/json | jq -r .crumb
	fi
}

change_pwd_install_plugins(){
	echo "Install plugins"
	crumb_pass_reset="Jenkins-Crumb=$1"
	crumb_plugin="Jenkins-Crumb: $1"

	if [[ ! -f /var/lib/jenkins/wizard_completed ]]; then
	 curl --user "admin:$2" -d "$crumb_pass_reset" --data-urlencode "script=$(< /vagrant/provisioning/groovy/setpasswd.groovy)" http://localhost:8080/scriptText && \
	 curl -k -L -XPOST --user "admin:admin" -H "Content-Type: application/json" -H "$crumb_plugin" -d "{\"dynamicLoad\": true,  \"plugins\": [\"cloudbees-folder\", \"antisamy-markup-formatter\", \"build-timeout\", \"credentials-binding\", \"timestamper\", \"ws-cleanup\", \"ant\", \"gradle\", \"workflow-aggregator\", \"github-organization-folder\", \"pipeline-stage-view\", \"git\", \"subversion\", \"ssh-slaves\", \"matrix-auth\", \"pam-auth\", \"ldap\", \"email-ext\", \"mailer\", \"custom-tools-plugin\", \"htmlpublisher\", \"zap\", \"job-dsl\", \"authorize-project\", \"workflow-aggregator\", \"copyartifact\", \"ansicolor\"] }" http://localhost:8080/pluginManager/installPlugins
	 touch /var/lib/jenkins/wizard_completed
	fi	
}

wait_for_wizard_complete(){
	for next in 0 1 2 3 4 5 6 7 8 9; do
		if [[ $(du -s /var/lib/jenkins/plugins | awk '{print $1}') -ge 124776 ]]; then
			break
		fi
		echo "$next $(du -s /var/lib/jenkins/plugins | awk '{print $1}')"
		sleep 60
	done	
}

restart_jenkins(){
	systemctl restart jenkins
	for next in 0 1 2 3 4 5 6 7 8 9; do
		if [[ $(curl -I http://localhost:8080/info | grep -c Forbidden) -eq 1 ]]; then
			break
		fi
		sleep 30
	done
}

generate_seed_job_and_execute(){
	crumb_pass_reset="Jenkins-Crumb=$1"
	curl --user "admin:admin" -d "$crumb_pass_reset" --data-urlencode "script=$(< /vagrant/provisioning/groovy/seed_job.groovy)" http://localhost:8080/scriptText
	curl -XPOST --user "admin:admin" -d "$crumb_pass_reset" http://localhost:8080/job/seed-job/build?token=TOKENVANDHRV73hbc5dsj
}

sudo apt-get update
sys_update
install_pkgs
download_install_jenkins
prepare_plugins_and_workspace
for next in 0 1 2 3 4 5 6 7 8 9; do
	if [[ -f /var/lib/jenkins/secrets/initialAdminPassword ]]; then
		break
	fi
	sleep 20
done
default_passwd=$(cat /var/lib/jenkins/secrets/initialAdminPassword)
echo "DEFAULT PASSWORD $default_passwd"
jcrumb=$(get_crumb "$default_passwd")
echo "----CRUMB $jcrumb"
change_pwd_install_plugins "$jcrumb" "$default_passwd"
wait_for_wizard_complete
restart_jenkins
generate_seed_job_and_execute "$jcrumb"
