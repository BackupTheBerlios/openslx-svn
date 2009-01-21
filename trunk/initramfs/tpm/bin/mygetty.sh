#!/bin/sh
#

if [ -f "/mnt/sbin/agetty" ] ; then
	/mnt/sbin/agetty -n -l /bin/bash 9600 /dev/tty1
else
	echo "agetty-binary not found!"
fi

# /bin/bash
