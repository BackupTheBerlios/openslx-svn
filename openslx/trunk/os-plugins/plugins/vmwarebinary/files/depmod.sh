#!/bin/sh

#TODO: -m returns i686... we dont know it, we asume it!

# get newest kernel. We asume it is used
kversion=$(ls /boot/vmlinuz*|grep -v -e "^/boot/vmlinuz$"|sed 's,/boot/vmlinuz-,,'|sort|tail -n 1)

case $1 in
	-a)
		/sbin/depmod.orig -a ${kversion}
		;;
esac
