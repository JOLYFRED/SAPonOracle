#!/bin/bash

function getdevicepath()
{
	echo "getdevicepath"
	getdevicepathresult=""
	local lun=$1
	local scsiOutput=$(lsscsi)
	if [[ $scsiOutput =~ \[5:0:0:$lun\][^\[]*(/dev/sd[a-zA-Z]{1,2}) ]];
	then 
		getdevicepathresult=${BASH_REMATCH[1]};
	else
		echo "lsscsi output not as expected for $lun"
		exit -1;
	fi
	echo "getdevicepath done"
}

prepare_and_mount_lun()
{
	echo "prepare_and_mount_lun"
	lun="$1"
	mountPoint="$2"
	getdevicepath $lun
	devicePath=$getdevicepathresult;

	fdisk -l $devicePath || break
	fdisk $devicePath << EOF
n
p
1


t
83
w
EOF
	mkfs -t xfs ${devicePath}1
	mkdir -p ${mountPoint}
	uuid=$(blkid ${devicePath}1 | cut -d' ' -f2)
	echo "${uuid} ${mountPoint} xfs defaults 0 0" >> /etc/fstab
	mount ${devicePath}1 ${mountPoint}
	echo "prepare_and_mount_lun done."
}

change_config()
{
	configFile="$1"
	keyToChange="$2"
	valueToSet="$3"

	sed -c -i "s/\($keyToChange *= *\).*/\1$valueToSet/" $configFile
}

# Before doing anything, update the system
# yum -y update --exclude=WALinuxAgent
# echo "System updated."

# Install lsscsi (needed for identifying devices by lun)
yum -y install lsscsi
echo "lsscsi installed."

# Prepare and mount disks
prepare_and_mount_lun 0 /usr/sap/
prepare_and_mount_lun 1 /work/transfer/
prepare_and_mount_lun 2 /sapmnt/

cat >/etc/sysconfig/network-scripts/ifcfg-eth0:0 <<EOL
DEVICE=eth0:0
BOOTPROTO=static
ONBOOT=yes
IPADDR=10.26.1.40
NETMASK=255.255.255.240
EOL
ifup ifcfg-eth0:0

cat >/etc/sysconfig/network-scripts/ifcfg-eth0:1 <<EOL
DEVICE=eth0:0
BOOTPROTO=static
ONBOOT=yes
IPADDR=10.26.1.41
NETMASK=255.255.255.240
EOL
ifup ifcfg-eth0:1

# Create Swap Space
change_config /etc/waagent.conf ResourceDisk.Format y
change_config /etc/waagent.conf ResourceDisk.EnableSwap y
change_config /etc/waagent.conf ResourceDisk.SwapSizeMB 40960
# CAUTION: waagent should not be restarted here because this causes the whole
# custom script execution to fail. And VM needs to be restarted at the end anyway.
# systemctl restart waagent.service
# swapon -s

# Install Packages
yum -y groupinstall "Infrastructure Server"
yum -y groupinstall "Large Systems Performance"
yum -y groupinstall "Network File System Client"
yum -y groupinstall "Performance Tools"
yum -y groupinstall "Compatibility Libraries"
 
yum -y groupinstall "directory-client"
 
yum -y install libstdc++-devel
yum -y install gcc
yum -y install gcc-c++
yum -y install ksh
yum -y install libaio-devel

# Install X-Server
yum -y groupinstall "X Window System"
yum -y groupinstall "Fonts"
 
yum -y install xorg-x11-apps.x86_64

# Install lftp
yum -y install lftp
 
# Install Unrar 
wget http://www.rarlab.com/rar/unrar-5.0-RHEL5x64.tar.gz
tar -zxvf unrar-5.0-RHEL5x64.tar.gz
cp unrar /usr/bin/
chmod 755 /usr/bin/unrar

# Setup NFS Server
service rpcbind start
service nfs start
service nfslock start
chkconfig rpcbind on
chkconfig nfs on
chkconfig nfslock on
systemctl start nfs-server
systemctl enable nfs-server
