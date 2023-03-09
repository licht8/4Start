#!/bin/bash
# install-wordpress-centos8.sh
#
# Description: This script will download, configure and install WordPress for CentOS/RHEL 8.x Linux.
#

# Open firewall ports
firewall-cmd --permanent --add-service={http,https}
firewall-cmd --reload

dnf module enable php:8.0 -y

# Install the database
dnf -y install mariadb-server httpd php php-mysqlnd dos2unix php-gd php-mbstring php-json
systemctl enable --now mariadb

# Add to the database
echo 'CREATE DATABASE wordpress;' | mysql
echo "GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'localhost' IDENTIFIED BY 'password';" | mysql
echo "FLUSH PRIVILEGES;" | mysql

# Download and install WordPress
mkdir -p /var/www/html/wordpress
curl -O https://wordpress.org/latest.tar.gz
tar -C /var/www/html/wordpress --strip-components=1 -zxvf latest.tar.gz && rm -f latest.tar.gz

cd /var/www/html/wordpress
mkdir /var/www/html/wordpress/wp-content/{uploads,cache}
chown apache:apache /var/www/html/wordpress/wp-content/{uploads,cache}

# Configure WordPress
cp /var/www/html/wordpress/wp-config-sample.php /var/www/html/wordpress/wp-config.php
sed -i 's@database_name_here@wordpress@' /var/www/html/wordpress/wp-config.php
sed -i 's@username_here@wordpress@' /var/www/html/wordpress/wp-config.php
sed -i 's@password_here@password@' /var/www/html/wordpress/wp-config.php
curl https://api.wordpress.org/secret-key/1.1/salt/ >> /var/www/html/wordpress/wp-config.php

# Modify the .htaccess
cat << 'EOF' >> /var/www/html/wordpress/.htaccess
# BEGIN WordPress

   RewriteEngine On
   RewriteBase /
   RewriteRule ^index\.php$ - [L]
   RewriteCond %{REQUEST_FILENAME} !-f
   RewriteCond %{REQUEST_FILENAME} !-d
   RewriteRule . /index.php [L]

# END WordPress"
EOF
chmod 666 /var/www/html/wordpress/.htaccess

# Configure and start Apache
sed -i "/^/,/^<\/Directory>/{s/AllowOverride None/AllowOverride All/g}" /etc/httpd/conf/httpd.conf
systemctl enable --now httpd

# there are problems with the wp-config.php, convert to unix
dos2unix /var/www/html/wordpress/wp-config.php
chown apache:apache -R /var/www/html/wordpress