import jenkins.model.Jenkins;
import hudson.model.FreeStyleProject;

job = Jenkins.instance.createProject(FreeStyleProject, 'seed-job')
builder = new javaposse.jobdsl.plugin.ExecuteDslScripts()
builder.setTargets("jobs/**/*.groovy")
job.buildersList.add(builder)
job.logRotator = new hudson.tasks.LogRotator ( -1, 2, -1, -1)
job.save()
