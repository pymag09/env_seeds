#!/bin/bash --login

sudo mkdir -p /opt/smartstack/synapse
sudo mkdir -p /opt/smartstack/synapse/conf.d
sudo mkdir -p /var/haproxy
sudo chown haproxy:haproxy /var/haproxy
sudo apt-get update && sudo apt-get install -y haproxy lynx mc
sudo echo "ENABLED=1" > /etc/default/haproxy
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
cp /vagrant/configuration/$(hostname).conf /etc/init
service $(hostname) start
sudo chmod 777 /etc/haproxy/haproxy.cfg
