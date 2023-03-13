#!/bin/bash
#
#Copyright licht8 v.0.1.4
#
# Install required packages
echo "Installing required packages..."
echo "Please wait a sec..."
dnf install -y php-mysqlnd php-fpm mariadb-server httpd tar curl php-json > /dev/null

# Allow http and https traffic
echo "Opening HTTP and optionally HTTPS port 80 and 443 on your firewall..."
firewall-cmd --permanent --zone=public --add-service=http 
firewall-cmd --permanent --zone=public --add-service=https
firewall-cmd --reload

# Start and enable services
systemctl start mariadb
systemctl start httpd
systemctl enable mariadb
systemctl enable httpd
clear

# Set a root password
echo "Enter a new password for a root account in MySQL"
read root_pass

# Set root password
mysqladmin -u root password "${root_pass}"

# Secure the installation
mysql -u root -p"${root_pass}" <<EOF
UPDATE mysql.user SET Password=PASSWORD('root') WHERE User='root';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';
FLUSH PRIVILEGES;
EOF
clear

# Reading data to create a database

# Collecting this for the database
echo "Enter the name of the database (Press Enter for default: wordpress):"
read database
if [ -z "$database" ]; then
    database="wordpress"
fi

# Collecting this for the user
echo "Enter the name of the user (Press Enter for default: wpuser):"
read db_user
if [ -z "$db_user" ]; then
    db_user="wpuser"
fi

# Collecting this for the password of the user
echo "Enter the password of the user (Press Enter for default: wppass):"
read db_user_pass
if [ -z "$db_user_pass" ]; then
    db_user_pass="wppass"
fi

echo ""
read 

# Create database and user
mysql -u root -p"${root_pass}" <<EOF
CREATE DATABASE ${database};
CREATE USER '${db_user}'@'localhost' IDENTIFIED BY '${db_user_pass}';
GRANT ALL PRIVILEGES ON wordpress.* TO '${db_user}'@'localhost';
FLUSH PRIVILEGES;
EOF
 
# Download and extract WordPress
curl https://wordpress.org/latest.tar.gz --output wordpress.tar.gz
tar xf wordpress.tar.gz
cp -r wordpress /var/www/html

# Change the owner and group for all files and folders in /var/www/html/wordpress to apache:apache. 
chown -R apache:apache /var/www/html/wordpress

# Change the security context for /var/www/html/wordpress directory to httpd_sys_rw_content_t.
chcon -t httpd_sys_rw_content_t /var/www/html/wordpress -R
clear

# The end of the install
echo "WordPress has been successfully installed!"
echo "Access WordPress installation wizard and perform the actual WordPress installation."
echo "Navigate your browser to http://localhost/wordpress and follow the instructions. "
echo ""
echo "Your database's data"
echo "Database: ${database}"
echo "User: " ${db_user}
echo "User's Password: ${db_user_pass}"

