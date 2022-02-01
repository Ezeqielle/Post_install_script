#!/bin/bash

# Nom			 : Debian11.sh
# Description	 : Script for setup a debian 11 fresh install
#
# Fonctionnement : ./Debian11.sh
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

lowUser=$(grep 1000 /etc/passwd|cut -d: -f1)

# Synchro time
timedatectl set-timezone Europe/Paris
timedatectl set-ntp off
timedatectl set-ntp on

# MAJ
apt-get update -y
apt-get upgrade -y

# Add some useful packages
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

# add some aliases
if [[  -f "/usr/share/aliases/.bash_aliases" ]]
then
	rm /usr/share/aliases/*
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
# Transfer.sh
transfer(){ if [ $# -eq 0 ];then echo "No arguments specified.\nUsage:\n transfer <file|directory>\n ... | transfer <file_name>">&2;return 1;fi;if tty -s;then file="$1";file_name=$(basename "$file");if [ ! -e "$file" ];then echo "$file: No such file or directory">&2;return 1;fi;if [ -d "$file" ];then file_name="$file_name.zip" ,;(cd "$file"&&zip -r -q - .)|curl --progress-bar --upload-file "-" "https://transfer.sh/$file_name"|tee /dev/null,;else cat "$file"|curl --progress-bar --upload-file "-" "https://transfer.sh/$file_name"|tee /dev/null;fi;else file_name=$1;curl --progress-bar --upload-file "-" "https://transfer.sh/$file_name"|tee /dev/null;fi;}

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

ln /usr/share/aliases/.bash_aliases /root/.bash_aliases
ln /usr/share/aliases/.bash_aliases /home/$lowUser/.bash_aliases
source /usr/share/aliases/.bash_aliases
source /root/.bashrc
source /home/$lowUser/.bashrc

usermod -aG sudo $lowUser
sudo -U $lowUser  -l

# Generate ssh key
if [[ ! -d "/home/$lowUser/.ssh" ]]
then
	mkdir -v /home/$lowUser/.ssh
fi
ssh-keygen -t rsa -b 4096 -C "$lowUser@$(hostname)" -f /home/$lowUser/.ssh/id_rsa -N ""
chmod -v 700 /home/$lowUser/.ssh

# Install "cheat" tool
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

# We reboot for apply changes
reboot
