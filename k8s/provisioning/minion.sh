#!/bin/bash

RETRY=6
TIMEOUT=10


update_install_pkg() {
  apt-get update && \
  apt-get install -y mc docker.io git make etcd
}

etcd_config() {
  src=$(md5sum /vagrant/etcd_configs/${HOSTNAME})
  dst=$(md5sum /etc/default/etcd)
  if [[ ! -d /etc/etcd/tls ]]; then
    mkdir -p /etc/etcd/tls
  fi
  if [[ ! "$src" == "$dst" ]]; then
     cp /vagrant/etcd_configs/${HOSTNAME} /etc/default/etcd
     cp /vagrant/k8s_tls/etcd* /etc/etcd/tls
     cp /vagrant/k8s_tls/ca* /etc/etcd/tls
     systemctl stop etcd
     systemctl start etcd
  fi
}

install_flannel() {
  if [[ ! -f /srv/flannel/dist/flanneld-amd64 ]]; then
    cd /srv
    git clone https://github.com/coreos/flannel.git
    tar -xzvf kubernetes.tar.gz
    rm -f kubernetes.tar.gz
    cd flannel
    make dist/flanneld-amd64
    cp /srv/flannel/dist/flanneld-amd64 /srv/k8s/flanneld || exit 1
    rm -Rf /srv/flannel
  fi
}

enable_flannel() {
  if [[ ! -h /etc/systemd/system/flanneld.service ]]; then
    systemctl enable /srv/kube_services/flanneld.service
  fi
  systemctl daemon-reload
}

run_flannel() {
  systemctl start flanneld.service || exit 1
  while [[ $RETRY -gt 0 ]]; do
    echo $RETRY
    sleep $TIMEOUT
    RETRY=$(( RETRY - 1))
    if [[ -f /var/run/flannel/subnet.env ]]; then
      break
    fi
  done
  source /var/run/flannel/subnet.env
  if [[ ! "$(md5sum < /etc/default/docker)" == "$(echo 'DOCKER_OPTS=\"--ip-masq=false --iptables=false --bip=${FLANNEL_SUBNET} --mtu=${FLANNEL_MTU}\"' | md5sum)" ]]; then
    echo "DOCKER_OPTS=\"--ip-masq=false --iptables=false --bip=${FLANNEL_SUBNET} --mtu=${FLANNEL_MTU}\"" > /etc/default/docker
    service docker restart
  fi
}

copy_k8s_bin() {
  src=$(ls /srv/k8s | md5sum)
  dst=$(ls /vagrant/k8s | md5sum)
  if [[ ! "$src" == "$dst" ]]; then
    cp -R /vagrant/k8s /srv
  fi
}

start_k8s_minion() {
  mkdir -p /etc/kubernetes/tls
  cp /vagrant/k8s_tls/* /etc/kubernetes/tls
  cp /vagrant/kubeconfigs/kube-proxy /var/lib/kubeproxy/kubeconfig
  cp /vagrant/kubeconfigs/kubelet /var/lib/kubelet/kubeconfig
  echo "nameserver 127.0.0.1" > /etc/resolvconf/resolv.conf.d/head
  resolvconf -u
  if [[ ! -h /etc/systemd/system/kube-proxy.service ]]; then
    systemctl enable /srv/kube_services/kube-proxy.service
  fi
  if [[ ! -h /etc/systemd/system/kubelet.service ]]; then
    systemctl enable /srv/kube_services/kubelet-minion.service
  fi
  systemctl start kube-proxy.service
  systemctl start kubelet-minion.service
}

[[ ! -d /srv/k8s ]] && mkdir /srv/k8s
[[ ! -d /var/lib/kubeproxy/ ]] && mkdir -p /var/lib/kubeproxy/
[[ ! -d /var/lib/kubelet/ ]] && mkdir -p /var/lib/kubelet/
cp -R /vagrant/kube_services /srv/kube_services
update_install_pkg
etcd_config
if [[ $(pgrep -c etc[d]) -gt 0 ]]; then
 etcdctl -ca-file=/etc/etcd/tls/ca.crt --cert-file=/etc/etcd/tls/etcd.crt --key-file=/etc/etcd/tls/etcd.key --peers="https://192.168.1.166:4001,https://192.168.1.166:2379" set /coreos.com/network/config  '{ "Network": "10.1.0.0/16", "Backend": { "Type": "vxlan", "VNI": 1 }  }'
fi
copy_k8s_bin
enable_flannel
run_flannel
mkdir -p /etc/cni/net.d/
cat <<EOF > /etc/cni/net.d/10-flannel.conf
{
  "name": "kubenet",
  "type": "flannel",
  "delegate": {
    "isDefaultGateway": true,
    "ipMasq": true
  }
}
EOF
for c in $(docker ps -q | awk '{print $1}'); do docker stop "$c"; done
for c in $(docker ps -a -q | awk '{print $1}'); do docker rm "$c"; done
start_k8s_minion
