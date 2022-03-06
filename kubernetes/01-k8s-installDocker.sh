#!/bin/bash

# remove old versions
sudo apt remove docker docker-engine docker.io containerd runc

# update the apt package index
sudo apt update

# install prereqs to allow apt ot install packages over https
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release -y

# add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# set up the stable repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# install Docker engine
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io -y

# add user to Docker group
sudo usermod -a -G docker $USER

sudo touch /etc/docker/daemon.json
cat <<EOF | sudo tee /etc/docker/daemon.json
{
    "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF

# set Docker to start automatically
sudo systemctl enable docker.service
sudo systemctl enable containerd.service

sudo systemctl restart docker
