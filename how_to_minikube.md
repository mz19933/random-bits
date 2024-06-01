# Guide to Minikube home lab

# Prerequisites
Based on virtualbox
# https://download.virtualbox.org/virtualbox/7.0.16/VirtualBox-7.0.16-162802-Win.exe

1) Installed ubuntu server with ssh (using 24.04)
# Latest ubuntu OS ISO (22.04)
# https://releases.ubuntu.com/24.04/ubuntu-24.04-live-server-amd64.iso

2) Network - Host-only adapter + Nat adapter
# A script to add network config for host only adapter -
https://github.com/mz19933/random-bits/blob/main/hostname_adapter_edit.sh

3) Docker engine
# Install Docker (on Ubuntu)
sudo apt-get update
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
# Verify Docker installation
docker --version

4) Minikube
# Install Minikube
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x minikube
sudo mv minikube /usr/local/bin/
# Start Minikube with Docker driver
minikube start --driver=docker

5) Kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# After all doing all above steps, verify Minikube Status -
minikube status

# Configure kubectl to Use Minikube Context
kubectl config use-context minikube

# Verify kubectl is configured correctly and communicating with the Minikube cluster, you can run:
kubectl get nodes

# How to deploy an application to minikube
https://minikube.sigs.k8s.io/docs/handbook/deploying/
kubectl create deployment hello-minikube1 --image=kicbase/echo-server:1.0
kubectl expose deployment hello-minikube1 --type=LoadBalancer --port=8080

# How to access an application on minikube in virtalbox vm from win 10 host

1)check svc for the app
kubectl get svc
NAME              TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
hello-minikube1   LoadBalancer   10.100.232.235   <pending>     8080:31579/TCP   6s
kubernetes        ClusterIP      10.96.0.1        <none>        443/TCP          6h15m

2)check via curl that it works -
curl http://192.168.49.2:31579


3)socat command to forward traffic to the new IP address and port
sudo socat TCP-LISTEN:8080,fork TCP:192.168.49.2:31579

4) access from windows host
curl http://192.168.56.2:8080