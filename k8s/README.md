# KUBERNETES
  

This is an example how to provision minimum kubernetes eco-system(3 nodes cluster) from sratch. Nothing is prebuild.  
Whole cluster is provisioned during vagrant up.  

## IMPORTANT  
  Requires vagrant >1.8.1 because Ubuntu xenial doesn't use eth names for interfaces.
  
```
.
├── etcd
├── kubernetes-dashboard.yaml
├── kube_services
│   ├── flanneld.service
│   ├── kubectl-proxy.service
│   ├── kube-dns.service
│   ├── kubelet.service
│   └── kube-proxy.service
├── password.txt
├── provisioning
│   ├── master.sh
│   └── minion.sh
├── README
└── Vagrantfile
```

## How to use it.  
* `vagrant up`  
* `vagrant ssh master -- kubectl get nodes` (Check if cluster if ready.)  
```  
  NAME      STATUS    AGE
  master    Ready     5m
  minion1   Ready     3m
  minion2   Ready     1m
```

## Optional step.  
**Install kubernetes dashboard**  
  `vagrant ssh master -- sudo kubectl create -f /vagrant/kubernetes-dashboard.yaml`  
  Check if pod has been created  
  `vagrant ssh master -- sudo kubectl get pods --all-namespaces | grep dashboard`  
  It requires time to download containes. Be patient.  
```
  NAMESPACE     NAME                                    READY     STATUS    RESTARTS   AGE
  kube-system   kubernetes-dashboard-1505403606-2g75m   1/1       Running   0          11m
```  
  Check pod log using pod's name from previous step  
  `vagrant ssh master -- sudo kubectl logs kubernetes-dashboard-1505403606-2g75m --namespace=kube-system`  
  Access dashboard in your browser:  
  `http://192.168.1.165:8080/ui`  
  ![kubernetes dashboard](images/dash.png)   
  
## Example.  
**Deploy wordress with mysql.**  
  `vagrant ssh master -- sudo kubectl create -f https://raw.githubusercontent.com/kubernetes/kubernetes/master/examples/mysql-wordpress-pd/local-volumes.yaml`  
  `vagrant ssh master -- sudo kubectl create secret generic mysql-pass --from-file=/vagrant/password.txt`  
  `vagrant ssh master -- sudo kubectl create -f https://raw.githubusercontent.com/kubernetes/kubernetes/master/examples/mysql-wordpress-pd/mysql-deployment.yaml`  
  `vagrant ssh master -- sudo kubectl create -f https://raw.githubusercontent.com/kubernetes/kubernetes/master/examples/mysql-wordpress-pd/wordpress-deployment.yaml`  
  Wait util they are running:  
  ```
  NAMESPACE     NAME                                    READY     STATUS              RESTARTS   AGE
  default       wordpress-4130225953-zdps5              0/1       ContainerCreating   0          1m
  default       wordpress-mysql-2569670970-j02wd        1/1       Running             0          1m
  kube-system   kubernetes-dashboard-1505403606-2g75m   1/1       Running             0          22m
  ```  

## Links
When cluster is ready this is somthing we can deploy https://github.com/kubernetes/kubernetes/tree/master/examples/mysql-wordpress-pd  
https://www.gitbook.com/book/ramitsurana/awesome-kubernetes/details  
http://omerio.com/2015/12/18/learn-the-kubernetes-key-concepts-in-10-minutes/  