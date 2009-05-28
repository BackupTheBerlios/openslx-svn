# Copyright (c) 2009 - OpenSLX GmbH
#
# This program/file is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your feedback to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org
#
# script is included from init via the "." load function - thus it has all
# variables and functions available

# check if the plugin config directory is generally available or if the client
# configuration failed somehow
[ -d /initramfs/plugin-conf ] || error "${init_picfg}" nonfatal

# main script
if [ -e /initramfs/plugin-conf/kiosk.conf ]; then
	. /initramfs/plugin-conf/kiosk.conf

  	if [ $dropbear_active -ne 0 ]; then
    	[ $DEBUGLEVEL -gt 0 ] && echo "executing the 'kiosk' os-plugin ...";
		
		# create new user
		chroot /mnt useradd -s /bin/bash -m kiosk
		cp /mnt/opt/openslx/plugin-repo/kiosk/bashrc /mnt/home/kiosk/.bashrc
		
		# setup custom rungetty
		mkdir -p /mnt/root/bin
		ln -sf /mnt/opt/openslx/plugin-repo/kiosk/rungetty /mnt/root/bin/mygetty
        
        sed -i /mnt/etc/event.d/tty1 \
            -e 's#exec.*#exec /root/bin/mygetty --autologin kiosk tty1#'
		
    	[ $DEBUGLEVEL -gt 0 ] && echo "done with 'kiosk' os-plugin ...";

  	fi
	
fi