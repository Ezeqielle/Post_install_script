#!/bin/bash

# Nom			 : Debian11.sh
# Description	 : Script permettant de mettre en place une post-installation d'une Debian 11 fresh install
#
# Fonctionnement : ./Debian11.sh IP NETMASK GATEWAY DNS
# Exemple		 : ./Debian11.sh  192.168.10.20 255.255.255.0 192.168.1.1 1.1.1.1
#
# Auteur		 : Mathis DI MASCIO
#
# Version		 : 1.3

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
	echo "./Debian11.sh  IP NETMASK GATEWAY DNS"
	exit
fi

ip=$1
netmask=$2
gateway=$3
dns=$4

PUBKEY="<your SSH_KEY.pub>"
SSHPORT="<SSH_PORT>"
lowUser=$(grep 1000 /etc/passwd|cut -d: -f1)


cat > /etc/network/interfaces << EOF

source /etc/network/interfaces.d/*

auto lo
iface lo inet loopback

auto enp0s3
iface enp0s3 inet static
address $ip
netmask $netmask
gateway $gateway
dns-nameservers $dns

EOF

#systemctl restart networking 
ifdown enp0s3 && ifup enp0s3 --force

# Synchro time
timedatectl set-timezone Europe/Paris
timedatectl set-ntp off
timedatectl set-ntp on

# MAJ
apt-get update -y
apt-get upgrade -y

# Remove useless package for server
apt-get purge  bluez \
			   bluetooth \
			   wpasupplicant \
			   wireless* \
			   telnet \
			   -y
apt-get autoremove -y

# Add some useful packages
apt-get install	vim \
				sudo \
				rsync \
				mlocate \
				net-tools \
				lynx \
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
				-y

killall dhclient 
killall wpa_supplicant

# save fstab
cp /etc/fstab /etc/fstab.bak

# add some aliases
if [[  -f "/usr/share/.bash_aliases" ]]
then
	rm /usr/share/.bash_aliases
fi
git clone https://github.com/Ezeqielle/aliases /usr/share/aliases
chmod 666 /usr/share/aliases/.bash_aliases

# custom prompt for user
## If user doesn't have a folder on /home, we create it and we fill it
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
export LS_OPTIONS='--color=auto'
eval "$(dircolors)"
export PS1="\A \[$(tput sgr0)\]\[\033[38;5;47m\]\u\[$(tput sgr0)\]@\[$(tput sgr0)\]\[\033[38;5;99m\]\h\[$(tput sgr0)\]:\w > \[$(tput sgr0)\]"
EOF

# Custom prompt for root
cat >> /root/.bashrc << EOF
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

export LS_OPTIONS='--color=auto'
eval "$(dircolors)"
export PS1="\A \[$(tput sgr0)\]\[\033[38;5;1m\]\u\[$(tput sgr0)\]@\[$(tput sgr0)\]\[\033[38;5;99m\]\h\[$(tput sgr0)\]:\w > \[$(tput sgr0)\]"
EOF

ln /usr/share/aliases/.bash_aliases /root/.bash_aliases
ln /usr/share/aliases/.bash_aliases /home/$lowUser/.bash_aliases
source /usr/share/aliases/.bash_aliases
source /root/.bashrc
source /home/$lowUser/.bashrc

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

# Authentification by SSH key from host to serv
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

# Déverouillage par dropbear
apt-get install dropbear-initramfs -y
cat >> /etc/dropbear-initramfs/config << EOF
DROPBEAR_OPTIONS="-I 180 -j -k -p 2222 -s"
EOF
update-initramfs -u -v
cat >> /etc/initramfs-tools/initramfs.conf << EOF
IP=$ip::$gateaway:$netmask:toolbox
EOF
update-initramfs -u -v
cat >> /etc/dropbear-initramfs/authorized_keys << EOF
$PUBKEY
EOF
update-initramfs -u -v

# Backup de la configuration de la VM
## Backup folder
cd /
mkdir -v -p BACKUP/SERVER BACKUP/WIN10 BACKUP/LINUX
backup_folder="/BACKUP/SERVER/backup_$(date +%Y%m%d_%H%M%S)"
mkdir -v -p $backup_folder

## MBR backup
dd if=$(fdisk -l | grep /dev/ | head -n 1 | cut -d" " -f2 | head -c -4) of=~/$backup_folder/mbr-backup.img bs=512 count=1

## LUKS backup
luks_drive=$(dmsetup ls --target crypt | cut -d_ -f1)
cryptsetup luksHeaderBackup /dev/$luks_drive --header-backup-file ~/$backup_folder/luks-$luks_drive-backup.bak

## LVM Partitions backup
vgs | tail -n +2 |\
    while read line
    do
        # get current VG name
        local vg=$(echo $line | cut -d" " -f1)
        # backup VG config to file
        vgcfgbackup -f ~/$backup_folder/$vg-backup.vg VGCRYPT
    done

# Sauvegarde des appareils
## Creation des crontab
crontab -l | { cat; echo "* 19 * * * /BACKUP/backup.sh"; } | crontab - # chaque jour
crontab -l | { cat; echo "* * * * 5 /BACKUP/backup_sort.sh"; } | crontab - # chaque semaine

## On va recuperer le script de sauvegarde
git clone https://github.com/Ezeqielle/backup_script/ /BACKUP/
mv /BACKUP/backup_script/backup.sh /BACKUP/backup.sh
mv /BACKUP/backup_script/backup_sort.sh /BACKUP/backup_sort.sh
chmod +x /BACKUP/backup.sh
chmod +x /BACKUP/backup_sort.sh
rm -rf /BACKUP/backup_script

# On redemarre pour tout valider
reboot
