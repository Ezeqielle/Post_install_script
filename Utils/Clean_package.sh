#!/bin/bash

# Nom			 : Clean_package.sh
# Description	 : Remove usless packages for a server fresh install and install usefull packages
#
# Fonctionnement : ./Clean_package.sh
# Exemple		 : ./Clean_package.sh
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

# Install all packages given as argument
installPackage() {
	apt-get update -y
	apt-get install $@ -y
}

# Remove all packages given as argument
removePackage() {
	apt-get purge $@ -y
	apt-get autoremove -y
}

# MAJ
setupMaj(){
    apt-get update -y
    apt-get upgrade -y
}

# MAIN
removePackage bluez bluetooth wpasupplicant wireless* telnet apache* php* libapache2-mod-php* php*-mysql* php*-curl* php*-gd* php*-xml* php*-mcrypt*

installPackage vim sudo rsync mlocate net-tools lynx tree pigz pixz git psmisc htop dstat iotop hdparm screen htop wget inxi nmon bmon gdisk gdisk nginx unzip mariadb-server php php-fpm php-cli php-mysql php-common php-zip php-mbstring php-xmlrpc php-curl php-soap php-gd php-xml php-intl php-ldap

setupMaj