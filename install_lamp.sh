#!/bin/bash

# Cool ASCII art logo for LAMP SERVER
cat << "EOF"
 _        _    __  __ ____    ____  _____ ______     _______ ____  
| |      / \  |  \/  |  _ \  / ___|| ____|  _ \ \   / / ____|  _ \ 
| |     / _ \ | |\/| | |_) | \___ \|  _| | |_) \ \ / /|  _| | |_) |
| |___ / ___ \| |  | |  __/   ___) | |___|  _ < \ V / | |___|  _ < 
|_____/_/   \_\_|  |_|_|     |____/|_____|_| \_\ \_/  |_____|_| \_\

		     LAMP SERVER INSTALLER | Development by : Chamnan Dev (Khmer Developer)




EOF




# Function to log messages
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Function to detect Linux distribution
detect_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
  elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VERSION=$DISTRIB_RELEASE
  elif [ -f /etc/redhat-release ]; then
    OS="rhel"
    VERSION=$(cat /etc/redhat-release | grep -oP '[0-9]+(\.[0-9]+)?')
  else
    log "Cannot detect operating system. Exiting..."
    exit 1
  fi
}

# Function to install LAMP on Debian-based systems
install_debian() {
  log "Detected Debian-based system ($OS). Proceeding with installation..."
  sudo apt update -y && sudo apt upgrade -y
  sudo apt install apache2 mysql-server php php-cli php-cgi libapache2-mod-php php-mysql phpmyadmin -y
  sudo mysql --validate-password=OFF
  sudo systemctl start apache2
  sudo systemctl enable apache2
  sudo systemctl start mysql
  sudo systemctl enable mysql
  sudo mysql_secure_installation
  sudo systemctl restart apache2
  echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php
  log "phpMyAdmin installation complete. Visit http://your_server_ip/phpmyadmin"
    # Disable validate_password plugin
  sudo mysql --user=root <<"EOF"
   	UNINSTALL COMPONENT 'file://component_validate_password';
  	ALTER USER 'root'@'localhost' IDENTIFIED BY '';
  	FLUSH PRIVILEGES;
EOF

  log "MySQL installed with password validation disabled and root password set to empty."
}

# Function to install LAMP on RHEL-based systems
install_rhel() {
  log "Detected RHEL-based system ($OS). Proceeding with installation..."
  sudo yum update -y
  sudo yum install httpd mariadb-server php php php-cli php-cgi php-mysqlnd epel-release -y
  sudo yum install phpmyadmin -y
  sudo systemctl start httpd
  sudo systemctl enable httpd
  sudo systemctl start mariadb
  sudo systemctl enable mariadb
  sudo mysql_secure_installation
  sudo systemctl restart httpd
  echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php
  log "phpMyAdmin installation complete. Visit http://your_server_ip/phpmyadmin"

    # Disable validate_password plugin
  sudo mysql --user=root <<"EOF"
UNINSTALL COMPONENT 'file://component_validate_password';
ALTER USER 'root'@'localhost' IDENTIFIED BY '';
FLUSH PRIVILEGES;
EOF

  log "MySQL installed with password validation disabled and root password set to empty."
}

# Function to install LAMP on Arch Linux
install_arch() {
  log "Detected Arch Linux system ($OS). Proceeding with installation..."
  sudo pacman -Syu --noconfirm
  sudo pacman -S apache mariadb php php php-cli php-cgi php-apache phpmyadmin --noconfirm
  sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
  sudo systemctl start mariadb
  sudo systemctl enable mariadb
  sudo sed -i '/^#LoadModule rewrite_module/s/^#//' /etc/httpd/conf/httpd.conf
  sudo sed -i '/^#LoadModule php_module/s/^#//' /etc/httpd/conf/httpd.conf
  sudo sed -i 's/DirectoryIndex index.html/DirectoryIndex index.php index.html/' /etc/httpd/conf/httpd.conf
  echo "Include /etc/phpmyadmin/apache.conf" | sudo tee -a /etc/httpd/conf/httpd.conf
  echo "<?php phpinfo(); ?>" | sudo tee /srv/http/info.php
  sudo systemctl restart httpd
  sudo systemctl enable httpd
  log "phpMyAdmin installation complete. Visit http://your_server_ip/phpmyadmin"
    # Disable validate_password plugin
  sudo mysql --user=root <<"EOF"
UNINSTALL COMPONENT 'file://component_validate_password';
ALTER USER 'root'@'localhost' IDENTIFIED BY '';
FLUSH PRIVILEGES;
EOF

  log "MySQL installed with password validation disabled and root password set to empty."
}

# Main script
detect_os

case $OS in
  ubuntu | debian)
    install_debian
    ;;
  centos | fedora | rhel)
    install_rhel
    ;;
  arch)
    install_arch
    ;;
  *)
    log "Unsupported operating system: $OS. Exiting..."
    exit 1
    ;;
esac

log "LAMP SERVER installed successfully."
log "Visit http://your_server_ip/info.php to verify PHP installation."
log "Remember to remove 'info.php' after testing for security reasons."

