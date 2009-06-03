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

#setting udhcpc up
mkdir -p /usr/share/udhcpc
echo -e "#!/bin/ash\nunset infomsg HOME IFS mask lease interface DEBUGLEVEL \
BOOT_IMAGE\nset >/tmp/ipstuff" >/usr/share/udhcpc/default.script
chmod u+x /usr/share/udhcpc/default.script

echo "! shutting down watchdog for debugging";
killall watchdog;

essid=$(sed -n 's/.*essid=\([^[:blank:]]*\) .*/\1/p' /proc/cmdline);
[ $DEBUGLEVEL -gt 0 ] && echo "set essid to ${essid}";
#value of essid unchecked yet


# load network adaptor modules
#modprobe iwl3945
cd /lib/modules/$(ls /lib/modules/)/kernel/drivers/net/wireless
for mod in $(find . | grep .ko | sed 's,.*/\([^/]*\).ko,\1',); do
  echo "Mod:";
  echo $mod;
  modprobe $mod || echo "module $mod did not load for some reason"
  usleep 10000 
done
cd /

wlanif=$(iwconfig 2>/dev/null|sed -n "/ESSID:/p"|sed "s/    .*//")
[ $DEBUGLEVEL -gt 0 ] && echo "wlancard recognized as ${wlanif}";

if [ -n "$wlanif" ] ; then
  ip link set dev ${wlanif} up
  if iwconfig ${wlanif} mode managed essid "${essid}"; then
    nwif=${wlanif}
  else
    error "  Unable to configure the WLAN interface."
  fi  
  
  
  ( sleep 6 ; killall udhcpc >/dev/null 2>&1 ) &
  udhcpc -f -n -q $vci -s /usr/share/udhcpc/default.script -i $nwif 2>/dev/null
  if grep "ip=" /tmp/ipstuff >/dev/null 2>&1 ; then
	. /tmp/ipstuff
	for i in $dns ; do
		echo "nameserver $i" >>/etc/resolv.conf
	done
    # simply add a single dns server for passing via kernel cmdline to stage3
    # (quickhack, just the last, list of dns might be better ...)
    echo "dnssrv=$i" >>/tmp/ipstuff
    return
  else
    if [ $i -eq 1 ] ; then
      sleep 1
    else
      echo "Did not get any proper IP configuration"; /bin/ash
    fi
  fi
  
  ip addr add $ip/$(ipcalc -s -p $ip $subnet|sed s/.*=//) dev $nwif
  ip route add default via $router
  [ $DEBUGLEVEL -gt 0 ] && echo "IP-Configuration: $ip on interface $wlanif."
else
  error "  No wireless LAN capable interface found. Did you provide the \
proper kernel\n  modules and firmware?"
fi