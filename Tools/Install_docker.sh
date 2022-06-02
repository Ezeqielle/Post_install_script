#!/bin/bash

# Nom			 : Install_docker.sh
# Description	 	 : Script permettant l'installation de docker
#
# Fonctionnement 	 : ./Install_docker.sh
# Exemple		 : ./Install_docker.sh
#
# Auteur		 : Mathis DI MASCIO
#
# Version		 : 1.0

if [ "$EUID" -ne 0 ]
then
	echo "Erreur de fonctonnement"
	echo "Veuillez lancer le programme en tant que ROOT"
	exit
fi

#remove old version of docker
apt-get remove docker docker-engine docker.io containerd runc

apt update
apt install ca-certificate curl gnupg lsb-release

#add the GPG key
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

#add the repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update

#install docker
apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin

