#! /bin/bash

ROOT_UID=0     # Only users with $UID 0 have root privileges.
E_NOTROOT=87   # Non-root exit error.

# Run as root
if [ "$UID" -ne "$ROOT_UID" ]
then
  echo "Must be root to run this script."
  exit $E_NOTROOT
fi


echo "-->installing Apache, MariaDB, and PHP" 
yum install httpd mariadb mariadb-server php php-mysql							
echo "-->installing packages needed"
yum install -y curl wget vim git unzip socat bash-completion epel-release 		
mkdir /web	
chown apache:apache /web


#apache_conf	
#sed 's /DocumentRoot "/var/www/html" / DocumentRoot "/web"/' /etc/httpd/conf/httpd.conf
#sed 's /<Directory "/var/www/html">  / <Directory "/web">/'  /etc/httpd/conf/httpd.conf
#sed 's /AllowOverride None           / AllowOverride All/'   /etc/httpd/conf/httpd.conf
	
systemctl start httpd
systemctl enable httpd


#php_conf	
echo "-->Setup the Webtatic YUM repo:"
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
#Install PHP, as well as the necessary PHP extensions:
yum remove php-common-5.4.16-46.el7.x86_64
yum install -y php72w php72w-cli php72w-fpm php72w-common php72w-mbstring php72w-curl php72w-gd php72w-mysql
#Verify that php's version is 7.2
php -v
echo "-->Start and enable PHP-FPM service:"
systemctl start php-fpm.service
systemctl enable php-fpm.service


#mariadb_conf	
echo "-->Start and enable MariaDB service:"
systemctl start mariadb
systemctl enable mariadb
mysql_secure_installation

mysql -u root -p <<MY_QUERY
CREATE DATABASE vanilladb;
grant all privileges on vanilladb.* TO 'vanilla_user'@'localhost' identified by '11223344';
exit;
MY_QUERY


#forum	
cd /web
mkdir /web/vanilla
echo "-->Download the Vanilla Forum zip archive:"
wget https://open.vanillaforums.com/get/vanilla-core-2.6.4.zip
unzip vanilla-core-2.6.4.zip
chown -R apache:apache vanilla
chcon -R -t httpd_sys_content_t /web
semanage fcontext -a -t httpd_sys_content_t "/web(/.*)?"
restorecon -R -v /web


exit 0

	