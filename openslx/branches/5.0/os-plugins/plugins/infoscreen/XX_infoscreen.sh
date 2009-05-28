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
if [ -e /initramfs/plugin-conf/infoscreen.conf ]; then
	. /initramfs/plugin-conf/infoscreen.conf

  	if [ $infoscreen_active -ne 0 ]; then
    	[ $DEBUGLEVEL -gt 0 ] && echo "executing the 'infoscreen' os-plugin ...";
		
		ln -sf /opt/openslx/plugin-repo/infoscreen/kiosk.dpms \
		       /mnt/bin/kiosk.dpms
		
		# prepare xsession
        echo "#!/bin/bash" \
                > /mnt/home/kiosk/.xinitrc
        echo "xhost +local:" \
                >> /mnt/home/kiosk/.xinitrc
        echo "xsetroot -cursor /opt/openslx/plugin-repo/infoscreen/empty.xbm \\" \
                >> /mnt/home/kiosk/.xinitrc
        echo "/opt/openslx/plugin-repo/infoscreen/empty.xbm" \
                >> /mnt/home/kiosk/.xinitrc
        echo "/usr/bin/dpclient" \
                >> /mnt/home/kiosk/.xinitrc

		# remove Standby
		sed -r "s,(Option.*\"(Blank|Standby|Suspend|Off)Time\"[^\"]*)(.*),\1 \"0\" # disabled by infoscreen \3," \
		  -i /mnt/etc/X11/xorg.conf
		sed -r "s,(Option.*\"(blank|standby|suspend|off) time\"[^\"]*)(.*),\1 \"0\" # disabled by infoscreen \3," \
		  -i /mnt/etc/X11/xorg.conf

		# energy safe
		# (requires "xhost +local:")
		sed -r "s,(Section \"Module\"),\1\n  Load  \"dpms\"," -i /mnt/etc/X11/xorg.conf
		echo "0 22   * * *   root    /bin/kiosk.dpms sleep" >> /mnt/etc/crontab
		echo "0 7   * * *   root    /bin/kiosk.dpms wakeup" >> /mnt/etc/crontab


		
    	[ $DEBUGLEVEL -gt 0 ] && echo "done with 'infoscreen' os-plugin ...";

  	fi
	
fi
