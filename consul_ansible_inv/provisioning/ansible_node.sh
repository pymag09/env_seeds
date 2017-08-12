#!/bin/bash

consul_dir='/opt/consul'

if [[ -f /etc/updated ]]; then
  sudo apt-get update && touch /etc/updated
fi
apt-get install -y wget mc unzip apache2 python python-pip python-openssl
if [[ $(pip2 list | grep consu[l] | wc -l) -eq 0 ]]; then
  pip install --upgrade pip
  pip2 install python-consul
fi
if [[ $(pip2 list | grep ansibl[e] | wc -l) -eq 0 ]]; then
  pip2 install ansible
fi

localectl set-locale LANG=C

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
echo "Create consul data dir" && \
mkdir $consul_dir/data && \
echo "DONE."

echo "Copy consul config" && \
cp /vagrant/services_config/ansible-server/consul.conf /etc/consul.d/consul.conf && \
echo "DONE."

[[ ! -h /etc/systemd/system/consul.service ]] && \
echo "Create consul service" && \
systemctl enable /vagrant/services_config/consul.service && \
echo "DONE."

systemctl start consul

[[ ! -f $consul_dir/consul.ini ]] && \
echo "Copy consul dynamic inventory config" && \
cp /vagrant/services_config/consul.ini $consul_dir/consul.ini && \
echo "DONE."

[[ ! -f $consul_dir/consul_io.py ]] && \
echo "Copy consul dynamic inventory script" && \
cp /vagrant/services_config/consul_io.py $consul_dir/consul_io.py && \
echo "DONE."
chown -R nobody:nogroup /opt/consul

sleep 60

ans_var=$(curl -XPUT --data "{\"show\": \"no\"}" http://192.168.1.165:8500/v1/kv/ansible/metadata/vagrant/node1)
ans_group=$(curl -XPUT --data "g1,g2" http://192.168.1.165:8500/v1/kv/ansible/groups/vagrant/node2)
echo $ans_var
echo $ans_group
if [[ ! "$ans_var" = "true" || ! "$ans_group" = "true" ]]; then
  exit 1;
fi
