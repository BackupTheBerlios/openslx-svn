# Copyright (c) 2009 - OpenSLX GmbH
#
# This program/file is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your feedback to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org
#
# stage3 part of 'wlanboot' plugin - the runlevel script
#
# script is included from init via the "." load function - thus it has all
# variables and functions available

if [ -e /initramfs/plugin-conf/wlanboot.conf ]; then
  . /initramfs/plugin-conf/wlanboot.conf
  if [ $wlanboot_active -ne 0 ]; then
    [ $DEBUGLEVEL -gt 0 ] && echo "executing the 'wlanboot' os-plugin ...";
	#iwconfig wlan0 essid "wlanboottest"
	#ip link set wlan0 up
	#udhcpc -i wlan0
	
    [ $DEBUGLEVEL -gt 0 ] && echo "done with 'wlanboot' os-plugin ...";

  fi
fi
