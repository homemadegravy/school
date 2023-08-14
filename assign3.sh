#!/bin/bash

target_one=("target1-mgmt") 
	#changing hostname
ssh remoteadmin@"$target_one" sudo hostnamectl set-hostname loghost

	#changing ip
ssh remoteadmin@"$target_one" sudo ip addr add 172.16.1.3 dev eth0

	# Add entry to /etc/hosts for webhost
ssh remoteadmin@"$target_one" echo "172.16.1.4 webhost" | sudo tee -a /etc/hosts
        
        # Install ufw if not installed
ssh remoteadmin@"$target_one" sudo apt-get update
ssh remoteadmin@"$target_one" sudo apt-get install ufw -y
        
        # Allow connections to port 514/udp from the mgmt network
ssh remoteadmin@"$target_one" sudo ufw allow from 172.16.1.0/24 to any port 514/udp
        
        # Configure rsyslog to listen for UDP connections
ssh remoteadmin@"$target_one" sudo sed -i 's/#module(load="imudp")/module(load="imudp")/' /etc/rsyslog.conf
ssh remoteadmin@"$target_one" sudo sed -i 's/#input(type="imudp" port="514")/input(type="imudp" port="514")/' /etc/rsyslog.conf
ssh remoteadmin@"$target_one" sudo systemctl restart rsyslog


target_two=("target2-mgmt")

# changing hostname
ssh remoteadmin@"$target_two" sudo hostnamectl set-hostname webhost
#changing ip
ssh remoteadmin@"$target_two" sudo ip addr add 172.16.1.4 dev eth0
# Add entry to /etc/hosts for loghost
ssh remoteadmin@"$target_two" echo "172.16.1.3 webhost" | sudo tee -a /etc/hosts
#ufw install
ssh remoteadmin@"$target_two" sudo apt-get update
ssh remoteadmin@"$target_two" sudo apt-get install ufw -y
ssh remoteadmin@"$target_two" sudo ufw enable
ssh remoteadmin@"$target_two" sudo ufw allow 80/tcp
ssh remoteadmin@"$target_two" sudo ufw reload	
#install apache2
ssh remoteadmin@"$target_two" sudo apt-get update
ssh remoteadmin@"$target_two" sudo apt-get install apache2 -y
#sending logs
ssh remoteadmin@"$target_two" log_ip="172.16.1.3"
ssh remoteadmin@"$target_two" sudo sh -c "echo '*.* @$loghost_ip' >> /etc/rsyslog.conf"
ssh remoteadmin@"$target_two" sudo systemctl restart rsyslog
		
echo script complete
