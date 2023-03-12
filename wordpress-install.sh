#!/bin/bash
#

# Check OS version
if ! grep -qiE "fedora|centos" /etc/*release; then
    echo "Unsupported OS. This script only supports Fedora and CentOS."
    exit 1
fi

# Check if script is being run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run this script as root."
    exit 1
fi

# Install required packages
echo "Installing required packages..."
echo "Please wait a sec..."
if ! $pkg_mgr install -y php-mysqlnd php-fpm mariadb-server httpd tar curl php-json > /dev/null; then
  echo "Failed to install required packages."
  exit 1
fi

# Allow http and https traffic
echo "Opening HTTP and optionally HTTPS port 80 and 443 on your firewall..."
if ! firewall-cmd --permanent --zone=public --add-service=http && \
  firewall-cmd --permanent --zone=public --add-service=https && \
  firewall-cmd --reload; then
  echo "Failed to open ports on the firewall."
  exit 1
fi

# Start and enable services
systemctl start mariadb
systemctl start httpd
systemctl enable mariadb
systemctl enable httpd
clear

# Set a root password
echo "Enter a new password for a root account in MySQL"
read -s root_pass

# Set root password
if ! mysqladmin -u root password "${root_pass}"; then
  echo "Failed to set root password."
  exit 1
fi

# Secure the installation
if ! sudo mysql -u root -p"${root_pass}" <<EOF
UPDATE mysql.user SET Password=PASSWORD('${root_pass}') WHERE User='root';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';
FLUSH PRIVILEGES;
EOF
then
  echo "Failed to secure the installation."
  exit 1
fi
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

# Create database and user
mysql -u root -proot <<EOF
CREATE DATABASE ${database};
CREATE USER '${db_user}'@'localhost' IDENTIFIED BY '${db_user_pass}';
GRANT ALL PRIVILEGES ON wordpress.* TO '${db_user}'@'localhost';
FLUSH PRIVILEGES;
EOF
 
# Download and extract WordPress
read -p "Enter the directory to install WordPress in (default /var/www/html): " wp_dir
wp_dir=${wp_dir:-/var/www/html}
if ! curl https://wordpress.org/latest.tar.gz --output wordpress.tar.gz; then
  echo "Failed to download WordPress."
  exit 1
fi
if ! tar xf wordpress.tar.gz; then
  echo "Failed to extract WordPress."
  exit 1
fi
if ! cp -r wordpress "$wp_dir"; then
  echo "Failed to copy WordPress to $wp_dir."
  exit 1
fi

# Set permissions and security context
if ! chown -R apache:apache "$wp_dir"; then
  echo "Failed to change ownership to apache:apache."
  exit 1
fi
if ! chcon -t httpd_sys_rw_content_t "$wp_dir" -R; then
  echo "Failed to change security context to httpd_sys_rw_content_t."
  exit 1
fi

# Log events and errors
LOG_FILE="/var/log/wp-install.log"
exec > >(tee -i "$LOG_FILE")
exec 2>&1

# The end of the install
echo "WordPress has been successfully installed!"
echo "Access WordPress installation wizard and perform the actual WordPress installation."
echo "Navigate your browser to http://localhost/wordpress and follow the instructions. "
echo ""
echo "Your database's data"
echo "Database: $database"
echo "User: $db_user"
echo "User's Password: $db_user_pass"