import jenkins.model.*
import hudson.security.*
import hudson.tasks.*

'''
Add default user admin
'''
def instance = Jenkins.getInstance()
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
hudsonRealm.createAccount("admin","admin")
instance.setSecurityRealm(hudsonRealm)
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)
instance.save()

'''
Add initial job. For demo purpose.
'''
def steps = [new Shell("py.test -v /vagrant/tests/node1/* --host=192.168.1.166 --connection=ssh --ssh-config=/vagrant/ssh_config --junit-xml '\$WORKSPACE/node1.xml'"),
             new Shell("py.test -v /vagrant/tests/node2/* --host=192.168.1.167 --connection=ssh --ssh-config=/vagrant/ssh_config --junit-xml '\$WORKSPACE/node2.xml'"),
             new junit.JUnitResultArchiver("*.xml")]
job = Jenkins.instance.createProject(FreeStyleProject, 'Scripted Policy Demo')
steps.each {
  if (it instanceof Shell)
    it.unstableReturn = 1
  job.buildersList.add(it)
}
job.logRotator = new LogRotator ( -1, 2, -1, -1)
job.save()
