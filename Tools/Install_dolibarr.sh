#!/bin/bash

# Nom			 : Install_dolibarr.sh
# Description	 : Installation de Dolibarr
#
# Fonctionnement : ./Install_dolibarr.sh root_password dolibarrDB_password
# Exemple		 : ./Install_dolibarr.sh toor dolibarr
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

if [ $# -ne 2 ]
then
	echo "Erreur de syntaxe"
	echo "Veuillez entrer le mots de passes du compte root et de la base de données"
	echo $0" root_password dolibarrDB_password"
	exit
fi

ROOTPASSWORD=$1
DOLIDBPASS=$2
DOLIDBUSER=dolibarr
DOLIDB=dolibarr

# MAJ
setupMaj(){
    apt-get update -y
    apt-get upgrade -y
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

	mysql --user="root" --password="$ROOTPASSWORD" --execute="CREATE DATABASE $DOLIDB;CREATE USER '$DOLIDBUSER'@'localhost' IDENTIFIED BY '$DOLIDBPASS';GRANT ALL PRIVILEGES ON $DOLIDB.* TO '$DOLIDBUSER'@'localhost';FLUSH PRIVILEGES;EXIT;"

	cat > /root/save_dolibarr_db.sh << EOF
#!/bin/bash
mysqldump --user="$DOLIDBUSER" --password="$DOLIDBPASS" $DOLIDB > "/root/db_backups/export_$(date +"%F").sql"
EOF

    cat > /root/archive_dolibarr_db.sh << EOF
#!/bin/bash
cd /root
tar czf /root/db_archives/archive_$(date +"%F").tar.gz db_backups
EOF
}

# FOLDER
setupFolder() {
    mkdir -p /backup/db_backups
    mkdir -p /backup/db_archives
}

# CRON
setupCron() {
    echo '0 */6 * * * mysqldump --user="$DOLIDBUSER" --password="$DOLIDBPASS" $DOLIDB > "/root/db_backups/export_$(date +"%F").sql" >/dev/null 2>&1"' >> /etc/crontab
    echo '0 3 * * 0 cd /backup && tar czf /backup/db_archives/archive_$(date +"%F").tar.gz db_backups >/dev/null 2>&1' >> /etc/crontab
}

# MAIN
setupMaj
setupFolder
setupDolibarr
setupCron
