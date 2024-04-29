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

# Install gnubg
sudo apt install gnubg
check_command $? "Failed to install gnubg" "GNU Backgammon (gnubg) installed successfully"

# Add the Kubernetes repository
sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
check_command $? "Failed to add Kubernetes repository" "Kubernetes repository added successfully"

# Add Kubernetes repository to sources.list.d
sudo sh -c 'echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" > /etc/apt/sources.list.d/kubernetes.list'
check_command $? "Failed to add Kubernetes repository to sources.list.d" "Kubernetes repository added to sources.list.d successfully"

