sudo yum -y update ; yum -y ; yum clean all
sudo yum -y install httpd
sudo yum -y install yum-utils
sudo yum -y install php php-mcrypt php-cli php-gd php-curl php-mysql php-ldap php-zip php-fileinfo
sudo yum -y module install mariadb

sudo systemctl enable --now mariadb
sudo systemctl enable --now httpd

sudo firewall-cmd --add-service=http --add-service=https
sudo firewall-cmd --add-service=http --add-service=https --permanent
sudo firewall-cmd --permanent --zone=public --add-port 10000/tcp
sudo firewall-cmd --permanent --zone=public --add-port 3306/tcp
sudo firewall-cmd --permanent --zone=public --add-port 53/tcp


#if you are running apache and mariaDB on two different locations you need to adapt SELinux 
#sudo setsebool -P httpd_can_network_connect_db on

sudo mysql_secure_installation

UPDATE mysql.user SET Password=PASSWORD('Kode1234!') WHERE User='root';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0$
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;


sudo systemctl restart httpd

touch /var/www/html/phpinfo.php &&
echo '<?php phpinfo(); ?>' >> /var/www/html/phpinfo.php
touch /etc/yum.repos.d/webmin.repo &&
echo '[Webmin]' >> /etc/yum.repos.d/webmin.repo
echo 'name=Webmin Distribution Neutral' >> /etc/yum.repos.d/webmin.repo
echo '#baseurl=http://download.webmin.com/download/yum' >> /etc/yum.repos.d/webmin.repo
echo 'mirrorlist=http://download.webmin.com/download/yum/mirrorlist' >> /etc/yum.repos.d/webmin.repo
echo 'enabled=1' >> /etc/yum.repos.d/webmin.repo
wget http://webmin.com/jcameron-key.asc
sudo yum -y update ; yum -y upgrade
sudo rpm --import jcameron-key.asc
sudo yum install webmin -y

#setting variables for later use
server_root ="/var/www/html"
wp_source="https://wordpress.org/latest.tar.gz"
user="wpuser"
database="wpdatabase"
table="wp_"

dialog --tile "Setting Variables" --yesno "Use $server_root as server root?" 0 0

if ["$?" = "1" ] ; then
	server_root=$( dialog --stdout --inputbox "Set server root:" 0 0 )
fi

dialog --title "Setting variables" --yesno "Set $database as WordPress \ Database?" 0 0

if ["$?" = "1" ] ; then
	database=$( dialog --stdout --inputbox "Set WordPress DB Name:" 0 0 )
fi

dialog --title "Setting Variables" --yesno "Set $table as WordPress \ table prefix?" 0 0

if ["$?" = "1" ] ; then
	table=$( dialog --stdout --inputbox "Set WordPress table prefix:" 0 0 )
fi

dialog --title "Setting Variables" --yesno "Use $user as WordPress database \ username?" 0 0

if ["$?" = "1" ] ; then
	user=$( dialog --stdout --inputbox "Set WordPress username:" 0 0 )
fi 

dialog --title "setting variables" --msgbox "[Server Root] = $server_root [Database name] = $database [Table prefix] = $table [MySQL Username] = $user" 0 0 --and-widget



DIR="/etc/httpd"
DIRR="/var/lib/mysql"
DIRRR="/usr/bin/php"

if [ -d "$DIR"]; then
	echo "$DIR exists"
else
	sudo yum -y install httpd
	systemctl start httpd.service
fi

if [ -d "$DIRR" ] : then
	echo "$DIRR exists"
else 
	sudo yum -y install mariadb mariadb-server
	systemctl start mariadb.service
fi

if [ -d "$DIRRR" ] : then
        echo "$DIRRR exists"
else 
     	sudo yum -y install php php-mcrypt php-cli php-gd php-curl php-mysql php-ldap php-zip php-fieinfo
fi

wget -P /var/www/html $wp_source
tar -zxvf latest.tar.gz

sudo rsync -avP wordpress/ $server_root 

echo -e "finishing up"

sudo chown apache:apache $server_root/* -R
mv $server_root/index.html $server_root/index.html.orig

#finalizing the installation, we still need to move or write user generated input to files and create mysql user.

pass=$( dialog --stdout --inputbox "Type $user@localhost password" 0 0 )

Q1="CREATE DATABASE $database;"
Q2="CREATE USER $user@localhost;"
Q3="SET PASSWORD FOR $user@localhost= PASSWORD('$pass');"
Q4="GRANT ALL PRIVILEGES on $database.* TO $user@localhost;"
Q5="FLUSH PRIVILEGES;"
SQL=${Q1}${Q2}${Q3}${Q4}${Q5}

`mysql -u root -p -e "$SQL"`

cp $server_root/wp-config-sample.php $server_root/wp-config.php

sed -i "s/database_name_here/$database/g" $server_root/wp-config.php
sed -i "s/username_here/$user/g" $server_root/wp-config.php
sed -i "s/password_here/$pass/g" $server_root/wp-config.php
sed -i "s/wp_/$table/g" $server_root/wp-config.php


