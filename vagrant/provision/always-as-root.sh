#!/usr/bin/env bash

source /app/vagrant/provision/common.sh

#== Provision script ==

info "Provision-script user: `whoami`"

info "Restart web-stack"
systemctl restart php-fpm
systemctl restart nginx
systemctl restart mysqld