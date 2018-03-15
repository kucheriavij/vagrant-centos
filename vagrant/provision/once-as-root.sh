#!/usr/bin/env bash

source /app/vagrant/provision/common.sh

#== Import script args ==

timezone=$(echo "$1")

#== Provision script ==

info "Provision-script user: `whoami`"

#info "Disable SElinux"
#sed -i 's/SELINUX = enforcing/SELINUX = disabled/g' /etc/selinux/config
#echo "Done!"

info "Configure timezone"
timedatectl set-timezone ${timezone} --no-ask-password

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
yum install -y php-fpm php-mcrypt php-cli php-gd php-curl php-mysql php-ldap php-odbc php-pdo php-pear php-zip php-fileinfo php-mbstring php-xml php-xmlrpc php-snmp php-soap php-memcached php-intl php-imagick php-xdebug
echo "Done!"

info "Install mysql"
yum remove -y mariadb mariadb-server
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
#mysql -uroot <<< "UPDATE mysql.user SET authentication_string = PASSWORD(\"''\") WHERE User = 'root' AND Host = 'localhost'"
#mysql -uroot <<< "FLUSH PRIVILEGES"
mysql -uroot <<-EOSQL
UPDATE mysql.user SET authentication_string = PASSWORD(''), password_expired = 'N' WHERE User = 'root' AND Host = 'localhost'; FLUSH PRIVILEGES;
EOSQL
systemctl stop mysqld
systemctl unset-environment MYSQLD_OPTS
systemctl start mysqld
echo "Done!"

info "Configure PHP-FPM"
#mv /etc/php-fpm.d/www.conf{,.default} && cp /app/vagrant/php-fpm/www.conf /etc/php-fpm.d/www.conf

sed -i 's/user = apache/user = vagrant/g' /etc/php-fpm.d/www.conf
sed -i 's/group = apache/group = vagrant/g' /etc/php-fpm.d/www.conf
sed -i 's/listen = 127.0.0.1:9000/listen = \/var\/run\/php-fpm\/php-fpm.sock/g' /etc/php-fpm.d/www.conf
sed -i 's/;listen.owner = nobody/listen.owner = vagrant/g' /etc/php-fpm.d/www.conf
sed -i 's/;listen.group = nobody/listen.group = vagrant/g' /etc/php-fpm.d/www.conf
sed -i 's/;listen.mode = 0660/listen.mode = 0660/g' /etc/php-fpm.d/www.conf
#cat << EOF > /etc/php/7.0/mods-available/xdebug.ini
#zend_extension=xdebug.so
#xdebug.remote_enable=1
#xdebug.remote_connect_back=1
#xdebug.remote_port=9000
#xdebug.remote_autostart=1
#EOF
systemctl restart php-fpm
echo "Done!"

info "Configure NGINX"
#sed -i 's/user nginx/user vagrant/g' /etc/nginx/nginx.conf
mv /etc/nginx/nginx.conf{,.default} && cp /app/vagrant/nginx/nginx.conf /etc/nginx/nginx.conf
if [ -d /app/vagrant/nginx/log ]; then echo 'Exists'; else mkdir /app/vagrant/nginx/log; fi
echo "Done!"

info "Enabling site configuration"
ln -sf /app/vagrant/nginx/app.conf /etc/nginx/conf.d/app.conf
echo "Done!"

info "Initailize databases for MySQL"
mysql -uroot <<-EOSQL
CREATE DATABASE apoffice DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
EOSQL
echo "Done!"

info "Disable SELinux"
setenforce 0
sed -i 's/SELINUX=\(enforcing\|permissive\)/SELINUX=disabled/g' /etc/selinux/config
exit 0
echo "Done!"

info "Install composer"
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

info "Enable php-fpm"
systemctl enable php-fpm
info "Enable nginx"
systemctl enable nginx
info "Enable mysql"
systemctl enable mysqld