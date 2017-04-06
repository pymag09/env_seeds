#!/bin/bash --login

[[ ! -d /opt/smartstack/nerve ]] && mkdir -p /opt/smartstack/nerve
[[ ! -d /opt/smartstack/nerve/conf.d ]] && mkdir -p /opt/smartstack/nerve/conf.d
if [[ ! -f /etc/updated ]]; then
  apt-get update
  touch /etc/updated
fi
apt-get install -y apache2
echo "ruby-2.2.1" > /opt/smartstack/nerve/.ruby-version
echo "nerve" > /opt/smartstack/nerve/.ruby-gemset
curl -sSL https://rvm.io/mpapis.asc | gpg --import -
curl -sSL https://get.rvm.io | bash -s stable --ruby
source /usr/local/rvm/scripts/rvm
cd /
cd /opt/smartstack/nerve
rvm install ruby-2.2.1
cd /
cd /opt/smartstack/nerve
gem install nerve
if [[ ! "$(md5sum /vagrant/configuration/$(hostname).conf)" = "$(md5sum /etc/init)" ]]; then
  cp /vagrant/configuration/$(hostname).conf /etc/init
fi
service $(hostname) start
