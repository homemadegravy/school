#!/bin/bash

# Change host name
host=$(hostname)

if [ "$host" != 'autosrv' ]; then
    sudo hostname autosrv
    echo "Your hostname is now autosrv"
else
    echo "Your hostname is already autosrv"
fi

#change network configuration
main_interface=$(ip route | grep default | awk '{print $5}')
manage_interfaces=$(find /sys/class/net -type l -printf "%f\n" | grep -v -e "lo" -e "$main_interface")
#checking to make sure the enviroment is as expected
total_interfaces=$(echo "$manage_interfaces"| wc -l)
if [ "$total_interfaces" != '1' ]; then
 echo "the enviroment is not configured properly, expecting only 1 additional interface"
 exit 1
fi

sudo cat > /etc/netplan/01-"$manage_interfaces".yaml << E0F
network:
  version: 2
  renderer: networkd
  ethernets:
    $manage_interfaces:
      addresses:
        - 192.168.16.21/24
      gateway4: 192.168.16.1
      nameservers:
        addresses: [192.168.16.1]
        search: [home.arpa, localdomain]
E0F

#install and config ssh
sudo apt-get update
sudo apt-get install openssh-server -y

sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart ssh

#install and config apache2
sudo apt-get install apache2 -y
sudo sed -i 's/Listen 80/Listen 80\nListen 443/' /etc/apache2/ports.conf
sudo systemctl restart apache2

#install and config squid
sudo apt-get install squid -y
sudo sed -i 's/http_port 3128/http_port 3128/' /etc/squid/squid.conf
sudo systemctl restart squid

#install and config UFW
sudo apt-get update
sudo apt-get install ufw -y

sudo ufw enable

sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 3128/tcp
sudo ufw reload

#setting up user profiles
users=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")
ssh_keys=("ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm")

for user in "${users[@]}"; do
 sudo useradd -m -s /bin/bash "$user"
 sudo -u "$user" ssh-keygen -t rsa -f "/home/$user/.ssh/id_rsa" -q -N ""
 sudo -u "$user" ssh-keygen -t ed25519 -f "/home/$user/.ssh/id_ed25519" -q -N ""
 sudo -u "$user" echo "${ssh_keys[@]}" | sudo tee -a file
 "/home/$user/.ssh/authorized_keys"
 if [ "$user" == "dennis" ]; then
  echo "$user ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers
 fi
done
