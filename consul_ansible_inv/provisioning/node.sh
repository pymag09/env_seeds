#!/bin/bash

consul_dir='/opt/consul'

if [[ -f /etc/updated ]]; then
    apt update && touch /etc/updated
fi
apt install -y wget mc unzip apache2

[[ ! -d $consul_dir ]] && \
echo "Create consul dir" && \
mkdir $consul_dir && \
echo "DONE."

[[ ! -d /etc/consul.d ]] && \
echo "Create consul config dir" && \
mkdir /etc/consul.d && \
echo "DONE."

[[ ! -f $consul_dir/consul.zip ]] && \
echo "Download consul" && \
wget -O $consul_dir/consul.zip "https://releases.hashicorp.com/consul/0.8.1/consul_0.8.1_linux_amd64.zip?_ga=2.79866196.298394035.1493891390-803001184.1469129827" && \
echo "DONE."

[[ ! -f $consul_dir/consul ]] && \
echo "Unzip consul" && \
sudo unzip $consul_dir/consul.zip -d $consul_dir && \
echo "DONE."

[[ ! -d $consul_dir/data ]] && \
echo "Creating consul data dir" && \
mkdir $consul_dir/data && \
echo "DONE."

echo "Copy consul config" && \
cp /vagrant/services_config/$(hostname)/consul.conf /etc/consul.d/consul.conf && \
cp /vagrant/services_config/apache.json /etc/consul.d/apache.json && \
echo "DONE."

sudo chown -R nobody:nogroup /opt/consul

[[ ! -h /etc/systemd/system/consul.service ]] && \
echo "Create consul service and start" && \
systemctl enable /vagrant/services_config/consul.service && \
systemctl start consul && \
echo "DONE."

echo "NEXT STEP"