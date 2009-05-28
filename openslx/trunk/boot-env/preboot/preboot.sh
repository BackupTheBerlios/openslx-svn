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
dialog --file bootmenu.dialog 2>result
# source the system to boot configuration ($kernel, $initramfs, $append,
# $label)
. ./$(cat result)

echo $kernel

wget -O /tmp/kernel $boot_uri/$kernel
wget -O /tmp/initramfs $boot_uri/$initramfs

# read primary IP configuration to pass it on
. /tmp/ipstuff

# start the new kernel with initialramfs and cmdline
echo "Booting OpenSLX client $label ..."
kexec -l /tmp/kernel --initrd=/tmp/initramfs \
  --append="$append file=$boot_uri debug=3"
kexec -e
