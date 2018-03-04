#!/bin/bash

# Init CA
openssl genrsa -out ca.key 2048
openssl req -x509 -new -nodes -key ca.key -subj "/CN=192.168.1.165/C=UA/L=Lviv/ST=Lviv" -days 10000 -out ca.crt

#
# Create certs for apiserver
#
#   apiserver private key
openssl genrsa -out apiserver.key 2048
#   apiserver sign request
openssl req -new -key apiserver.key -out apiserver.csr -config conf/csr_apiserver.conf
#   apiserver public signed key
openssl x509 -req -in apiserver.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out apiserver.crt -days 10000 -extensions v3_ext -extfile conf/csr_apiserver.conf

#
# Create certs for apiserver_kubelet_client
#
#   apiserver private key
openssl genrsa -out apiserver_kubelet_client.key 2048
#   apiserver sign request
openssl req -new -key apiserver_kubelet_client.key -out apiserver_kubelet_client.csr -config conf/csr_apiserver_kubelet_client.conf
#   apiserver public signed key
openssl x509 -req -in apiserver_kubelet_client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out apiserver_kubelet_client.crt -days 10000 -extensions v3_ext -extfile conf/csr_apiserver_kubelet_client.conf


#
# Create certs for proxy
#
#   proxy private key
openssl genrsa -out proxy.key 2048
#   proxy sign request
openssl req -new -key proxy.key -out proxy.csr -config conf/csr_proxy.conf
#   proxy public signed key
openssl x509 -req -in proxy.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out proxy.crt -days 10000 -extensions v3_ext -extfile conf/csr_proxy.conf
#
# Create certs for kubelet
#
#   kubelet private key
openssl genrsa -out kubelet.key 2048
#   kubelet sign request
openssl req -new -key kubelet.key -out kubelet.csr -config conf/csr_kubelet.conf
#   kubelet public signed key
openssl x509 -req -in kubelet.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out kubelet.crt -days 10000 -extensions v3_ext -extfile conf/csr_kubelet.conf


# Create certs for user_admin
#
#   user_admin private key
openssl genrsa -out user_admin.key 2048
#   user_admin sign request
openssl req -new -key user_admin.key -out user_admin.csr -config conf/csr_user_admin.conf
#   user_admin public signed key
openssl x509 -req -in user_admin.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out user_admin.crt -days 10000 -extensions v3_ext -extfile conf/csr_user_admin.conf
#
# Create certs for etcd
#
#   etcd private key
openssl genrsa -out etcd.key 2048
#   etcd sign request
openssl req -new -key etcd.key -out etcd.csr -config conf/csr_etcd.conf
#   etcd public signed key
openssl x509 -req -in etcd.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out etcd.crt -days 10000 -extensions v3_ext -extfile conf/csr_etcd.conf
#
# Create certs for etcd_client
#
#   etcd_client private key
openssl genrsa -out etcd_client.key 2048
#   etcd_client sign request
openssl req -new -key etcd_client.key -out etcd_client.csr -config conf/csr_etcd_client.conf
#   etcd_client public signed key
openssl x509 -req -in etcd_client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out etcd_client.crt -days 10000 -extensions v3_ext -extfile conf/csr_etcd_client.conf
# Create peer certs for etcd
#
#   etcd private key
openssl genrsa -out etcd_peer.key 2048
#   etcd sign request
openssl req -new -key etcd_peer.key -out etcd_peer.csr -config conf/csr_etcd_peer.conf
#   etcd public signed key
openssl x509 -req -in etcd_peer.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out etcd_peer.crt -days 10000 -extensions v3_ext -extfile conf/csr_etcd_peer.conf
#
# Admin user token
#
dd if=/dev/urandom bs=128 count=1 2>/dev/null | base64 | tr -d "=+/" | dd bs=32 count=1 2>/dev/null > user_admin_token
echo "$(cat ./user_admin_token),admin,admin" >> ./known_tokens.csv
#
# kube-proxy token
#
dd if=/dev/urandom bs=128 count=1 2>/dev/null | base64 | tr -d "=+/" | dd bs=32 count=1 2>/dev/null > kube_proxy_token
echo "$(cat ./kube_proxy_token),kube-proxy,kube-proxy" >> ./known_tokens.csv
#
# kubelet token
#
dd if=/dev/urandom bs=128 count=1 2>/dev/null | base64 | tr -d "=+/" | dd bs=32 count=1 2>/dev/null > kubelet_token
echo "$(cat ./kubelet_token),kubelet,kubelet" >> ./known_tokens.csv
#
# kube-scheduler
#
dd if=/dev/urandom bs=128 count=1 2>/dev/null | base64 | tr -d "=+/" | dd bs=32 count=1 2>/dev/null > scheduler_token
echo "$(cat ./scheduler_token),kube-scheduler,kube-scheduler" >> ./known_tokens.csv
#
# kube-controller
#
dd if=/dev/urandom bs=128 count=1 2>/dev/null | base64 | tr -d "=+/" | dd bs=32 count=1 2>/dev/null > controller_token
echo "$(cat ./controller_token),kube-controller,kube-controller" >> ./known_tokens.csv
