import hudson.security.HudsonPrivateSecurityRealm.Details;
def user = hudson.model.User.current();
user.addProperty(Details.fromPlainPassword('admin'))