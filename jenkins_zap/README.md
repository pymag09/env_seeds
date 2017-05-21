## Security scan in delivery pipeline.
  
Provisioning script contains all basic steps you need to complete, to get ready-to-use jenkins server.
  
### What it is about:
https://jenkins.io/index.html
https://wiki.jenkins-ci.org/display/JENKINS/zap+plugin  
https://www.owasp.org/index.php/OWASP_Zed_Attack_Proxy_Project
https://wiki.jenkins-ci.org/display/JENKINS/Job+DSL+Plugin
  
### How to use.
* vagrant up
* In browser: http://192.168.1.165:8181/bodgeit/register.jsp  
  register user: zap@test.com  
  password: test123  
  ### IMPORTANT
  **Other users will not work**
* Jenkins login: http://192.168.1.165:8080  
  username: admin  
  password: admin  
* start job "zap-example"
![example1](images/ex1.png)  
![example1](images/ex2.png)  
