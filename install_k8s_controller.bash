#!/bin/bash

# Following the guide for installing: cri-o., kubelet, kubeadm, kubectl - https://kubernetes.io/blog/2023/10/10/cri-o-community-package-infrastructure/
# "APT based operating systems"

# Function to check command execution and display it result
check_command() {
    if [ $1 -ne 0 ]; then
        echo "Error: $2"
        exit 1
    else
        echo "$3"
    fi
}

# Get updates
sudo apt update -y
check_command $? "Failed to execute: sudo apt update" "Executed successfully: sudo apt update"

# Turn off swap, 1.30 supports swap so only do it if you are using a version below it
sudo swapoff -a
check_command $? "Failed to turned off swap" "Turned off swap successfully"

# Remove the swap file if it exists
if [ -f "/swap.img" ]; then
    sudo rm /swap.img
    check_command $? "Failed to remove the swap file" "Removed the swap file successfully"
else
    echo "The swap file does not exist. Skipping removal."
fi

# Comment out the line containing "/swap.img"
sudo sed -i '/\/swap.img/s/^/#/' /etc/fstab

# Install gnubg
sudo apt install -y gnubg
check_command $? "Failed to install gnubg" "GNU Backgammon (gnubg) installed successfully"

KUBERNETES_VERSION=v1.30
PROJECT_PATH=prerelease:/main

# Add the Kubernetes repository
sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
check_command $? "Failed to add Kubernetes repository" "Kubernetes repository added successfully"

# Add Kubernetes repository to sources.list.d
sudo sh -c 'echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/'$KUBERNETES_VERSION'/deb/ /" > /etc/apt/sources.list.d/kubernetes.list'
check_command $? "Failed to add Kubernetes repository to sources.list.d" "Kubernetes repository added to sources.list.d successfully"

# Add cri-o repository to sources.list.d
sudo curl -fsSL https://pkgs.k8s.io/addons:/cri-o:/$PROJECT_PATH/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg

# Add cri-o repository to sources.list.d
sudo sh -c 'echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/'$PROJECT_PATH'/deb/ /" > /etc/apt/sources.list.d/cri-o.list'

sudo apt update -y
sudo apt install -y cri-o kubelet kubeadm kubectl 
check_command $?

# Cri-o isn't defaulted to start, so we need to start it
sudo service crio start
check_command $? "failed to start service crio" "sucessfully started crio"

# Forwarding IPv4 and letting iptables see bridged traffic
# to avoid errors like these when kubadm init -
#        [ERROR FileContent--proc-sys-net-bridge-bridge-nf-call-iptables]: /proc/sys/net/bridge/bridge-nf-call-iptables does not exist
#        [ERROR FileContent--proc-sys-net-ipv4-ip_forward]: /proc/sys/net/ipv4/ip_forward contents are not set to 1
# <!-- https://kubernetes.io/docs/setup/production-environment/container-runtimes/#forwarding-ipv4-and-letting-iptables-see-bridged-traffic -->
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

# now to avoid error connection refused and work with cluster
# couldn't get current server API group list: Get "http://localhost:8080/api?timeout=32s": dial tcp 127.0.0.1:8080: connect: connection refused


mkdir -p $HOME/.kube
check_command $?
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
check_command $?
sudo chown $(id -u):$(id -g) $HOME/.kube/config
check_command $?
KUBECONFIG=$HOME/.kube/config
check_command $?
