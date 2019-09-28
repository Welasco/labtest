#!/bin/bash
#############################
# Script Definition
#############################
logpath=/var/log/deploymentscriptlog


#############################
# Upgrading Linux Distribution
#############################
echo "#############################" >> $logpath
echo "Upgrading Linux Distribution" >> $logpath
echo "#############################" >> $logpath
sudo apt-get update >> $logpath
sudo apt-get -y upgrade >> $logpath
echo " " >> $logpath


#############################
# Installing .Net Core
#############################
echo "#############################" >> $logpath
echo "Installing .Net Core" >> $logpath
echo "#############################" >> $logpath
wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb >> $logpath
sudo dpkg -i packages-microsoft-prod.deb >> $logpath
sudo add-apt-repository universe >> $logpath
sudo apt-get update >> $logpath
sudo apt-get install -y apt-transport-https  >> $logpath
sudo apt-get install -y dotnet-sdk-3.0 >> $logpath
echo " " >> $logpath


#############################
# Installing NodeJS
#############################
echo "#############################" >> $logpath
echo "Installing NodeJS" >> $logpath
echo "#############################" >> $logpath
curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash - >> $logpath
sudo apt-get install -y nodejs >> $logpath


#############################
# Python is already installed
#############################
echo "#############################" >> $logpath
echo "Installing Python" >> $logpath
echo "#############################" >> $logpath
sudo apt-get install -y python-pip >> $logpath
sudo apt-get install -y python3-pip >> $logpath
echo " " >> $logpath


#############################
# Installing Apache and PHP
#############################
# Installing Apache
echo "#############################" >> $logpath
echo "Installing Apache" >> $logpath
echo "#############################" >> $logpath
sudo apt-get install -y apache2 >> $logpath

# Installing PHP
echo "Installing PHP" >> $logpath
sudo apt-get install -y php >> $logpath
sudo systemctl restart apache2.service >> $logpath
printf '%s\n' '' \
    '<?php' \
    '   phpinfo();' \
    '?>' \
    '' \
    '' > /var/www/html/phpinfo.php
echo " " >> $logpath


#############################
# Installing Java
#############################
echo "#############################" >> $logpath
echo "Installing Java" >> $logpath
echo "#############################" >> $logpath
sudo apt install -y default-jdk >> $logpath
echo " " >> $logpath


#############################
#Install Docker
#############################
echo "#############################" >> $logpath
echo "Installing Docker" >> $logpath
echo "#############################" >> $logpath
wget -qO- https://get.docker.com/ | sh >> $logpath
sudo usermod -aG docker $1
echo " " >> $logpath


#############################
# Preparing DNS Host file
#############################
echo "#############################" >> $logpath
echo "Preparing DNS" >> $logpath
echo "#############################" >> $logpath
sudo bash -c "echo 127.0.0.1 contoso.com >> /etc/hosts"
sudo bash -c "echo 127.0.0.1 www.contoso.com >> /etc/hosts"
cat /etc/hosts >> $logpath
echo " " >> $logpath


#############################
# Preparing Code
#############################
echo "#############################" >> $logpath
echo "Preparing Code" >> $logpath
echo "#############################" >> $logpath
sudo apt-get install -y unzip >> $logpath
wget https://github.com/Welasco/labtest/raw/master/oss-labs.zip  >> $logpath
unzip oss-labs.zip -d /opt  >> $logpath
mv /opt/oss-labs /opt/apps

# Preparing NodeJS Code
echo "Preparing NodeJS App (npm install)" >> $logpath
cd /opt/apps/NodeJSApp
npm install  >> $logpath
chmod +x /opt/apps/NodeJSApp/bin/www
echo " " >> $logpath

# Preparing Python Code
echo "Preparing Python App (pip install)" >> $logpath
cd /opt/apps/PythonApp
pip3 install -r requirements.txt  >> $logpath
chmod +x /opt/apps/PythonApp/app.py
echo " " >> $logpath

# Preparing Java
echo "Preparing Java App" >> $logpath
cd /opt/apps/JavaApp
chmod +x /opt/apps/JavaApp/mvnw
# build java
# mvnw clean package
echo " " >> $logpath

# Preparing PHP Code
# Setting UP Apache VDir
echo "Preparing PHP Code" >> $logpath
printf '%s\n' '' \
    '<VirtualHost *:8088>' \
    '    DocumentRoot /var/www/contoso.com' \
    '    ErrorLog ${APACHE_LOG_DIR}/error.log' \
    '    CustomLog ${APACHE_LOG_DIR}/access.log combined' \
    '    <Directory /var/www/contoso.com>' \
    '        Options Indexes FollowSymLinks MultiViews' \
    '        AllowOverride All' \
    '        Require all granted' \
    '    </Directory>' \
    '</VirtualHost>' \
    '' \
    '' > /etc/apache2/sites-available/contoso.com.conf
cat /etc/apache2/sites-available/contoso.com.conf >> $logpath
sudo mkdir /var/www/contoso.com
sudo cp /var/www/html/phpinfo.php /var/www/contoso.com/phpinfo.php
sudo bash -c "echo Listen 8088 >> /etc/apache2/ports.conf"
cat /etc/apache2/ports.conf >> $logpath
sudo a2enmod rewrite >> $logpath
sudo a2ensite contoso.com.conf >> $logpath
sudo systemctl reload apache2
sudo cp -rR /opt/apps/PHPApp/. /var/www/contoso.com/
sudo service apache2 restart
echo " " >> $logpath

#############################
# Loading App Services Daemon
#############################
echo "#############################" >> $logpath
echo "Preparing Apps Daemon" >> $logpath
echo "#############################" >> $logpath
cp /opt/apps/PythonApp/pythonapp.service /lib/systemd/system
cp /opt/apps/NodeJSApp/nodejsapp.service /lib/systemd/system
cp /opt/apps/JavaApp/javaapp.service /lib/systemd/system
sudo systemctl daemon-reload
sudo systemctl enable nodejsapp
sudo systemctl enable pythonapp
sudo systemctl enable javaapp
sudo service nodejsapp start
sudo service pythonapp start
sudo service javaapp start
sudo service nodejsapp status  >> $logpath
sudo service pythonapp status >> $logpath
sudo service javaapp status >> $logpath
echo " " >> $logpath


#############################
# Cleaning Resources
#############################
echo "#############################" >> $logpath
echo "Cleaning Resources" >> $logpath
echo "#############################" >> $logpath
rm -rf /opt/apps/VMTemplate
rm -rf /opt/apps/StaticDesign
rm -rf /opt/apps/.gitignore
rm -rf /opt/apps/README.md
rm -rf /opt/apps/.vscode
ls /opt/apps >> $logpath