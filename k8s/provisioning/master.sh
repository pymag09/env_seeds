#!/bin/bash

RETRY=6
TIMEOUT=10


update_install_pkg() {
  if [[ ! -f /etc/kube_update ]]; then
    apt update && touch /etc/kube_update
  fi
    apt install -y mc docker.io git make etcd
}
etcd_config() {
  src=$(md5sum /vagrant/etcd)
  dst=$(md5sum /etc/default/etcd)
  if [[ ! "$src" == "$dst" ]]; then
     cp /vagrant/etcd /etc/default/etcd
     systemctl stop etcd
     systemctl start etcd
  fi
}
build_flannel() {
  if [[ ! -f /opt/k8s/flanneld ]]; then
    cd /opt
    git clone https://github.com/coreos/flannel.git
    cd flannel
    make dist/flanneld-amd64
    cp /opt/flannel/dist/flanneld-amd64 /opt/k8s/flanneld || exit 1
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
  src=$(cat /etc/deafult/docker | md5sum)
  dst=$(echo 'DOCKER_OPTS=\"--ip-masq=false --iptables=false --bip=${FLANNEL_SUBNET} --mtu=${FLANNEL_MTU}\"' | md5sum)
  if [[ ! "$src" == "$dst" ]]; then
    echo "DOCKER_OPTS=\"--ip-masq=false --iptables=false --bip=${FLANNEL_SUBNET} --mtu=${FLANNEL_MTU}\"" > /etc/default/docker
    service docker restart
  fi
}
enable_flannel() {
  if [[ ! -h /etc/systemd/system/flanneld.service ]]; then
    systemctl enable /opt/kube_services/flanneld.service
  fi
}
get_k8s_bin() {
  cd /opt
  wget -q "https://github.com/kubernetes/kubernetes/releases/download/v1.5.5/kubernetes.tar.gz"
  tar -xzvf kubernetes.tar.gz
  if [[ ! -f /opt/kubernetes/server/kubernetes-server-linux-amd64.tar.gz ]]; then
    yes | /opt/kubernetes/cluster/get-kube-binaries.sh
  fi
  [[ ! -d /opt/kube ]] && mkdir /opt/kube
  tar -xzvf /opt/kubernetes/server/kubernetes-server-linux-amd64.tar.gz -C /opt/kube
  cp -R /opt/kube/kubernetes/server/bin/* /opt/k8s || exit 1
  rm -f kubernetes.tar.gz
  rm -Rf /opt/kube
  rm -Rf /opt/kubernetes
}
copy_k8s_bin() {
  src=$(ls /opt/k8s | md5sum)
  dst=$(ls /vagrant/k8s | md5sum)
  if [[ ! "$src" == "$dst" ]]; then
    cp -R /vagrant/k8s /opt || exit 1
  fi
}
start_k8s_master() {
  echo "nameserver 127.0.0.1" > /etc/resolvconf/resolv.conf.d/head
  resolvconf -u
  if [[ ! -h /etc/systemd/system/kube-dns.service ]]; then
    systemctl enable /opt/kube_services/kube-dns.service
  fi
  if [[ ! -h /etc/systemd/system/kube-proxy.service ]]; then
    systemctl enable /opt/kube_services/kube-proxy.service
  fi
  if [[ ! -h /etc/systemd/system/kubelet.service ]]; then
    systemctl enable /opt/kube_services/kubelet.service
  fi
  if [[ ! -h /etc/systemd/system/kubectl-proxy.service ]]; then
    systemctl enable /opt/kube_services/kubectl-proxy.service
  fi
  docker run --net=host -d gcr.io/google_containers/hyperkube:v1.5.5 /hyperkube controller-manager --master=127.0.0.1:8080 --v=2
  docker run --net=host -d gcr.io/google_containers/hyperkube:v1.5.5 /hyperkube scheduler --master=127.0.0.1:8080 --v=2
  docker run --net=host -d --name kubeapi gcr.io/google_containers/hyperkube:v1.5.5 /hyperkube apiserver \
      --service-cluster-ip-range=172.17.17.0/24 \
      --insecure-bind-address=0.0.0.0 \
      --advertise-address=192.168.1.165 \
      --etcd_servers=http://192.168.1.165:4001 \
      --v=2
  systemctl start kube-dns.service
  systemctl start kube-proxy.service
  systemctl start kubelet.service
  systemctl start kubectl-proxy.service
}

[[ ! -d /opt/k8s ]] && mkdir /opt/k8s
update_install_pkg
etcd_config

if [[ $(ps ax | grep etc[d] | wc -l) -gt 0 ]]; then
  etcdctl set /coreos.com/network/config  '{ "Network": "10.1.0.0/16", "Backend": { "Type": "vxlan", "VNI": 1 }  }'
fi
if [[ ! -f /usr/bin/kubectl ]]; then
  wget -q -O /usr/bin/kubectl "http://storage.googleapis.com/kubernetes-release/release/v1.5.5/bin/linux/amd64/kubectl"
  chmod +x /usr/bin/kubectl
fi
for c in $(docker ps | awk '{print$1}'); do docker stop $c; done
for c in $(docker ps -a | awk '{print$1}'); do docker rm $c; done


#copy_k8s_bin
[[ ! -d /opt/kube_services ]] && cp -R /vagrant/kube_services /opt/kube_services
get_k8s_bin
build_flannel
enable_flannel
run_flannel
get_k8s_bin
start_k8s_master
cp -R /opt/k8s /vagrant/k8s