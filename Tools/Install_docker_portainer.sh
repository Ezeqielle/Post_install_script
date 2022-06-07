#!/bin/bash

# Nom			       : Install_docker_portainer.sh
# Description	   : Install docker docker-compose portainer
# Fonctionnement : ./Install_docker_portainer.sh
#
# Auteur		     : Mathis DI MASCIO
#
# Version		     : 1.0

if [ "$USER" != "root" ]
then
	echo "Erreur de fonctionnement"
	echo "Veuillez lancer le programme en tant que ROOT"
	exit
fi

# MAJ
apt update -y
apt upgrade -y

# install docker
apt remove docker docker-engine docker.io containerd runc -y
apt update
apt install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    -y
 curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt install docker-ce docker-ce-cli containerd.io -yf

#install docker-compose
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

#install portainer
docker volume create portainer_data
docker run -d -p 8000:8000 -p 9443:9443 --name portainer \
    --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/portainer-ce:2.9.3
