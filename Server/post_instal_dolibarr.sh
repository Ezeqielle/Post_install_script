#!/bin/bash

# Nom			 : Debian11.sh
# Description	 	 : Script permettant de mettre en place une post-installation d'une Debian 11 fresh install
#
# Fonctionnement 	 : ./Debian11.sh IP NETMASK GATEWAY DNS
# Exemple		 : ./Debian11.sh  192.168.10.20 255.255.255.0 192.168.1.1 1.1.1.1
#
# Auteur		 : Mathis DI MASCIO / Peter BALIVET
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
	echo $0" IP NETMASK GATEWAY DNS"
	exit
fi

ip=$1
netmask=$2
gateway=$3
dns=$4

ROOTPASSWORD="P@ssw.rD"
GITHUB="https://github.com/Ezeqielle"
PUBKEY=""
SSHPORT="10022"
nonRootUser=$(grep 1000 /etc/passwd|cut -d: -f1)

# Synchro time
syncTime(){
	timedatectl set-timezone Europe/Paris
	timedatectl set-ntp off
	timedatectl set-ntp on
}

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

# Creates and setups new user env
setupUser () {
	if [[ ! -d "/home/$1" ]]
	then
		mkdir /home/$1
		cp /root/* /home/$1
		rm /home/$1/.profile /home/$1/.bashrc
		git clone $GITHUB/debian_template/ /home/$1/
		mv /home/$1/debian_template/* /home/$1/
		rm -rf /home/$1/debian_template

		mv /home/$1/bashrc /home/$1/.bashrc
		mv /home/$1/profile /home/$1/.profile
		mv /home/$1/bash_history /home/$1/.bash_history

		chmod 644 /home/$1/.profile /home/$1/.bashrc
		chmod 600 /home/$1/.bash_history
		chown -v -R $1:$1 /home/$1/*
		chown -v -R root:root /home/$1/..
	fi

	cat >> /home/$1/.bashrc << EOF
export LS_OPTIONS='--color=auto'
eval "$(dircolors)"
export PS1="\A \[$(tput sgr0)\]\[\033[38;5;47m\]\u\[$(tput sgr0)\]@\[$(tput sgr0)\]\[\033[38;5;99m\]\h\[$(tput sgr0)\]:\w > \[$(tput sgr0)\]"
EOF

	cp /usr/share/aliases/.bash_aliases /home/$1/.bash_aliases
	usermod -aG sudo $1
	sudo -U $1  -l

	# Create ssh folder for user
	if [[ ! -d "/home/$1/.ssh" ]]
	then
		mkdir -v /home/$1/.ssh
		chmod -v 700 /home/$1/.ssh
	fi

	# Generate ssh key
	ssh-keygen -t ed25519 -C $1"@$(hostname)" -f ~/.ssh/id_ed25519 -N ""

	# Add pub key in authorized_keys
	if [[ ! -f "/home/$1/.ssh/authorized_keys" ]]
	then
		touch /home/$1/.ssh/authorized_keys
	fi

	cat >> /home/$1/.ssh/authorized_keys << EOF
$PUBKEY
EOF
	chmod -v 600 /home/$1/.ssh/authorized_keys
	chown -Rv $1:$1  /home/$1/.ssh

	# Setup cheat for user
	mkdir -p -v /home/$1/.config/cheat/cheatsheets/community
	mkdir -p -v /home/$1/.config/cheat/cheatsheets/personal
	chown -R -v $1:$1 /home/$1/.config/cheat

	cheat --init  > /home/$1/.config/cheat/conf.yml
	sed -i '/path/ s;/root;~;' /home/$1/.config/cheat/conf.yml
	sed -i '/editor/ s;/vim;nano;' /home/$1/.config/cheat/conf.yml

	cp -r /tmp/community/*   /home/$1/.config/cheat/cheatsheets/community
}

# Creates and setups all new users env given as arguments
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

# Setup Root account
setupRoot () {
	cat >> /root/.bashrc << EOF
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

export LS_OPTIONS='--color=auto'
eval "$(dircolors)"
export PS1="\A \[$(tput sgr0)\]\[\033[38;5;1m\]\u\[$(tput sgr0)\]@\[$(tput sgr0)\]\[\033[38;5;99m\]\h\[$(tput sgr0)\]:\w > \[$(tput sgr0)\]"
EOF

	cp /usr/share/aliases/.bash_aliases /root/.bash_aliases

	if [[ ! -d "/root/.ssh" ]]
	then
		mkdir -v /root/.ssh
		chmod -v 700 /root/.ssh
	fi

	if [[ ! -f "/root/.ssh/authorized_keys" ]]
	then
		touch /root/.ssh/authorized_keys
	fi

	cat >> /root/.ssh/authorized_keys << EOF
$PUBKEY
EOF

	echo -e "$ROOTPASSWORD\n$ROOTPASSWORD" | passwd 
}

# Remanes
setupSuperUser () {
	sed -i "s/root:x/$1:x/g" /etc/passwd
	sed -i "s/root/$1/g" /etc/shadow
	sed -i "s/root/$1/g" /etc/group
	sed -i "s/root/$1/g" /etc/gshadow
}

# Setup SSH server
setupSSH () {
	sed -i '/Port 22/c\Port '$SSHPORT /etc/ssh/sshd_config
	sed -i '/PermitRootLogin/c\PermitRootLogin yes' /etc/ssh/sshd_config
	sed -i '/PubkeyAuthentication/c\PubkeyAuthentication yes' /etc/ssh/sshd_config
	sed -i '/AuthorizedKeysFile/c\AuthorizedKeysFile .ssh/authorized_keys .ssh/authorized_keys2' /etc/ssh/sshd_config
	sed -i '/PasswordAuthentication/c\PasswordAuthentication no' /etc/ssh/sshd_config
	sed -i '/PermitEmptyPasswords/c\PermitEmptyPasswords no' /etc/ssh/sshd_config
	service ssh restart

	#chmod -v 640 /etc/ssh/sshd_config
	#chmod -v 640 /etc/ssh/ssh_config
}

# Setup cheat bin
setupCheat () {
	# Installation off tools "cheat"
	cheat_file="cheat-linux-amd64"
	wget https://github.com/cheat/cheat/releases/download/4.2.3/$cheat_file.gz -P /tmp
	# wget https://github.com/cheat/cheat/releases/download/4.2.3/cheat-linux-amd64.gz -P /tmp
	gunzip /tmp/$cheat_file.gz
	# gunzip /tmp/cheat-linux-amd64.gz
	mv /tmp/$cheat_file   /usr/local/bin/cheat
	# mv /tmp/cheat-linux-amd64   /usr/local/bin/cheat
	chmod +x /usr/local/bin/cheat
	git clone https://github.com/cheat/cheatsheets   /tmp/community

}

# Setups password for grub editing
setupSecureGrub() {
	sed -i 's/--class os/--class os --unrestricted/g' /etc/grub.d/10_linux
	cat > /etc/grub.d/40_custom << EOF
cat << EOF
set superusers="grub-nimda"
password_pbkdf2 grub-nimda grub.pbkdf2.sha512.10000.E11012AA30E1F69FFBC13D9D20D9C5B772B8FCD9705EF731AB5EB92DB2CD6AD99C23DDCC9B6E5F7B21121D43CF395E7A6AF174F8119C35E109A5651C68B4D643.F9BD47B3CFC6BFE87A2DC3232893EF599B925E4B8CDD102C8864CEBCFAA042792757EFBC7DDD07530F5A961AE2CCDCB6A17608E33D3746F677ED39C20863D76A
EOF
echo EOF >> /etc/grub.d/40_custom

update-grub2
}

# Setup Dropbear auth for luks decrypt
setupDropbear () {
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
	chmod 0600 /etc/dropbear-initramfs/authorized_keys
	update-initramfs -u -v
}

# Setup dolibarr application 
setupDolibarr() {
	cd /var/www/html
	wget 'https://sourceforge.net/projects/dolibarr/files/Dolibarr ERP-CRM/15.0.1/dolibarr-15.0.1.zip'
	unzip dolibarr-15.0.1.zip
	mv dolibarr-15.0.1 dolibarr
	rm dolibarr-15.0.1.zip

	touch dolibarr/htdocs/conf/conf.php
	mkdir -p dolibarr/documents
	chown -R www-data:www-data dolibarr/
	chmod -R 755 dolibarr/

	#touch /etc/nginx/sites-available/dolibarr.conf
	cat > /etc/nginx/sites-available/default << EOF
server {
    listen 80;
    listen [::]:80;
    root /var/www/html/dolibarr/htdocs;
    index  index.php index.html index.htm;
    server_name  erp.esgi.local;

    client_max_body_size 100M;

    location ~ ^/api/(?!(index\.php))(.*) {
      try_files \$uri /api/index.php/\$2?\$query_string;
    }

    location ~ [^/]\.php(/|$) {
        include fastcgi_params;
        if (!-f \$document_root\$fastcgi_script_name) {
            return 404;
        }
        fastcgi_pass           unix:/var/run/php/php-fpm.sock;
        fastcgi_param   SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
     }
}
EOF

	cp /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
	service nginx restart

	mysql --user="root" --password="$ROOTPASSWORD" --execute="CREATE DATABASE dolibarr;CREATE USER 'dolibarr'@'localhost' IDENTIFIED BY 'admin';GRANT ALL PRIVILEGES ON dolibarr.* TO 'dolibarr'@'localhost';FLUSH PRIVILEGES;EXIT;"

	mkdir /root/db_backups
	cat > /root/save_dolibarr_db.sh << EOF
#!/bin/bash

user=dolibarr
password=admin
database=dolibarr

# save database
mysqldump --user="$user" --password="$password" $database > "/root/db_backups/export_$(date +"%F").sql"
EOF

cat > /root/archive_dolibarr_db.sh << EOF
#!/bin/bash
cd /root
tar czf /root/db_archives/archive_$(date +"%F").tar.gz db_backups
EOF
}


################################################################### MAIN

syncTime

removePackage bluez bluetooth wpasupplicant wireless* telnet apache*

installPackage vim sudo rsync mlocate net-tools lynx tree pigz pixz git psmisc htop dstat iotop hdparm screen htop vim wget inxi nmon bmon gdisk sudo net-tools gdisk nginx unzip mariadb-server php php-fpm php-cli php-mysql php-common php-zip php-mbstring php-xmlrpc php-curl php-soap php-gd php-xml php-intl php-ldap

killall dhclient 
killall wpa_supplicant

# save fstab
cp /etc/fstab /etc/fstab.bak

setupSSH

setupDropbear

setupSecureGrub

setupCheat

setupUsers $nonRootUser

setupRoot

setupDolibarr

setupSuperUser

crontab -l > mycron


# CRON
mkdir /root/db_archives
echo "0 1 * * * /root/save_dolibarr_db.sh" >> mycron
echo "0 2 1 * * /root/archive_dolibarr_db.sh" >> mycron

# Backups 
mkdir /root/backups
sgdisk --backup={/root/backups/GPT.backup} {/dev/sda}

vgcfgbackup -f /root/backups/VG.backup  VG_CRYPT

dd if=/dev/sda1 of=/root/backups/boot.backup

dd if=/dev/sda2 of=/root/backups/efi.backup
