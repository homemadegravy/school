#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root."
  exit 1
fi
echo "the script is now running please wait..."
# Change host name
host=$(hostname)

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
echo 'networking section complete'
#install and config ssh
sudo apt-get update > /dev/null
sudo apt-get install openssh-server -y > /dev/null || echo "openssh-server failed to install" | exit 1
echo ssh server installed
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config > /dev/null
sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config > /dev/null
sudo systemctl restart ssh > /dev/null

#install and config apache2
sudo apt-get install apache2 -y > /dev/null || echo "apache2 failed to install" | exit 1
sudo sed -i 's/Listen 80/Listen 80\nListen 443/' /etc/apache2/ports.conf > /dev/null
sudo systemctl restart apache2 > /dev/null
echo apache 2 installed
#install and config squid
sudo apt-get install squid -y > /dev/null || echo "squid failed to install" | exit 1
sudo sed -i 's/http_port 3128/http_port 3128/' /etc/squid/squid.conf > /dev/null
sudo systemctl restart squid > /dev/null
echo squid installed
#install and config UFW
sudo apt-get update > /dev/null
sudo apt-get install ufw -y > /dev/null || echo "ufw failed to install" | exit 1
echo ufw installed
sudo ufw enable > /dev/null

sudo ufw allow 22/tcp > /dev/null
sudo ufw allow 80/tcp > /dev/null
sudo ufw allow 443/tcp > /dev/null
sudo ufw allow 3128/tcp > /dev/null
sudo ufw reload > /dev/null

#setting up user profiles
users=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")
ssh_keys=("ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm")

for user in "${users[@]}"; do
 sudo useradd -m -s /bin/bash "$user"
 sudo -u "$user" ssh-keygen -t rsa -f "/home/$user/.ssh/id_rsa" -q -N ""
 sudo -u "$user" ssh-keygen -t ed25519 -f "/home/$user/.ssh/id_ed25519" -q -N ""
 if [ ! -e /home/$user/.ssh/authorized_keys ]; then
	sudo -u "$user" touch "/home/$user/.ssh/authorized_keys"
fi
 sudo -u "$user" echo "${ssh_keys[@]}" | sudo tee -a "/home/$user/.ssh/authorized_keys"
 if [ "$user" == "dennis" ]; then
  echo "$user ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers
 fi
done

echo "wow it worked"
