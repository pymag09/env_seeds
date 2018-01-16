import os

import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']).get_hosts('all')


def test_jenkins_user(host):
    assert host.user('jenkins').name == 'jenkins'


def test_service(host):
    s = host.service('jenkins')
    assert s.is_enabled
    assert s.is_running


def test_jenkins_port(host):
    assert host.socket('tcp://0.0.0.0:8080').is_listening


def test_jenkins_jobs(host):
    folders = ['seed-job',
               'bodgeit-pipeline/jobs/SonarQube',
               'bodgeit-pipeline/jobs/bodgeit-build',
               'bodgeit-pipeline/jobs/bodgeit-delivery-pipeline',
               'bodgeit-pipeline/jobs/bodgeit-deploy',
               'bodgeit-pipeline/jobs/bodgeit-zap']
    for f in folders:
        assert host.file('/var/lib/jenkins/jobs/%s' % f).is_directory


def test_sonar_container_is_up(host):
    assert host.socket('tcp://0.0.0.0:9000').is_listening


def test_jenkins_pip_dependecies(host):
    dep = {'jmespath', 'docker-py'}
    pip_dict = host.pip_package.get_packages()
    pip_list = set(pip_dict.keys())
    intersection = dep & pip_list
    assert intersection == dep


def test_jenkins_dependacies(host):
    dep = ['mc', 'docker.io', 'openjdk-8-jdk', 'daemon', 'wget', 'jq']
    for pkg in dep:
        assert host.package(pkg).is_installed


def test_jenkins_plugins(host):
    plugins_ = ['ace-editor',
                'ansicolor',
                'ant',
                'antisamy-markup-formatter',
                'apache-httpcomponents-client-4-api',
                'authentication-tokens',
                'authorize-project',
                'bouncycastle-api',
                'branch-api',
                'build-timeout',
                'cloudbees-folder',
                'copyartifact',
                'credentials',
                'credentials-binding',
                'custom-tools-plugin',
                'display-url-api',
                'docker-commons',
                'docker-workflow',
                'durable-task',
                'email-ext',
                'extended-choice-parameter',
                'git',
                'git-client',
                'git-server',
                'github',
                'github-api',
                'github-branch-source',
                'github-organization-folder',
                'gradle',
                'handlebars',
                'htmlpublisher',
                'jackson2-api',
                'job-dsl',
                'jquery',
                'jquery-detached',
                'jsch',
                'junit',
                'ldap',
                'mailer',
                'mapdb-api',
                'matrix-auth',
                'matrix-project',
                'momentjs',
                'pam-auth',
                'pipeline-build-step',
                'pipeline-github-lib',
                'pipeline-graph-analysis',
                'pipeline-input-step',
                'pipeline-milestone-step',
                'pipeline-model-api',
                'pipeline-model-declarative-agent',
                'pipeline-model-definition',
                'pipeline-model-extensions',
                'pipeline-rest-api',
                'pipeline-stage-step',
                'pipeline-stage-tags-metadata',
                'pipeline-stage-view',
                'plain-credentials',
                'resource-disposer',
                'scm-api',
                'script-security',
                'sonar',
                'ssh-credentials',
                'ssh-slaves',
                'structs',
                'subversion',
                'timestamper',
                'token-macro',
                'windows-slaves',
                'workflow-aggregator',
                'workflow-api',
                'workflow-basic-steps',
                'workflow-cps',
                'workflow-cps-global-lib',
                'workflow-durable-task-step',
                'workflow-job',
                'workflow-multibranch',
                'workflow-scm-step',
                'workflow-step-api',
                'workflow-support',
                'ws-cleanup',
                'zap']
    for plugin in plugins_:
        assert host.file('/var/lib/jenkins/plugins/%s' % plugin).is_directory
