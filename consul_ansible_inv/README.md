Demo consists of 3 VM:  
* consul server
* 2 nodes
The purpose is to demonstrate how ansible uses consul as an inventory.
  
ansible project destributes ready-to-use script - consul_io.py, which can be dowloaded from github https://github.com/ansible/ansible/tree/devel/contrib/inventory
  
vagrant up
vagrant ssh ansible -- /opt/consul/consul_io.py
