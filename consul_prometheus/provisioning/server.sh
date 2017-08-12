#!/bin/bash

consul_dir='/opt/consul'
prometheus_dir='/opt'

if [[ -f /etc/updated ]]; then
  sudo apt-get update && touch /etc/updated
fi
apt install -y wget mc unzip

localectl set-locale LANG=C

#----------------------CONSUL

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
echo "Create consul data dir" && \
mkdir $consul_dir/data && \
chown -R nobody:nogroup /opt/consul && \
echo "DONE."

echo "Copy consul config" && \
cp /vagrant/services_config/server/consul.json /etc/consul.d/consul.json && \
cp /vagrant/services_config/consul_exporter.json /etc/consul.d/consul_exporter.json && \
echo "DONE."

#---------------------------PROMETHEUS

[[ ! -d $prometheus_dir ]] && \
echo "Create prometheus dir" && \
mkdir $prometheus_dir && \
echo "DONE."

[[ ! -f $prometheus_dir/prometheus.tar.gz ]] && \
echo "Download prometheus" && \
wget -O $prometheus_dir/prometheus.tar.gz "https://github.com/prometheus/prometheus/releases/download/v1.7.1/prometheus-1.7.1.linux-amd64.tar.gz" && \
echo "DONE."

[[ ! -f $prometheus_dir/prometheus ]] && \
echo "Unzip prometheus" && \
sudo tar -xzvf $prometheus_dir/prometheus.tar.gz -C $prometheus_dir && \
mv /opt/prometheus-* /opt/prometheus/ && \
cp /vagrant/services_config/prometheus.yml $prometheus_dir/prometheus/prometheus.yml && \
echo "DONE."

#---------------------CONSUL_EXPORTER

[[ ! -f $prometheus_dir/consul_exporter.tar.gz ]] && \
echo "Download consul_exporter" && \
wget -O $prometheus_dir/consul_exporter.tar.gz "https://github.com/prometheus/consul_exporter/releases/download/v0.3.0/consul_exporter-0.3.0.linux-amd64.tar.gz" && \
echo "DONE."

[[ ! -f $prometheus_dir/consul_exporter ]] && \
echo "Unzip consul_exporter" && \
sudo tar -xzvf $prometheus_dir/consul_exporter.tar.gz -C $prometheus_dir/prometheus && \
mv /opt/prometheus/consul_exporter-* /opt/prometheus/consul_exporter/ && \
chown -R nobody:nogroup /opt/prometheus && \
echo "DONE."


#-----------------------------------------------

[[ ! -h /etc/systemd/system/consul.service ]] && \
echo "Create consul service" && \
systemctl enable /vagrant/services_config/consul.service && \
echo "DONE."

[[ ! -h /etc/systemd/system/prometheus.service ]] && \
echo "Create prometheus service" && \
systemctl enable /vagrant/services_config/prometheus.service && \
echo "DONE."

[[ ! -h /etc/systemd/system/consul_exporter.service ]] && \
echo "Create consul_exporter service" && \
systemctl enable /vagrant/services_config/consul_exporter.service && \
echo "DONE."

systemctl start consul
systemctl start prometheus
systemctl start consul_exporter
