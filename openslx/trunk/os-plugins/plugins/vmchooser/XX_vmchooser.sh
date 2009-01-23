
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
                Exec=/etc/X11/sessions/default.sh
                TryExec=/etc/X11/sessions/default.sh
		Icon=
                Type=Application' >> /mnt/etc/X11/sessions/default.desktop


		[ $DEBUGLEVEL -gt 0 ] && echo "creating wrapper script ...";
		echo '#!/bin/bash
		# This script was created from XX_vmchooser.sh
		# and is a wrapper script for the vmchooser program
		/opt/openslx/plugin-repo/vmchooser/vmchooser -s /etc/X11/sessions/
		/etc/X11/sessions/session.sh &
		' >> /mnt/etc/X11/sessions/default.sh
		chmod +x /mnt/etc/X11/sessions/default.sh

		[ $DEBUGLEVEL -gt 0 ] && echo "done with 'vmchooser' os-plugin ...";
	fi
fi
