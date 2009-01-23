#!/bin/sh

echo "This script will download and install vmplayer from http://www.vmware.com/"
echo "Please go to http://vmware.com/download/player/player_reg.html"
echo "and ..."
echo "   * complete this registration form"
echo "   * click on \"Download Now\""
echo "   * read and decide if you want to accept the VMware master end user license agreement"
echo
echo "If you have done this and accepted the enduser licence type in yes in uppercase."
echo "This will install vmplayer on your vendor-os. If you don't agree this license"
echo "vmplayer won't be installed."
echo
read
echo 

if [ "${REPLY}" == "YES" ]; then

	echo "   * Downloading vmplayer now. This may take a while"
	cd /opt/openslx/plugin-repo/vmware/vmpl2.0
	#TODO: during development we have this file and dont need to download it
	#wget -c http://download3.vmware.com/software/vmplayer/VMware-player-2.0.2-59824.i386.tar.gz

	echo "   * Unpacking vmplayer"
	#tar xfz VMware-player-2.0.2-59824.i386.tar.gz
    #TODO: just for developing purpose
	tar xfz ../../VMware-player-2.0.2-59824.i386.tar.gz

	echo "   * copying files..."
	mkdir root
	mkdir -p root/lib
	mv vmware-player-distrib/lib root/lib/vmware
	mv vmware-player-distrib/bin root/
	mv vmware-player-distrib/sbin root/
	mv vmware-player-distrib/doc root/
    rm -rf vmware-player-distrib/

    # I don't want to understand what vmware is doing, but without this
    # step we need to have LD_LIBRARY_PATH with 53 entrys. welcome to
    # library hell
    echo "   * fixing librarys..."
    cd root/lib/vmware/lib
    mkdir test
    mv lib* test
    mv test/lib*/* .
    cd ../../../..

	echo "   * creating /etc/vmware"
	mkdir -p /etc/vmware

    echo "   * unpacking kernel modules"
    cd root/lib/vmware/modules/source
    tar xf vmnet.tar
    tar xf vmmon.tar
    tar xf vmblock.tar

    echo "   * building vmblock module"
    cd vmblock-only/
    # TODO: check if /boot/vmlinuz is available if we get the kernel version this way
    #       perhaps we don't need a check... perhaps openslx always use
    #       /boot/vmlinuz
    #       This problem happens 3 times. see below!
    # TODO: error check if build environment isn't installed...
    sed -i "s%^VM_UNAME = .*%VM_UNAME = $(ls /boot/vmlinuz*|grep -v -e "^/boot/vmlinuz$$"|sed 's,/boot/vmlinuz-,,'|sort|tail -n 1)%" Makefile
    make -s
    cd ..

    echo "   * building vmmon module"
    cd vmmon-only
    sed -i "s%^VM_UNAME = .*%VM_UNAME = $(ls /boot/vmlinuz*|grep -v -e "^/boot/vmlinuz$$"|sed 's,/boot/vmlinuz-,,'|sort|tail -n 1)%" Makefile
    make -s
    cd ..
    
    echo "   * building vmnet module"
    cd vmnet-only
    sed -i "s%^VM_UNAME = .*%VM_UNAME = $(ls /boot/vmlinuz*|grep -v -e "^/boot/vmlinuz$$"|sed 's,/boot/vmlinuz-,,'|sort|tail -n 1)%" Makefile
    make -s
    cd ..

    # TODO: remove. just for debug reasons
    echo "Press any return to process"
    read

	echo "   * finishing installation"
	
else
	echo "You didnt't accept the end user license. vmplayer is not installed."
fi
