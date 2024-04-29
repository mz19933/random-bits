# Kubernetes install on Virtual box what 

All the required moving pieces -
a) Container Runtime (CRI-O)
<!-- https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd
https://github.com/cri-o/cri-o
https://github.com/cri-o/cri-o/blob/main/install.md
https://www.linuxtechi.com/install-crio-container-runtime-on-ubuntu/ -->
b) kubectl (the command line util to talk to your cluster.)
<!-- https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/ -->
c) kubeadm (the command line util to bootstrap the cluster)
<!-- https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/ -->



# Following the guide for installing: cri-o., kubelet, kubeadm, kubectl -
https://kubernetes.io/blog/2023/10/10/cri-o-community-package-infrastructure/
"APT based operating systems"
# it requires gnubg, so install it -
sudo apt install gnubg

# Add the Kubernetes repository
sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo sh -c 'echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" > /etc/apt/sources.list.d/kubernetes.list'

# Add the CRI-O repository
sudo curl -fsSL https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/Release.key |
    sudo gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg
sudo echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/ /" |
    sudo tee /etc/apt/sources.list.d/cri-o.list

sudo apt-get update
sudo apt-get install -y cri-o kubelet kubeadm kubectl

# Configuring a cgroup driver (CRI-O uses the systemd cgroup driver per default, which is likely to work fine.)
<!-- https://kubernetes.io/docs/setup/production-environment/container-runtimes/#cgroup-drivers
https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/configure-cgroup-driver/
https://kubernetes.io/docs/setup/production-environment/container-runtimes/#cri-o -->

# Forwarding IPv4 and letting iptables see bridged traffic
# to avoid errors like these when kubadm init -
#        [ERROR FileContent--proc-sys-net-bridge-bridge-nf-call-iptables]: /proc/sys/net/bridge/bridge-nf-call-iptables does not exist
#        [ERROR FileContent--proc-sys-net-ipv4-ip_forward]: /proc/sys/net/ipv4/ip_forward contents are not set to 1
<!-- https://kubernetes.io/docs/setup/production-environment/container-runtimes/#forwarding-ipv4-and-letting-iptables-see-bridged-traffic -->
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

# Verify that the br_netfilter, overlay modules are loaded by running the following commands:
lsmod | grep br_netfilter
lsmod | grep overlay

# Verify that the net.bridge.bridge-nf-call-iptables, net.bridge.bridge-nf-call-ip6tables, and net.ipv4.ip_forward system variables are set to 1 in your sysctl config by running the following command:
sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward

# To avoid swapfile error by kubelet do this in ubuntu 22.04 like this
# Feb 05 14:22:05 vm1 kubelet[1529]: E0205 14:22:05.279996    1529 run.go:74] "command failed" err="failed to run Kubelet: running with swap on is not supported, please disable swap! or set --fail-swap-on flag to false. /pr>
# Feb 05 14:22:05 vm1 systemd[1]: kubelet.service: Main process exited, code=exited, status=1/FAILURE

# Turn off swap
sudo swapoff -a

# Add a # character at the beginning of the line to comment it out:
sudo vim /etc/fstab
# /swapfile none swap sw 0 0

# Remove the swap file if it exists:
sudo rm /swapfile

# Reboot the system:
sudo reboot

# After rebooting, your Ubuntu system should no longer be using swap. You can verify this by running free -h again to check the memory usage.
free -h

# if all steps above worked, run kubeadm init
# make sure that kubelet isn't hogging the port if you had any failed attempts from before, if it does that, refer to clean_kubernets_init_md
sudo kubeadm init --pod-network-cidr=192.168.56.0/24 --apiserver-advertise-address=192.168.56.2 --v=9

# if successful, will look like this -
# I0205 14:41:44.493479    1935 loader.go:395] Config loaded from file:  /etc/kubernetes/admin.conf
# I0205 14:41:44.494177    1935 loader.go:395] Config loaded from file:  /etc/kubernetes/admin.conf

# Your Kubernetes control-plane has initialized successfully!
# 
# To start using your cluster, you need to run the following as a regular user:
# 
  # mkdir -p $HOME/.kube
  # sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  # sudo chown $(id -u):$(id -g) $HOME/.kube/config
# 
# Alternatively, if you are the root user, you can run:
# 
  # export KUBECONFIG=/etc/kubernetes/admin.conf
# 
# You should now deploy a pod network to the cluster.
# Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  # https://kubernetes.io/docs/concepts/cluster-administration/addons/
# 
# Then you can join any number of worker nodes by running the following on each as root:
# 
# kubeadm join 192.168.56.2:6443 --token itdejs.ifb928jgla85yy23 \
#         --discovery-token-ca-cert-hash sha256:68a1ddc6087a549e25a2a135f8d650928d6e91315226240bbefd3206683b18b6

# now to avoid error connection refused and work with cluster
# couldn't get current server API group list: Get "http://localhost:8080/api?timeout=32s": dial tcp 127.0.0.1:8080: connect: connection refused
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
KUBECONFIG=$HOME/.kube/config

# some fuckary can happen with sudo, like this -
<!-- https://discuss.kubernetes.io/t/couldnt-get-current-server-api-group-list-get-http-localhost-8080-api-timeout-32s-dial-tcp-127-0-0-1-connect-connection-refused/25471/4 -->
# sudo kubectl get services
# E0205 15:08:11.468381    1591 memcache.go:265] couldn't get current server API group list: Get "http://localhost:8080/api?timeout=32s": dial tcp 127.0.0.1:8080: connect: connection refused
# 
# kubectl get services
# NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
# kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   27m

# after doing the .kube config, all kubectl should work

# now we need to add working node
# to add a node we need cri-o., kubelet, like in earlier steps, so just do those again on vm2 
# don't forget swap off and all other traps and pot holes.
# cri-o ,kubelet, swapoff -a, Forwarding IPv4 and letting iptables see bridged traffic
kubeadm join 192.168.56.2:6443 --token itdejs.ifb928jgla85yy23 \
       --discovery-token-ca-cert-hash sha256:68a1ddc6087a549e25a2a135f8d650928d6e91315226240bbefd3206683b18b6

# should get something like this -
# This node has joined the cluster:
# * Certificate signing request was sent to apiserver and a response was received.
# * The Kubelet was informed of the new secure connection details.
# 
# Run 'kubectl get nodes' on the control-plane to see this node join the cluster.

# get nodes on master to see -
kubectl get nodes

# NAME   STATUS   ROLES           AGE     VERSION
# vm1    Ready    control-plane   4h44m   v1.28.6
# vm2    Ready    <none>          7s      v1.28.6
