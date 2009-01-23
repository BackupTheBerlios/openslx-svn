
CONFFILE="/initramfs/plugin-conf/vmchooser.conf"

if [ -e $CONFFILE ]; then
	. $CONFFILE
	if [ $vmchooser_active -ne 0 ]; then
		[ $DEBUGLEVEL -gt 0 ] && echo "executing the 'vmchooser' os-plugin ...";
		[ $DEBUGLEVEL -gt 0 ] && echo "copying default .desktop file ...";
		cp /mnt/opt/openslx/plugin-repo/vmchooser/default.desktop /mnt/etc/X11/sessions/
		[ $DEBUGLEVEL -gt 0 ] && echo "done with 'vmchooser' os-plugin ...";
	fi
fi
