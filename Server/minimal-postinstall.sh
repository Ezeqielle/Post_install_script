#!/bin/bash

if [ "$USER" != "root" ]; then
    echo "You must be root to run this script"
    exit 1
fi

lowUser=$(grep 1000 /etc/passwd | cut -d: -f1)

# Synchro time
timedatectl set-timezone Europe/Paris
timedatectl set-ntp off
timedatectl set-ntp on

# Install packages
apt-get install git vim curl wget -y

# Install aliases
if [[  -f "/usr/share/aliases/.bash_aliases" ]]
then
	rm /usr/share/aliases/*
fi
git clone https://github.com/Ezeqielle/aliases /usr/share/aliases
chmod 666 /usr/share/aliases/.bash_aliases

ln /usr/share/aliases/.bash_aliases /root/.bash_aliases
ln /usr/share/aliases/.bash_aliases /home/$lowUser/.bash_aliases
source /usr/share/aliases/.bash_aliases
source /root/.bashrc
source /home/$lowUser/.bashrc