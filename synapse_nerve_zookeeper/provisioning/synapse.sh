#!/bin/bash --login

[[ ! -d /opt/smartstack/synapse ]] && mkdir -p /opt/smartstack/synapse
[[ ! -d  /opt/smartstack/synapse/conf.d ]] && mkdir -p /opt/smartstack/synapse/conf.d
[[ ! -d /var/haproxy ]] && mkdir -p /var/haproxy
chown haproxy:haproxy /var/haproxy
if [[ ! -f /etc/updated ]]; then
  apt-get update
  touch /etc/updated
fi
sudo apt-get install -y haproxy lynx mc
echo "ENABLED=1" > /etc/default/haproxy
echo "ruby-2.2.1" > /opt/smartstack/synapse/.ruby-version
echo "synapse" > /opt/smartstack/synapse/.ruby-gemset
curl -sSL https://rvm.io/mpapis.asc | gpg --import -
curl -sSL https://get.rvm.io | bash -s stable --ruby
source /usr/local/rvm/scripts/rvm
cd /
cd /opt/smartstack/synapse
rvm install ruby-2.2.1
cd /
cd /opt/smartstack/synapse
gem install synapse
if [[ ! "$(md5sum /vagrant/configuration/$(hostname).conf)" = "$(md5sum /etc/init)" ]]; then
 cp /vagrant/configuration/$(hostname).conf /etc/init
fi
service $(hostname) start
sudo chmod 777 /etc/haproxy/haproxy.cfg
