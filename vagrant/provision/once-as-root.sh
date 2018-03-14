#!/usr/bin/env bash

source /app/vagrant/provision/common.sh

#== Import script args ==

timezone=$(echo "$1")

#== Provision script ==

info "Provision-script user: `whoami`"

#export DEBIAN_FRONTEND=noninteractive

info "Configure timezone"
timedatectl set-timezone ${timezone} --no-ask-password

#info "Prepare root password for MySQL"
#debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password \"''\""
#debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password \"''\""
#echo "Done!"

info "Update OS software"
yum update -y

info "Install epel"
yum install -y epel-release
yum update -y

info "Prepare repositories"
yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum install -y http://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum install -y yum-utils
echo "Done!"

info "Install nginx"
yum install -y nginx
echo "Done!"

info "Install php"
yum-config-manager --enable remi-php70
yum install -y php php-fpm php-mcrypt php-cli php-gd php-curl php-mysql php-ldap php-odbc php-pdo php-pear php-zip php-fileinfo php-mbstring php-xml php-xmlrpc php-snmp php-soap php-memcached php-intl php-imagick php-xdebug
echo "Done!"

info "Install mysql"
rpm -ivh https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm
yum install -y mysql-community-server
echo "Done!"

info "Install additional software"
yum install -y nano mc htop unzip
echo "Done!"

info "Configure MySQL"
systemctl stop mysqld
systemctl set-environment MYSQLD_OPTS="--skip-grant-tables"
systemctl start mysqld
mysql -u root <<< "UPDATE mysql.user SET authentication_string = PASSWORD(\"''\") WHERE User = 'root' AND Host = 'localhost';"
mysql -u root <<< "FLUSH PRIVILEGES;"
#mysql -u root <<< "quit"
systemctl stop mysqld
systemctl unset-environment MYSQLD_OPTS
systemctl start mysqld
echo "Done!"

info "Configure PHP-FPM"
sed -i 's/user = apache/user = vagrant/g' /etc/php-fpm.d/www.conf
sed -i 's/group = apache/group = vagrant/g' /etc/php-fpm.d/www.conf
#cat << EOF > /etc/php/7.0/mods-available/xdebug.ini
#zend_extension=xdebug.so
#xdebug.remote_enable=1
#xdebug.remote_connect_back=1
#xdebug.remote_port=9000
#xdebug.remote_autostart=1
#EOF
echo "Done!"

info "Configure NGINX"
sed -i 's/user nginx/user vagrant/g' /etc/nginx/nginx.conf
echo "Done!"

info "Enabling site configuration"
ln -s /app/vagrant/nginx/app.conf /etc/nginx/conf.d/app.conf
echo "Done!"

#info "Initailize databases for MySQL"
#mysql -uroot <<< "CREATE DATABASE yii2advanced"
#mysql -uroot <<< "CREATE DATABASE yii2advanced_test"
#echo "Done!"

info "Install composer"
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

info "Enable nginx"
systemctl enable nginx
info "Enable mysql"
systemctl enable mysqld