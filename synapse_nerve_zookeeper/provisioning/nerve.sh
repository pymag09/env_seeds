#!/bin/bash --login

sudo mkdir -p /opt/smartstack/nerve
sudo mkdir -p /opt/smartstack/nerve/conf.d
sudo apt-get update && sudo apt-get install -y apache2
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
cp /vagrant/configuration/$(hostname).conf /etc/init
service $(hostname) start
