#! /bin/sh
#
# stage3 part of 'displaymanager' plugin - the runlevel script
#
. /etc/functions
. /etc/distro-functions
. /etc/sysconfig/config
if [ -e /initramfs/plugin-conf/displaymanager.conf ]; then
	. /initramfs/plugin-conf/displaymanager.conf
	if [ $displaymanager_active -ne 0 ]; then
		[ $DEBUGLEVEL -gt 0 ] && echo "executing the 'displaymanager' os-plugin ...";
	
		testmkd /mnt/var/lib/openslx/themes
                testmkd /mnt/var/lib/openslx/config

                if [ -d /usr/share/config/gdm ]; then
                        cp /usr/share/config/gdm.conf /mnt/etc/gdm/gdm.conf
                        cp -a /usr/share/themes/displaymanager/gdm /mnt/var/lib/openslx/themes
                        sed -i "s,^\(GraphicalThemeDir=.*\)$,#\1 \nGraphicalThemeDir=/var/lib/openslx/themes," \
                                /mnt/etc/gdm/gdm.conf
                        sed -i "s,^\(GraphicalTheme=.*\)$,#\1 \nGraphicalTheme=gdm," /mnt/etc/gdm/gdm.conf
                fi

                if [ -d /usr/share/config/gdm ]; then
                        cp /usr/share/config/kdmrc /mnt/${D_KDMRCPATH}
                        cp -a /usr/share/themes/displaymanager/kdm /mnt/var/lib/openslx/themes
                        sed -i "s,UseTheme=.*,UseTheme=true," /mnt/${D_KDMRCPATH}/kdmrc
                fi

		[ $DEBUGLEVEL -gt 0 ] && echo "done with 'displaymanager' os-plugin ...";

        fi
fi
