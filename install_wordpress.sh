#!/bin/bash

# Variables
wordpress_db="your_database_name"
db_user="your_database_user"
db_password="your_database_password"
virtualhost_name="your_domain_name"
install_directory="/var/www/html/$virtualhost_name"

# Update the package list
sudo apt -y install software-properties-common
sudo add-apt-repository ppa:ondrej/php
sudo apt update

# Set hostname
sudo hostnamectl set-hostname $virtualhost_name

# Set Timezone
sudo timedatectl set-timezone Asia/Dhaka

# Install required packages
sudo apt install -y fail2ban apache2 mariadb-server php8.2 libapache2-mod-php8.2 php8.2-gd php8.2-mysql php8.2-curl php8.2-mbstring php8.2-intl php8.2-gmp php8.2-bcmath php8.2-imagick php8.2-xml php8.2-zip redis-server php8.2-redis certbot python3-certbot-apache

# Configure ufw
sudo ufw allow ssh
sudo ufw allow in "Apache Full"
sudo ufw enable

# Start and enable Apache web server
sudo systemctl start apache2
sudo systemctl enable apache2

# Start and enable MySQL service
sudo systemctl start mysql
sudo systemctl enable mysql

# Create root directory for wordpress
sudo mkdir /var/www/html/$virtualhost_name
sudo chown -R www-data:www-data /var/www/html/$virtualhost_name

# Create a MySQL database and user for WordPress
sudo mariadb -e "CREATE DATABASE $wordpress_db;"
sudo mariadb -e "CREATE USER '$db_user'@'localhost' IDENTIFIED BY '$db_password';"
sudo mariadb -e "GRANT ALL PRIVILEGES ON $wordpress_db.* TO '$db_user'@'localhost';"
sudo mariadb -e "FLUSH PRIVILEGES;"

# Download and extract WordPress
sudo apt install -y wget
cd /tmp
wget https://wordpress.org/latest.tar.gz
tar -zxvf latest.tar.gz
sudo cp -R wordpress/* "$install_directory"

# Set permissions
sudo chown -R www-data:www-data "$install_directory"
sudo chmod -R 755 "$install_directory"

# Configure WordPress
sudo mv "$install_directory/wp-config-sample.php" "$install_directory/wp-config.php"
sudo sed -i 's/database_name_here/'$wordpress_db'/g' "$install_directory/wp-config.php"
sudo sed -i 's/username_here/'$db_user'/g' "$install_directory/wp-config.php"
sudo sed -i 's/password_here/'$db_password'/g' "$install_directory/wp-config.php"

# Create Apache VirtualHost
echo "
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    ServerName $virtualhost_name
    DocumentRoot $install_directory
    <Directory $install_directory>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/$virtualhost_name.error.log
    CustomLog \${APACHE_LOG_DIR}/$virtualhost_name.access.log combined
</VirtualHost>
" | sudo tee "/etc/apache2/sites-available/$virtualhost_name.conf" > /dev/null

# Enable the VirtualHost
sudo a2ensite "$virtualhost_name.conf"

# Enable necessary modules in apache
sudo a2enmod rewrite

# Restart apache2
sudo systemctl restart apache2

# Obtain ssl from let's encrypt
sudo certbot certonly --apache -d $virtualhost_name

# Configure virtualhost to use ssl

sudo tee "/etc/apache2/sites-available/$virtualhost_name.conf" > /dev/null <<EOF
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    ServerName $virtualhost_name
    DocumentRoot $install_directory
    <Directory $install_directory>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/$virtualhost_name.error.log
    CustomLog \${APACHE_LOG_DIR}/$virtualhost_name.access.log combined

    # Redirect HTTP to HTTPS
    RewriteEngine on
    RewriteCond %{SERVER_NAME} =$virtualhost_name
    RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,QSA,NE]
</VirtualHost>

<VirtualHost *:443>
    ServerAdmin webmaster@localhost
    ServerName $virtualhost_name
    DocumentRoot $install_directory
    <Directory $install_directory>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/$virtualhost_name.error.log
    CustomLog \${APACHE_LOG_DIR}/$virtualhost_name.access.log combined

    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/$virtualhost_name/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/$virtualhost_name/privkey.pem
    Include /etc/letsencrypt/options-ssl-apache.conf

    #SSLOptions +FakeBasicAuth +ExportCertData +StrictRequire
    <FilesMatch "\.(cgi|shtml|phtml|php)$">
          SSLOptions +StdEnvVars
    </FilesMatch>
    <Directory /usr/lib/cgi-bin>
          SSLOptions +StdEnvVars
    </Directory>
</VirtualHost>
EOF

# Enabla ssl module in apache2
sudo a2enmod ssl

# Restart Apache to apply changes
sudo systemctl restart apache2

echo "You need to configure fail2ban manually. WordPress installation is complete. Open your browser and navigate to http://$virtualhost_name/ to complete the setup."
