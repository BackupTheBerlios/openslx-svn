#! /bin/sh
#
# stage3 part of 'theme' plugin - the runlevel script
#
. /etc/functions
. /etc/distro-functions
. /etc/sysconfig/config
if [ -e /initramfs/plugin-conf/theme.conf ]; then
	. /initramfs/plugin-conf/theme.conf
	if [ $theme_active -ne 0 ]; then
		[ $DEBUGLEVEL -gt 0 ] && echo "executing the 'theme' os-plugin ...";
	
		testmkd /mnt/var/lib/openslx/themes/displaymanager
		testmkd /mnt/var/lib/openslx/bin
                if [ -d /usr/share/themes/displaymanager ]; then
                        cp -a /usr/share/themes/displaymanager \
                          /mnt/var/lib/openslx/themes
                        if [ -f /mnt/${D_KDMRCPATH}/kdmrc ]; then
                          sed -i "s,UseTheme=false,UseTheme=true," /mnt/${D_KDMRCPATH}/kdmrc
			fi
                        if [ -f /mnt/etc/gdm/gdm.conf ]; then
			  sed -i "s,^\(GraphicalThemeDir=.*\)$,#\1 \nGraphicalThemeDir=/var/lib/openslx/themes/displaymanager," /mnt/etc/gdm/gdm.conf
			  sed -i "s,^\(GraphicalTheme=.*\)$,#\1 \nGraphicalTheme=gdm," /mnt/etc/gdm/gdm.conf
			fi
                fi

		[ $DEBUGLEVEL -gt 0 ] && echo "done with 'theme' os-plugin ...";
        fi
fi
