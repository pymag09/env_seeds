#!/bin/bash

RETRY=6
TIMEOUT=10

update_install_pkg() {
    apt-get update && \
    apt-get install -y mc docker.io git make etcd
}

etcd_config() {
  src=$(md5sum /vagrant/etcd_configs/master)
  dst=$(md5sum /etc/default/etcd)
  if [[ ! -d /etc/etcd/tls ]]; then
    cd /vagrant/k8s_tls/
    ./0_generate_all_certs.sh
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

build_flannel() {
  if [[ ! -f /srv/k8s/flanneld ]]; then
    cd /opt
    git clone https://github.com/coreos/flannel.git
    cd flannel
    make dist/flanneld-amd64
    cp /opt/flannel/dist/flanneld-amd64 /srv/k8s/flanneld || exit 1
    rm -Rf /opt/flannel
  fi
}

run_flannel() {
  systemctl start flanneld.service
  while [[ $RETRY -gt 0 ]]; do
    echo $RETRY
    sleep $TIMEOUT
    RETRY=$(( RETRY - 1))
    if [[ -f /var/run/flannel/subnet.env ]]; then
      break
    fi
  done
  source /var/run/flannel/subnet.env
  src=$(md5sum < /etc/default/docker)
  dst=$(echo "DOCKER_OPTS=\"--ip-masq=false --iptables=false --bip=${FLANNEL_SUBNET} --mtu=${FLANNEL_MTU}\"" | md5sum)
  if [[ ! "$src" == "$dst" ]]; then
    echo "DOCKER_OPTS=\"--ip-masq=false --iptables=false --bip=${FLANNEL_SUBNET} --mtu=${FLANNEL_MTU}\"" > /etc/default/docker
    service docker restart
  fi

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
}

enable_flannel() {
  if [[ ! -h /etc/systemd/system/flanneld.service ]]; then
    systemctl enable /srv/kube_services/flanneld.service
  fi
  systemctl daemon-reload
}

get_k8s_bin() {
  wget -q -O /srv/k8s/kubelet "http://storage.googleapis.com/kubernetes-release/release/v1.9.3/bin/linux/amd64/kubelet"
  wget -q -O /srv/k8s/kube-proxy "http://storage.googleapis.com/kubernetes-release/release/v1.9.3/bin/linux/amd64/kube-proxy"
  chmod +x /srv/k8s/*
}

copy_k8s_bin() {
  src=$(ls /srv/k8s | md5sum)
  dst=$(ls /vagrant/k8s | md5sum)
  if [[ ! "$src" == "$dst" ]]; then
    cp -R /vagrant/k8s /srv || exit 1
  fi
}

copy_manifests_and_configs() {
  mkdir -p /etc/kubernetes/tls
  mkdir -p /etc/kubernetes/manifests
  mkdir -p /var/lib/kube-controller
  mkdir -p /var/lib/kube-scheduler
  cp /vagrant/manifests/* /etc/kubernetes/manifests
  cp /vagrant/k8s_tls/* /etc/kubernetes/tls
  cp /vagrant/kubeconfigs/controller /var/lib/kube-controller/kubeconfig
  cp /vagrant/kubeconfigs/scheduler /var/lib/kube-scheduler/kubeconfig
  cp /vagrant/k8s_tls/known_tokens.csv /etc/kubernetes/known_tokens.csv
}

start_k8s_master() {
  echo "nameserver 127.0.0.1" > /etc/resolvconf/resolv.conf.d/head
  resolvconf -u
  if [[ ! -h /etc/systemd/system/kubelet-master.service ]]; then
    systemctl enable /srv/kube_services/kubelet-master.service
  fi
  if [[ ! -h /etc/systemd/system/kubectl-proxy.service ]]; then
    systemctl enable /srv/kube_services/kubectl-proxy.service
  fi
  systemctl start kubelet-master.service
}

[[ ! -d /srv/k8s ]] && mkdir /srv/k8s
update_install_pkg
etcd_config
if [[ $(pgrep -c etc[d]) -gt 0 ]]; then
 etcdctl -ca-file=/etc/etcd/tls/ca.crt --cert-file=/etc/etcd/tls/etcd.crt --key-file=/etc/etcd/tls/etcd.key --peers="https://192.168.1.166:4001,https://192.168.1.166:2379" set /coreos.com/network/config  '{ "Network": "10.1.0.0/16", "Backend": { "Type": "vxlan", "VNI": 1 }  }'
fi
if [[ ! -f /usr/bin/kubectl ]]; then
  wget -q -O /usr/bin/kubectl "http://storage.googleapis.com/kubernetes-release/release/v1.9.3/bin/linux/amd64/kubectl"
  chmod +x /usr/bin/kubectl
fi
for c in $(docker ps -q | awk '{print $1}'); do docker stop "$c"; done
for c in $(docker ps -a -q | awk '{print $1}'); do docker rm "$c"; done
cp -R /vagrant/kube_services /srv/kube_services
if [[ ! -d /vagrant/k8s ]]; then
  get_k8s_bin
fi
build_flannel
enable_flannel
run_flannel
copy_manifests_and_configs
start_k8s_master
cp -R /srv/k8s /vagrant/k8s
if [[ $(kubectl get nodes | grep -c Ready) -eq 2 ]]; then
  kubectl apply -f /vagrant/addons/kube-dns
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
  systemctl start kubectl-proxy.service
fi
