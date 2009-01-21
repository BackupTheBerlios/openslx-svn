#! /bin/sh
#
# stage3 part of 'Theme' plugin - the runlevel script
#
if ! [ -e /initramfs/plugin-conf/Theme.conf ]; then
	exit 1
fi
. /initramfs/plugin-conf/Theme.conf

if ! [ -n $active ]; then
	exit 0
fi

echo "executing the 'Theme' os-plugin ...";

# nothing to do here, really

echo "done with 'Theme' os-plugin ...";
