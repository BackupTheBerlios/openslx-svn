#! /bin/sh
# Copyright (c) 1996 SuSE GmbH Nuernberg, Germany.  All rights reserved.
#
# Author: Florian La Roche <florian@suse.de>, 1996
#	  Werner Fink <werner@suse.de>, 1996
#
# modifications for use with diskless X stations (v3.3)
# Dirk von Suchodoletz <dirk@goe.net>, 07-07-2005
#
# /sbin/init.d/halt (and symlinked to reboot)
#

. /etc/rc.status
. /etc/sysconfig/clock
. /etc/sysconfig/suseconfig

#
# Avoid being interrupted by child or keyboard
trap "echo" SIGINT SIGSEGV SIGQUIT SIGTERM
set +e

rc_reset
case "$0" in
	*halt)
		message="The system is halted."
		command="halt"
		modprobe -q apm &>/dev/null
		if test -e /proc/apm -o -e /proc/acpi -o -e /proc/sys/acpi ; then
			command="halt -p"
		else
			read cmdline < /proc/cmdline
			case "$cmdline" in
				*apm=smp-power-off*|*apm=power-off*)
				command="halt -p" ;;
			esac
                fi
		;;
	*reboot)
		message="Please stand by while rebooting the system..."
		command="reboot"
		;;
	*)
		echo "$0: call me as \"halt\" or \"reboot\" please!"
		exit 1
		;;
esac

# Write to wtmp file before unmounting /var (only needed with 
# persistent mounted filesystem)
# $command -w 

rc_reset
echo "Turning off swap"
sync ; sync
swapoff -a || rc_failed
rc_status

UMOUNT_FAILED=false
rc_reset
echo "Unmounting file systems and devices"
for unmount in /media/* ; do
	umount -fnt $unmount &>/dev/null
done
umount -fnt /tmp/scratch &>/dev/null
eject /dev/zip &>/dev/null &
rc_status -v1

umount -anft noproc,nonfs &>/dev/null

rc_reset
# maybe we use multiple devices
if test -f /etc/mdtab -a -x /sbin/mdadd ; then
    echo -n "Disable Multiple Devices"
    /sbin/mdstop -a || rc_failed
    rc_status -v1
fi

sync

# show "the system is down" message
if test "$SPLASH" = yes ; then
        /sbin/splash -q -p 65535 -t "isdown"
fi

echo $message
exec $command -d -f
