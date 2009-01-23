#!/bin/sh

#TODO: -m returns i686... we dont know it, we asume it!

# get newest kernel. We asume it is used
kfile=$(ls /boot/vmlinuz*|grep -v -e "^/boot/vmlinuz$"|sort|tail -n 1)
kversion=$(ls /boot/vmlinuz*|grep -v -e "^/boot/vmlinuz$"|sed 's,/boot/vmlinuz-,,'|sort|tail -n 1)

fullversion=$(strings ${kfile}|grep -e "${kversion}")

case $1 in
	-r)
		echo "${kversion}"
		;;
	-s)
		echo "Linux"
		;;
	-v)
		echo "${fullversion}"|sed 's/.*) //'
		;;
	-m)
		echo "i686"
		;;
	-rs)
		echo "Linux ${kversion}"
		;;
esac


