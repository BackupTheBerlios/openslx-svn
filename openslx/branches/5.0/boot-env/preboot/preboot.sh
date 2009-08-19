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
# Linux stateless clients (fetched by Preboot init over the net)

# get configuration
. /etc/initramfs-setup
. ./preboot-scripts/dialog.functions

# bring the mac address into the standard format 01-<MAC>
client=$(echo 01-$macaddr|sed "s/:/-/g")

# check if already a configuration is available to decide if user interaction
# is required (path is to be fixed)
wget -q -O /tmp/have-user-config "$boot_uri/users.pl?user=${client}"
have_user_config=$(cat /tmp/have-user-config);

if [ "x1" == "x$have_user_config" ]; then
    wget -q -O /tmp/oldconfig "$boot_uri/users.pl?user=${client}&action=read"
    . /tmp/oldconfig
    menu_oldconfig $oldconfig  
else
    menu_firststart
fi
rm result;

# Switch here for several boot TYPE=fastboot/directkiosk/cfgkiosk/slxconfig
# fastboot - no interaction use system from client config
# directkiosk - start the default slx system into kiosk (using vmchooser)
# cfgkiosk - offer the user changes to his kiosk system (GUI environment)
# slxconfig - offer the user set of configuration options, like setting a non-
# priviledged user, root password, standard gui, plugins to activate ...

# we expect to have a system selection dialog file in /preboot/bootmenu.dialog
while [ "x$(cat result)" = "x" ] ; do
  dialog --file bootmenu.dialog 2>result
done
# source the system to boot configuration ($kernel, $initramfs, $append,
# $label)
sysname=$(cat result)
. ./$sysname
sysname=$(readlink $sysname)

# set basic post data information
postdata="system=${sysname}&preboot_id=${preboot_id}&client=${client}"

# ask for desired debug level in stage3 if debug!=0 in preboot
echo "0" >result
[ x$DEBUGLEVEL != x0 ] && dialog --no-cancel --menu "Choose Debug Level:" \
   20 65 10 "0" "no debug output (splash)"  \
            "2" "standard debug output" \
            "3" "debug output and shell" 2>result

# change debug level here if required (adjusted for the rest of the interactive
# part)
DEBUGLEVEL=$(cat result)
if [ x$DEBUGLEVEL != x0 ]; then
	debug="debug=$DEBUGLEVEL"
else
    debug=""
fi 

# send information to configuration host via http
wget --post-data "$postdata" -O /tmp/cfg-error \
  $boot_uri/cgi-bin/user_settings.pl

[ "x$DEBUGLEVEL" != x0 -a grep -qe "Error:" /tmp/cfg-error 2>/dev/null ] && \
  dialog --msgbox "An error occured ..." # to be elaborated

# fetch kernel and initramfs of selected system
dialog --infobox "Loading kernel of ${sysname} ..." 3 65
wget -q -O /tmp/kernel $boot_uri/$kernel
dialog --infobox "Loading initial ramfs of ${sysname} ..." 3 65
wget -q -O /tmp/initramfs $boot_uri/$initramfs

# read primary IP configuration to pass it on (behaviour like IPAPPEND=1 of
# PXElinux)
. /tmp/ipstuff

[ "x$DEBUGLEVEL" != x0 ] && { clear; ash; }

# start the new kernel with initialramfs and composed cmdline
dialog --infobox "Booting OpenSLX client $label ..." 3 65
kexec -l /tmp/kernel --initrd=/tmp/initramfs \
  --append="$append file=$boot_uri/${preboot_id}/client-config/${sysname}/${client}.tgz $quiet ip=$ip:$siaddr:$router:$subnet:$dnssrv $debug" 2>/dev/null
kexec -e >/dev/null 2>&1
