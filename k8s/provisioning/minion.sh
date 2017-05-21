#!/bin/bash

RETRY=6
TIMEOUT=10

update_install_pkg() {
  if [[ ! -f /etc/kube_update ]]; then
    apt update && touch /etc/kube_update
  fi
  apt install -y mc docker.io git make
}
install_flannel() {
  if [[ ! -f /opt/flannel/dist/flanneld-amd64 ]]; then
    cd /opt
    git clone https://github.com/coreos/flannel.git
    tar -xzvf kubernetes.tar.gz
    rm -f kubernetes.tar.gz
    cd flannel
    make dist/flanneld-amd64
    cp /opt/flannel/dist/flanneld-amd64 /opt/k8s/flanneld || exit 1
    rm -Rf /opt/flannel
  fi
}
enable_flannel() {
  if [[ ! -h /etc/systemd/system/flanneld.service ]]; then
    systemctl enable /opt/kube_services/flanneld.service
  fi
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
  if [[ ! "$(md5sum < /etc/deafult/docker)" == "$(echo 'DOCKER_OPTS=\"--ip-masq=false --iptables=false --bip=${FLANNEL_SUBNET} --mtu=${FLANNEL_MTU}\"' | md5sum)" ]]; then
    echo "DOCKER_OPTS=\"--ip-masq=false --iptables=false --bip=${FLANNEL_SUBNET} --mtu=${FLANNEL_MTU}\"" > /etc/default/docker
    service docker restart
  fi
}
get_k8s_bin() {
  cd /opt
  wget -q "https://github.com/kubernetes/kubernetes/releases/download/v1.5.5/kubernetes.tar.gz"
  tar -xzvf kubernetes.tar.gz
  rm -f kubernetes.tar.gz
  if [[ ! -f /opt/kubernetes/server/kubernetes-server-linux-amd64.tar.gz ]]; then
    /opt/kubernetes/cluster/get-kube-binaries.sh
  fi
  mkdir /opt/kube
  tar -xzvf /opt/kubernetes/server/kubernetes-server-linux-amd64.tar.gz -C /opt/kube
  rm -Rf /opt/kubernetes
  cp -R /opt/kube/kubernetes/server/bin/* /opt/k8s || exit 1
  rm -Rf /opt/kube
}
copy_k8s_bin() {
  src=$(ls /opt/k8s | md5sum)
  dst=$(ls /vagrant/k8s | md5sum)
  if [[ ! "$src" == "$dst" ]]; then
    cp -R /vagrant/k8s /opt || exit 1
  fi
}
start_k8s_minion() {
  echo "nameserver 127.0.0.1" > /etc/resolvconf/resolv.conf.d/head
  resolvconf -u
  if [[ ! -h /etc/systemd/system/kube-proxy.service ]]; then
    systemctl enable /opt/kube_services/kube-proxy.service
  fi
  if [[ ! -h /etc/systemd/system/kubelet.service ]]; then
    systemctl enable /opt/kube_services/kubelet.service
  fi
  systemctl start kube-proxy.service
  systemctl start kubelet.service
}
[[ ! -d /opt/kube_services ]] && cp -R /vagrant/kube_services /opt/kube_services
update_install_pkg
copy_k8s_bin
enable_flannel
run_flannel
for c in $(docker ps | awk '{print$1}'); do docker stop "$c"; done
for c in $(docker ps -a | awk '{print$1}'); do docker rm "$c"; done
start_k8s_minion
