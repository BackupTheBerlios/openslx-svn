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
                        sed -i "s,UseTheme=false,UseTheme=true," /mnt/${D_KDMRCPATH}/kdmrc
                        if [ -f /mnt/etc/gdm/gdm.conf ]; then
			  sed -i "s,^\(GraphicalThemeDir=.*\)$,#\1 \nGraphicalThemeDir=/var/lib/openslx/themes/displaymanager," /mnt/etc/gdm/gdm.conf
			  sed -i "s,^\(GraphicalTheme=.*\)$,#\1 \nGraphicalTheme=gdm," /mnt/etc/gdm/gdm.conf
			fi
                fi

		[ $DEBUGLEVEL -gt 0 ] && echo "done with 'theme' os-plugin ...";

                if [ ${theme_nosplash} -eq 0 ]; then
                        # make the splashy_update binary available in stage4 ...
                        mkdir -p /mnt/var/lib/openslx/bin
                        cp -a /bin/splashy_update /mnt/var/lib/openslx/bin

                        # ... and create a runlevelscript that will stop splashy somewhere near
                        # the end of stage4
                        d_mkrlscript init splashy.stop "Stopping Splashy ..."
                        echo -e "\t/var/lib/openslx/bin/splashy_update exit 2>/dev/null \
                                \n\ttype killall >/dev/null 2>&1 && killall -9 splashy \
                                \n\trm -f /var/lib/openslx/bin/splashy_update 2>/dev/null" \
                                >>/mnt/etc/${D_INITDIR}/splashy.stop
                        d_mkrlscript close splashy.stop ""
	        fi
        fi
fi
