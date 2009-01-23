
CONFFILE="/initramfs/plugin-conf/vmchooser.conf"

if [ -e $CONFFILE ]; then
	. $CONFFILE
	if [ $vmchooser_active -ne 0 ]; then
		[ $DEBUGLEVEL -gt 0 ] && echo "executing the 'vmchooser' os-plugin ...";
                [ $DEBUGLEVEL -gt 0 ] && echo "creating default session entry ...";
                echo '[Desktop Entry]
                Encoding=UTF-8
                Name=virtual machine chooser (default)
                Name[de]=Virtuelle Maschine auswählen
                Comment=This session starts the vm session chooser
                Comment[de]=Diese Sitzung startet das Auswahlmenü für die vorhandenen Sitzungen
                Exec=/opt/openslx/plugin-repo/vmchooser/vmchooser
                TryExec=/opt/openslx/plugin-repo/vmchooser/vmchooser
		Icon=
                Type=Application' >> /mnt/etc/X11/sessions/default.desktop

		[ $DEBUGLEVEL -gt 0 ] && echo "done with 'vmchooser' os-plugin ...";
	fi
fi
