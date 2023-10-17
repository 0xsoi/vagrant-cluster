#!/bin/bash

# PROVISIONING THE VAGRANT MACHINE
vagrant up master
vagrant up slave

# USEER MANAGEMENT
vagrant ssh master -c "sudo useradd -m altschool"
# GIVING USER ROOT PRIVILEGES
vagrant ssh master -c "sudo usermod -aG sudo altschool"

echo "Created user "altschool" with root privileges on the master node"

# INTER NODE COMMUNICATION
generate_ssh_key() {
    vagrant ssh master -c "sudo su - altschool -c 'mkdir -p /home/altschool/.ssh && ssh-keygen -t ed25519 -N \"0000\" -f /home/altschool/.ssh/id_ed25519'"
    vagrant ssh slave -c "sudo mkdir -p /home/altschool/.ssh"
    vagrant ssh slave -c "sudo bash -c 'echo \"$(vagrant ssh master -c 'cat /home/altschool/.ssh/id_ed25519.pub')\" >> /home/altschool/.ssh/authorized_keys'"
}

generate_ssh_key

echo "Copied ssh keys successfully"

# DATA MANAGEMENT AND TRANSFER
vagrant ssh master -c "[ ! -d /mnt/altschool ] && sudo mkdir -p /mnt/altschool"
vagrant ssh master -c "sudo chown altschool:altschool /mnt/altschool && sudo chmod u+r /mnt/altschool"
vagrant ssh master -c "sudo apt-get install rsync sshpass -y"
vagrant ssh master -c "sudo rsync -avz --rsync-path='mkdir -p /mnt/altschool/slave && rsync' /mnt/altschool/ altschool@192.168.56.3:/mnt/altschool/slave"

echo "Copied files successfully"

# PROCESS MONITORING
vagrant ssh master -c "top"

# DEPLOYING THE LAMP STACK 
vagrant ssh master -c "sudo apt-get update && sudo apt-get install -y apache2 mysql-server php libapache2-mod-php php-mysql"
vagrant ssh slave -c "sudo apt-get update && sudo apt-get install -y apache2 mysql-server php libapache2-mod-php php-mysql"

echo "Successfully insalled the LAMP stack on both nodes"

# CONFIGURING APACHE TO START ON BOOT
vagrant ssh master -c "sudo systemctl start apache2"
vagrant ssh slave -c "sudo systemctl start apache2"

 #CONFIGURING MYSQL
vagrant ssh master -c "sudo service mysql start"
vagrant ssh master -c "sudo mysql_secure_installation <<EOF
y
1234
1234
y
y
y
y
EOF
"
vagrant ssh slave -c "sudo service mysql start"
vagrant ssh slave -c "sudo mysql_secure_installation <<EOF
y
1234
1234
y
y
y
y
EOF
"

# VALIDATING PHP
vagrant ssh master -c "sudo a2enmod php7.4"
vagrant ssh master -c "sudo service apache2 restart"
vagrant ssh master -c 'echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/index.php'
vagrant ssh master -c "echo http://192.168.56.2/index.php"
vagrant ssh slave -c "sudo a2enmod php7.4"
vagrant ssh slave -c "sudo service apache2 restart"
vagrant ssh slave -c 'echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/index.php'
vagrant ssh slave -c "echo http://192.168.56.3/index.php"