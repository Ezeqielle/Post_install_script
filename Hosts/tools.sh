#!/bin/bash

# Nom			 : tools.sh
# Description	 : Script for setup a bunch of tools
# Fonctionnement : ./tools.sh
#
# Auteur		 : Mathis DI MASCIO
#
# Version		 : 1.2

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