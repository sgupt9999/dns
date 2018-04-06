#!/bin/bash
##############################################################
##
## Configuring a DNS caching server using bind on Centos 7
##
##############################################################

##############################################################
##
## User Inputs
TRUSTEDCLIENTS=(172.31.17.32 172.31.17.55) # Need at least one entry
SERVERIP=172.31.26.113/32

# firewalld should already be installed, enabled and running
FIREWALL=yes
#FIREWALL=no

##
###############################################################

if [[ $EUID != "0" ]]
then
	echo "ERROR. Need to run the script as root"
	exit 1
fi

PACKAGES="bind"

if yum list installed bind > /dev/null 2>&1
then
	systemctl -q is-active named && {
	systemctl -q stop named
	systemctl -q disable named
	}
	
	yum remove -y -q -e0 $PACKAGES
	rm -rf /etc/rndc.key
	rm -rf /etc/named*
fi

echo "Installing packages......................"
yum install -y -q -e0 $PACKAGES
echo "Done"

if [ -f /etc/named.conf_backup ]
then
	cp -f /etc/named.conf_backup /etc/named.conf
else
	cp -f /etc/named.conf /etc/named.conf_backup
fi

##################################################################
##
## Create trusted list of client servers

line_number=`grep options -n /etc/named.conf | head -n 1 | cut -d":" -f1`
sed -i "${line_number}i\acl \"trusted\" {" /etc/named.conf
for CLIENT in ${TRUSTEDCLIENTS[@]}
do
	line_number=`expr $line_number + 1`
	sed -i "${line_number}i	$CLIENT;" /etc/named.conf
done
line_number=`expr $line_number + 1`
sed -i "${line_number}i};" /etc/named.conf


sed -i "s#listen-on port 53.*#listen-on port 53 { $SERVERIP; };#" /etc/named.conf
sed -i "s/allow-query.*/allow-query	{ trusted; };/" /etc/named.conf
sed -i "s/recursion no/recursion yes/" /etc/named.conf

if [ $FIREWALL == "yes" ]
then
	firewall-cmd --permanent --add-service dns
	firewall-cmd --reload
fi

systemctl start named
systemctl enable named
