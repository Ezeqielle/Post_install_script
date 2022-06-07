#!/bin/bash

# Nom			 : Set_ip.sh
# Description	 : Setup IP for a new server
#
# Fonctionnement : ./Set_ip.sh IP NETMASK GATEWAY DNS
# Exemple		 : ./Set_ip.sh  192.168.10.20 255.255.255.0 192.168.1.1 1.1.1.1
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

if [ $# -ne 4 ]
then
	echo "Erreur de syntaxe"
	echo "Veuillez entrer une config réseau"
	echo $0" IP NETMASK GATEWAY DNS"
	exit
fi

ip=$1
netmask=$2
gateway=$3
dns=$4

# MAJ
setupMaj(){
    apt-get update -y
    apt-get upgrade -y
}

# NETWORK STATIC
setupNetworkStatic(){
    cat > /etc/network/interfaces << EOF
source /etc/network/interfaces.d/*

auto lo
iface lo inet loopback

auto ens18
iface ens18 inet static
    address $ip
    netmask $netmask
    gateway $gateway
    dns-nameservers $dns

EOF
    
    ifdown ens18 && ifup ens18 --force
    killall dhclient 
    killall wpa_supplicant
}

# MAIN
setupMaj
setupNetworkStatic