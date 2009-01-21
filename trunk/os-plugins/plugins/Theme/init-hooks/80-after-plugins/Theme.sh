if [ ${Theme_nosplash} -eq 0 ]; then

	/bin/splashy_update "progress 80" >/dev/null 2>&1

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
	D_INITSCRIPTS="${D_INITSCRIPTS} splashy.stop"

fi