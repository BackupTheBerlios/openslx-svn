
CONFFILE="/initramfs/plugin-conf/vmchooser.conf"

if [ -e $CONFFILE ]; then
	. $CONFFILE
	if [ $vmchooser_active -ne 0 ]; then
		[ $DEBUGLEVEL -gt 0 ] && echo "executing the 'example' os-plugin ...";

		# for this example plugin, we simply take a filename from the 
		# configuration and cat that file (output the smiley):
		cat /mnt/opt/openslx/plugin-repo/example/$preferred_side

		[ $DEBUGLEVEL -gt 0 ] && echo "done with 'example' os-plugin ...";
	fi
fi