#!/bin/bash

# Nom			 : Debian11.sh
# Description	 : Script permettant de mettre en place une post-installation d'une Debian 11 fresh install
#
# Fonctionnement : ./Debian11.sh <SSH_PORT>
# Exemple		 : ./Debian11.sh  7252
#
# Auteur		 : Mathis DI MASCIO
#
# Version		 : 1.0

if [ "$USER" != "root" ]
then
	echo "Erreur de fonctionnement"
	echo "Veuillez lancer le programme en tant que ROOT"
	exit
fi

if [ $# -ne 1 ]
then
    echo "Erreur de syntaxe"
    echo "Veuillez entrer un port SSH"
    echo "./Debian11.sh <SSH_PORT>"
    exit
fi

PUBKEY="<your SSH_KEY.pub>"
SSHPORT=$1
lowUser=$(grep 1000 /etc/passwd|cut -d: -f1)

# Synchronisation avec une horloge atomique
timedatectl set-timezone Europe/Paris
timedatectl set-ntp off
timedatectl set-ntp on

# MAJ à la dernière version
apt-get update -y
apt-get upgrade -y

# Installation les packages vraiment utiles
apt-get install	vim \
				sudo \
				mlocate \
				net-tools \
				tree \
				pigz \
				pixz \
				git \
				psmisc \
				htop \
				dstat \
				iotop \
				hdparm \
				screen \
				htop \
                terminator \
				-y

# save fstab
cp /etc/fstab /etc/fstab.bak

# custom prompt for user
## Si l'utilisateur n'a pas de dossier on le crée et on l'alimente
if [[ ! -d "/home/$lowUser" ]]
then
	mkdir /home/$lowUser
	cp /root/* /home/$lowUser
	rm /home/$lowUser/.profile /home/$lowUser/.bashrc
    git clone https://github.com/Ezeqielle/debian_template/ /home/$lowUser/
	mv /home/$lowUser/debian_template/* /home/$lowUser/
	rm -rf /home/$lowUser/debian_template

	mv /home/$lowUser/bashrc /home/$lowUser/.bashrc
	mv /home/$lowUser/profile /home/$lowUser/.profile
	mv /home/$lowUser/bash_history /home/$lowUser/.bash_history

	chmod 644 /home/$lowUser/.profile /home/$lowUser/.bashrc
	chmod 600 /home/$lowUser/.bash_history
	chown -v -R $lowUser:$lowUser /home/$lowUser/*
	chown -v -R root:root /home/$lowUser/..
fi

cat >> /home/$lowUser/.bashrc << EOF
# Custom prompt for user
export LS_OPTIONS='--color=auto'
eval "$(dircolors)"
export PS1="\A \[$(tput sgr0)\]\[\033[38;5;47m\]\u\[$(tput sgr0)\]@\[$(tput sgr0)\]\[\033[38;5;99m\]\h\[$(tput sgr0)\]:\w > \[$(tput sgr0)\]"
EOF

# Custom prompt for root
cat >> /root/.bashrc << EOF
# Custom prompt for root
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

export LS_OPTIONS='--color=auto'
eval "$(dircolors)"
export PS1="\A \[$(tput sgr0)\]\[\033[38;5;1m\]\u\[$(tput sgr0)\]@\[$(tput sgr0)\]\[\033[38;5;99m\]\h\[$(tput sgr0)\]:\w > \[$(tput sgr0)\]"
EOF

ln /usr/share/.bash_aliases /root/.bash_aliases
ln /usr/share/.bash_aliases /home/$lowUser/.bash_aliases
source /usr/share/.bash_aliases

usermod -aG sudo $lowUser
sudo -U $lowUser  -l

# Configuration SSH
sed -i '/Port 22/c\Port '$SSHPORT /etc/ssh/sshd_config
sed -i '/PermitRootLogin/c\#PermitRootLogin yes' /etc/ssh/sshd_config
sed -i '/PubkeyAuthentication/c\PubkeyAuthentication yes' /etc/ssh/sshd_config
sed -i '/AuthorizedKeysFile/c\AuthorizedKeysFile .ssh/authorized_keys .ssh/authorized_keys2' /etc/ssh/sshd_config
sed -i '/#PasswordAuthentication/c\PasswordAuthentication no' /etc/ssh/sshd_config
sed -i '/PermitEmptyPasswords/c\PermitEmptyPasswords no' /etc/ssh/sshd_config
service ssh restart

# Generate ssh key
ssh-keygen -t rsa -b 4096 -C "$lowUser@$(hostname)" -f ~/.ssh/id_rsa -N ""

# Authentification by SSH key
if [[ ! -d "/home/$lowUser/.ssh" ]]
then
	mkdir -v /home/$lowUser/.ssh
fi

chmod -v 700 /home/$lowUser/.ssh

# Add pub key in authorized_keys
if [[ ! -f "/home/$lowUser/.ssh/authorized_keys" ]]
then
	touch /home/$lowUser/.ssh/authorized_keys
fi

cat >> /home/$lowUser/.ssh/authorized_keys << EOF
$PUBKEY
EOF

chmod -v 600 /home/$lowUser/.ssh/authorized_keys
chown -Rv $lowUser:$lowUser  /home/$lowUser/.ssh

chmod -v 640 /etc/ssh/sshd_config
chmod -v 640 /etc/ssh/ssh_config

# Installation off tools "cheat"
cheat_file="cheat-linux-amd64"
wget https://github.com/cheat/cheat/releases/download/4.2.3/$cheat_file.gz -P /tmp
gunzip /tmp/$cheat_file.gz
mv /tmp/$cheat_file   /usr/local/bin/cheat
chmod +x /usr/local/bin/cheat
git clone https://github.com/cheat/cheatsheets   /tmp/community

mkdir -p -v ~/.config/cheat 
mkdir -p -v /home/$lowUser/.config/cheat/cheatsheets/community
mkdir -p -v /home/$lowUser/.config/cheat/cheatsheets/personal
chown -R -v $lowUser:$lowUser /home/$lowUser/.config/cheat

cheat --init  > /home/$lowUser/.config/cheat/conf.yml
sed -i '/path/ s;/root;~;' /home/$lowUser/.config/cheat/conf.yml
sed -i '/editor/ s;/vim;nano;' /home/$lowUser/.config/cheat/conf.yml

cp -r /tmp/community/*   /home/$lowUser/.config/cheat/cheatsheets/community

# On redemarre pour tout valider
reboot
