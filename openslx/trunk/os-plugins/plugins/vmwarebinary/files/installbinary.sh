#!/bin/sh

echo "This script will download and install vmplayer from http://www.vmware.com/"
echo "Please go to http://vmware.com/download/player/player_reg.html"
echo "and ..."
echo "	* complete this registration form"
echo "	* click on \"Download Now\""
echo "	* read and decide if you want to accept the VMware master end user license agreement"
echo
echo "If you have done this and accepted the enduser licence type in yes in uppercase."
echo "This will install vmplayer on your vendor-os. If you don't agree this license"
echo "vmplayer won't be installed."
echo
read
echo 

if [ ${REPLY} == "YES" ]; then
	cd /opt/openslx/plugin-repo/vmwarebinary

	echo "	* Downloading vmplayer now. This may take a while"
	cd /opt/openslx/plugin-repo/vmwarebinary/
	#todo, during development we have this file and dont need to download it
	wget -c http://download3.vmware.com/software/vmplayer/VMware-player-2.0.2-59824.i386.tar.gz

	echo "	* Unpacking vmplayer"
	tar xfz VMware-player-2.0.2-59824.i386.tar.gz

	echo "	* copying files..."
	mkdir root
	mkdir -p root/lib
	mv vmware-player-distrib/lib root/lib/vmware
	mv vmware-player-distrib/bin root/
	mv vmware-player-distrib/sbin root/
	mv vmware-player-distrib/doc root/
	mv vmware-player-distrib/installer/services.sh /etc/init.d/vmware

	echo "	* creating /etc/vmware/locations and /etc/vmware/not_configured"
	mkdir -p /etc/vmware
	touch /etc/vmware/not_configured
	mv locations /etc/vmware/

	echo "	* Faking kernelversion"
	mv /bin/uname /bin/uname.orig
	mv /sbin/depmod /sbin/depmod.orig
	mv /sbin/insmod /sbin/insmod.orig
	#for development purpose
	cp uname.sh /bin/uname
	cp depmod.sh /sbin/depmod
	cp insmod.sh /sbin/insmod
	chmod 755 /bin/uname /sbin/depmod /sbin/insmod

	echo "	* Start vmware configuration"
	/opt/openslx/plugin-repo/vmwarebinary/root/bin/vmware-config.pl \
		--default

	echo "	* undo fake environment"
	mv /bin/uname.orig /bin/uname
	mv /sbin/depmod.orig /sbin/depmod
	mv /sbin/insmod.orig /sbin/insmod

	echo "	* finishing installation"
	rm -rf /etc/vmware/not_configured
	
else
	echo "You didnt't accept the end user license. vmplayer is not installed."
fi
