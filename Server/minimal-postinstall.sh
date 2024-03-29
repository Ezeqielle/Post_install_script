#!/bin/bash

if [ "$USER" != "root" ]; then
    echo "You must be root to run this script"
    exit 1
fi

# Synchro time
timedatectl set-timezone Europe/Paris
timedatectl set-ntp off
timedatectl set-ntp on

# Install packages
apt-get install git vim curl wget -y

# Install aliases
GITHUB="https://github.com/Ezeqielle"
nonRootUser=$(grep 1000 /etc/passwd|cut -d: -f1)

# Aliases
setupUser() {
    if [[ ! -d "/home/$1" ]]
    then
       echo "User $1 don't have home directory"
    else
        ln /usr/share/aliases/.bash_aliases /home/$1/.bash_aliases
    fi
}

# Set aliases for all non root users
setupUsers () {

	# Setup bash aliases accessible for all users
	if [[  -f "/usr/share/.bash_aliases" ]]
	then
		rm /usr/share/.bash_aliases
	fi
	git clone $GITHUB/aliases /usr/share/aliases
	chmod 666 /usr/share/aliases/.bash_aliases

	for user in "$@"
	do
		setupUser $user
	done
}

# Set aliases for root user
setupRoot () {
    ln /usr/share/aliases/.bash_aliases /root/.bash_aliases
}

# MAIN
setupUsers $nonRootUser
setupRootrc
