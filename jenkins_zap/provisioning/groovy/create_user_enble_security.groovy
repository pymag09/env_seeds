import jenkins.model.*
import hudson.security.*

def instance = Jenkins.getInstance()

def hudsonRealm = new HudsonPrivateSecurityRealm(false)
def strategy = new hudson.security.FullControlOnceLoggedInAuthorizationStrategy()
hudsonRealm.createAccount("admin","admin")
instance.setSecurityRealm(hudsonRealm)
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)
instance.save()
