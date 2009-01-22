#! /bin/sh
#
# stage3 part of 'theme' plugin - the runlevel script
#
. /etc/functions
. /etc/sysconfig/config
if [ -e /initramfs/plugin-conf/theme.conf ]; then
	. /initramfs/plugin-conf/theme.conf
	if [ $Theme_active -ne 0 ]; then
		[ $DEBUGLEVEL -gt 0 ] && echo "executing the 'theme' os-plugin ...";
	
		testmkd /mnt/var/lib/openslx/themes/displaymanager
		testmkd /mnt/var/lib/openslx/bin
                if [ -d /usr/share/themes/displaymanager ]; then
                        cp -a /usr/share/themes/displaymanager \
                          /mnt/var/lib/openslx/themes
                        sed -i "s,UseTheme=false,UseTheme=true," /mnt/${D_KDMRCPATH}/kdmrc
                fi

		[ $DEBUGLEVEL -gt 0 ] && echo "done with 'theme' os-plugin ...";
	fi
fi
