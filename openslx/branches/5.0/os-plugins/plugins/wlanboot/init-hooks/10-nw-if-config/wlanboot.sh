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
# stage3 init-hook 10 of 'wlanboot' plugin - firing up the wlan connection

if [ $wlanboot_active -ne 0 ]; then
  # get essid for WLAN boot
  for source in /proc/cmdline /etc/initramfs-setup ; do
    essid=$(grep essid $source)
    if [ -n "$essid" ] ; then
      essid=${essid#essid=}
      break
    fi
  done
  # do WLAN specific settings, definition of wlan interface name and wireless
  # connect
  wlanif=$(iwconfig 2>/dev/null|sed -n "/ESSID:/p"|sed "s/    .*//")
  if [ -n "$if" ] ; then
    ip link set dev ${wlanif} up
    if iwconfig ${wlanif} mode managed essid "${essid}"; then
      nwif=${wlanif}
    else
      error "  Unable to configure the WLAN interface."
    fi
  else
    error "  No wireless LAN capable interface found. Did you provide the \
proper kernel\n  modules and firmware?"
fi

