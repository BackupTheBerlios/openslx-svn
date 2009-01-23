#! /bin/ash
#
# stage3 part of 'syslog' plugin - the runlevel script
#
. /etc/functions
. /etc/distro-functions
. /etc/sysconfig/config
if [ -e /initramfs/plugin-conf/syslog.conf ]; then
  . /initramfs/plugin-conf/syslog.conf
  if [ $syslog_active -ne 0 ]; then
    [ $DEBUGLEVEL -gt 0 ] && echo "executing the 'syslog' os-plugin ...";
  
    . /mnt/opt/openslx/plugin-repo/syslog/syslog.sh

    [ $DEBUGLEVEL -gt 0 ] && echo "done with 'syslog' os-plugin ...";

  fi
fi
