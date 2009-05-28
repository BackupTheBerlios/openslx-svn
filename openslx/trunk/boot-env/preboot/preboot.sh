#!/bin/ash
# Copyright (c) 2009 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your feedback to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org
#
# preboot script for user interaction with OpenSLX preloading environment for
# Linux stateless clients

# get configuration
. /etc/initramfs-setup

# we expect to have a system selection dialog file in /preboot/bootmenu.dialog
while [ "x$(cat result)" = "x" ] ; do
  dialog --file bootmenu.dialog 2>result
done
# source the system to boot configuration ($kernel, $initramfs, $append,
# $label)
sysname=$(cat result)
. ./$sysname
sysname=$(readlink $sysname)

ash

# bring the mac address into the standard format 01-<MAC>
client=$(echo 01-$macaddr|sed "s/:/-/g")
chvt 4
w3m -o confirm_qq=no \
  "$boot_uri/cgi-bin/user_settings.pl?system=${sysname}&preboot_id=${preboot_id}&client=${client}"
chvt 1

# fetch kernel and initramfs of selected system 
wget -O /tmp/kernel $boot_uri/$kernel
wget -O /tmp/initramfs $boot_uri/$initramfs

# read primary IP configuration to pass it on
. /tmp/ipstuff

# start the new kernel with initialramfs and composed cmdline
echo "Booting OpenSLX client $label ..."
kexec -l /tmp/kernel --initrd=/tmp/initramfs \
  --append="$append file=$boot_uri/${preboot_id}/client-config/${sysname}/${client}.tgz $quiet ip=$ip:$siaddr:$router:$subnet:$dnssrv debug=3"
kexec -e
