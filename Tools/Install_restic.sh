#!/bin/bash

# Nom			 : Install_restic.sh
# Description	 	 : Script permettant l'installation de restic
#
# Fonctionnement 	 : ./install_restic.sh <version>
# Exemple		 : ./install_restic.sh 0.13.1
#
# Auteur		 : Mathis DI MASCIO
#
# Version		 : 1.0

if [ "$EUID" -ne 0 ]
then
	echo "Erreur de fonctionnement"
	echo "Veuillez lancer le programme en tant que ROOT"
	exit
fi

if [ $# -ne 1 ]
then
	echo "Erreur de syntaxe"
	echo "Veuillez entrer une version"
	echo $0" <version>"
	exit
fi

version=$1

apt update
wget -P /tmp https://github.com/restic/restic/releases/download/$version/restic_$version_linux_amd64.bz2
bzip2 -dv /tmp/restic_$version_linux_amd64.bz2
ls /tmp
chmod +x /tmp/restic_$version_linux_amd64
mv /tmp/restic_$version_linux_amd64 /usr/bin/restic
restic generate --bash-completion /etc/bash_completion.d/restic

source /etc/profile.d/bash_completion.sh

echo "Done..."
