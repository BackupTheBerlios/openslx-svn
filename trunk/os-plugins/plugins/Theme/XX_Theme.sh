#! /bin/sh
#
# stage3 part of 'Theme' plugin - the runlevel script
#
if [ -e /initramfs/plugin-conf/Theme.conf ]; then
	. /initramfs/plugin-conf/Theme.conf
	if [ $Theme_active -ne 0 ]; then
		[ $DEBUGLEVEL -gt 0 ] && echo "executing the 'Theme' os-plugin ...";
	
		testmkd /mnt/var/lib/openslx/themes/displaymanager
		testmkd /mnt/var/lib/openslx/bin
		[ -d /usr/share/themes/displaymanager ] \
			&& cp -a /usr/share/themes/displaymanager \
			         /mnt/var/lib/openslx/themes

		[ $DEBUGLEVEL -gt 0 ] && echo "done with 'Theme' os-plugin ...";
	fi
fi
