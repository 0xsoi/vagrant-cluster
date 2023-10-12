#!/bin/bash

# PROVISIONING THE VAGRANT MACHINE
vagrant up

# CREATING USER ON MASTER NODE
vagrant ssh master -c "sudo useradd -m altschool"
# GIVING USER ROOT PRIVILEGES
vagrant ssh master -c "sudo usermod -aG sudo altschool"

echo "Created user "altschool" with root privileges on the master node"

# Creating passwordless access from master node to slave node
vagrant ssh master -c "ssh-keygen -t ed25519 -N '' /home/altschool/.ssh/id_ed25519"

vagrant ssh slave -c "sudo mkdir -p /home/altschool/.ssh"

vagrant ssh slave -c "sudo bash -c 'echo \"`vagrant ssh master -c 'cat /home/altschool/.ssh/id_ed25519.pub'`"

echo "Copied ssh keys successfully"

# COPYING FILES FROM MASTER TO SLAVE
vagrant ssh master -c "sudo cp -R /mnt/altschool /mnt/altschool/slave"

echo "Copied files successfully"

# DEPLOYING THE LAMP STACK 
vagrant ssh master -c "sudo apt-get update && sudo apt-get install -y apache2 mysql-server php libapache2-mod-php php-mysql"
vagrant ssh slave -c "sudo apt-get update && sudo apt-get install -y apache2 mysql-server php libapache2-mod-php php-mysql"

echo "Successfully insalled the LAMP stack on both nodes"

# CONFIGURING APACHE TO START ON BOOT
vagrant ssh master -c "sudo systemctl start apache2"
vagrant ssh slave -c "sudo systemctl start apache2"

# SECURING MY SQL INSTALLATION
vagrant ssh master -c "sudo mysql_secure_installation"

# VALIDATING PHP
vagrant ssh master -c "echo "<?phpinfo(): ?>" | sudo tee /var/www/index/info.php"