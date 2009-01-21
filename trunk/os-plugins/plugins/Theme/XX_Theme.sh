#! /bin/sh
#
# stage3 part of 'Theme' plugin - the runlevel script
#
. /etc/functions
. /etc/sysconfig/config
if [ -e /initramfs/plugin-conf/Theme.conf ]; then
	. /initramfs/plugin-conf/Theme.conf
	if [ $Theme_active -ne 0 ]; then
		[ $DEBUGLEVEL -gt 0 ] && echo "executing the 'Theme' os-plugin ...";
	
		testmkd /mnt/var/lib/openslx/themes/displaymanager
		testmkd /mnt/var/lib/openslx/bin
                if [ -d /usr/share/themes/displaymanager ]; then
                        cp -a /usr/share/themes/displaymanager \
                          /mnt/var/lib/openslx/themes
                        sed -i "s,UseTheme=false,UseTheme=true," /mnt/${D_KDMRCPATH}/kdmrc
                fi

		[ $DEBUGLEVEL -gt 0 ] && echo "done with 'Theme' os-plugin ...";
	fi
fi
