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

                if [ "${displaymanager_xdmcp}" = "gdm" ]; then
                        cp /usr/share/config/gdm.conf /mnt/etc/gdm/gdm.conf
                        cp -a /usr/share/themes/gdm /mnt/var/lib/openslx/themes
                        sed -i "s,GraphicalThemeDir=.*,GraphicalThemeDir=/var/lib/openslx/themes," \
                                /mnt/etc/gdm/gdm.conf
                        sed -i "s,GraphicalTheme=.*GraphicalTheme=gdm," /mnt/etc/gdm/gdm.conf
                fi

                if [ "${displaymanager_xdmcp}" = "kdm" ]; then
                        cp /usr/share/config/kdmrc /mnt/etc/kde3/kdm/kdmrc
                        cp -a /usr/share/themes/kdm /mnt/var/lib/openslx/themes
                        sed -i "s,Theme=.*,Theme=/var/lib/openslx/themes/kdm," /mnt/etc/kde3/kdm/kdmrc
                        sed -i "s,UseTheme=.*,UseTheme=true," /mnt/etc/kde3/kdm/kdmrc
                fi

		[ $DEBUGLEVEL -gt 0 ] && echo "done with 'displaymanager' os-plugin ...";

        fi
fi
