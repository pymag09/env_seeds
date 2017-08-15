#!/bin/bash

consul_dir='/opt/consul'
prometheus_dir='/opt/prometheus'

if [[ -f /etc/updated ]]; then
    apt-get update && touch /etc/updated
fi
apt-get install -y wget mc unzip python3-pip zabbix-agent
pip3 install prometheus_client
pip3 install pyyaml
#------------CONSUL

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
wget -O $consul_dir/consul.zip "https://releases.hashicorp.com/consul/0.9.0/consul_0.9.0_linux_amd64.zip" && \
echo "DONE."

[[ ! -f $consul_dir/consul ]] && \
echo "Unzip consul" && \
sudo unzip $consul_dir/consul.zip -d $consul_dir && \
echo "DONE."

[[ ! -d $consul_dir/data ]] && \
echo "Creating consul data dir" && \
mkdir $consul_dir/data && \
chown -R nobody:nogroup /opt/consul && \
echo "DONE."

echo "Copy consul config" && \
cp /vagrant/services_config/$(hostname)/consul.json /etc/consul.d/consul.json && \
cp /vagrant/services_config/node_exporter.json /etc/consul.d/node_exporter.json && \
cp /vagrant/services_config/swiss_knife_exporter.json /etc/consul.d/swiss_knife_exporter.json && \
echo "DONE."

#---------------HOST_EXPORTER
[[ ! -d $prometheus_dir ]] && \
echo "Create prometheus dir" && \
mkdir $prometheus_dir && \
echo "DONE."

[[ ! -f $prometheus_dir/node_exporter.tar.gz ]] && \
echo "Download node_exporter" && \
wget -O $prometheus_dir/node_exporter.tar.gz "https://github.com/prometheus/node_exporter/releases/download/v0.14.0/node_exporter-0.14.0.linux-amd64.tar.gz" && \
echo "DONE."

[[ ! -f $prometheus_dir/node_exporter/node_exporter ]] && \
echo "Unzip node_exporter" && \
sudo tar -xzvf $prometheus_dir/node_exporter.tar.gz -C $prometheus_dir && \
mv /opt/prometheus/node_exporter-* /opt/prometheus/node_exporter/ && \
chown -R nobody:nogroup /opt/prometheus && \
echo "DONE."

#---------------SWISS_KNIFE_EXPORTER
[[ ! -d $prometheus_dir ]] && \
echo "Create prometheus dir" && \
mkdir $prometheus_dir && \
echo "DONE."

[[ ! -f $prometheus_dir/PROMETHEUS-SWISS-KNIFE-EXPORTER/swiss_knife_exporter.py ]] && \
echo "Download swiss_knife_exporter" && \
cd $prometheus_dir && \
git clone https://github.com/pymag09/PROMETHEUS-SWISS-KNIFE-EXPORTER.git && \
chown -R nobody:nogroup /opt/prometheus && \
echo "DONE."


[[ ! -h /etc/systemd/system/consul.service ]] && \
echo "Create consul service and start" && \
systemctl enable /vagrant/services_config/consul.service && \
echo "DONE."

[[ ! -h /etc/systemd/system/node_exporter.service ]] && \
echo "Create node_exporter service and start" && \
systemctl enable /vagrant/services_config/node_exporter.service && \
echo "DONE."

[[ ! -h /etc/systemd/system/swiss_knife_exporter.service ]] && \
echo "Create swiss_knife_exporter service and start" && \
systemctl enable /vagrant/services_config/swiss_knife_exporter.service && \
echo "DONE."

systemctl start consul
systemctl start node_exporter
systemctl start swiss_knife_exporter
