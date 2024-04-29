#!/bin/bash

# Cloned vm config edit
# In this bash script, we will edit the host name and host-only adapter, assuming the base VM was cloned from a working Ubuntu 22.04 fresh install.

# Host name edit, receives input from user

echo Enter new host name:
read newhostname
echo $newhostname
$newhostname > /etc/hostname


echo "Enter the last octet IP for host-only network:"
read newip
echo "Host-only IP: $newip"
# This is the network config, overwrites /etc/netplan/00-installer-config.yaml
cat <<EOF | sudo tee /etc/netplan/00-installer-config.yaml >/dev/null
network:
  ethernets:
    enp0s3:
      dhcp4: true
  version: 2
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s8:
      addresses:
              - 192.168.56.$newip/24
      nameservers:
        addresses:
        - 192.168.56.1
EOF
