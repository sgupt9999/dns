#!/bin/bash
##############################################################
## Configuring a DNS caching client on Centos 7
## Making the DNS Server change persistent in /etc/resolv.conf
##############################################################

##############################################################
## User Inputs
SERVERIP=172.31.26.113
###############################################################

if [[ $EUID != "0" ]]
then
	echo "ERROR. Need to run the script as root"
	exit 1
fi

PACKAGES="bind-utils"

echo "Installing packages......................"
yum install -y -q -e0 $PACKAGES
echo "Done"

# Temporarily change the DNS servers in the /etc/resolv.conf file
if [ -f /etc/resolv.conf_backup ]
then
	cp -f /etc/resolv.conf_backup /etc/resolv.conf
else
	cp -f /etc/resolv.conf /etc/resolv.conf_backup
fi
sed -i "s/nameserver/#nameserver/g" /etc/resolv.conf
echo "nameserver $SERVERIP" >> /etc/resolv.conf

# Making the DNS server change persistent
# This will update the name-server in /etc/resolv.conf persistently
echo "supersede domain-name-servers $SERVERIP;" > /etc/dhcp/dhclient.conf

# Testing with Google name server
echo "##### Resolving yahoo.com using the Google DNS name server - 1st attempt #####"
dig @8.8.4.4 A +noall +stats www.yahoo.com
sleep 2
echo "##### Resolving yahoo.com using the Google DNS name server - 2nd attempt #####"
dig @8.8.4.4 A +noall +stats www.yahoo.com
sleep 2
echo "##### Resolving yahoo.com using the Google DNS name server - 3rd attempt #####"
dig @8.8.4.4 A +noall +stats www.yahoo.com
sleep 2

# Testing with caching name server	
echo "##### Resolving yahoo.com using the cache name server - 1st attempt #####"
dig A +noall +stats www.yahoo.com
sleep 2
echo "##### Resolving yahoo.com using the cache name server - 2nd attempt #####"
dig A +noall +stats www.yahoo.com
sleep 2
echo "##### Resolving yahoo.com using the cache name server - 3rd attempt #####"
dig A +noall +stats www.yahoo.com
