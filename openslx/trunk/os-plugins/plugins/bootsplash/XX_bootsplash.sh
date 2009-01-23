#!/bin/ash
#
# Copyright (c) 2007..2008 - RZ Uni Freiburg
# Copyright (c) 2008 - OpenSLX GmbH
#
# This program/file is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your feedback to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org
#
# stage3 part of 'bootsplash' plugin - the runlevel script
#
. /etc/functions
. /etc/distro-functions
[ -d /etc/sysconfig ] && . /etc/sysconfig/config
if [ -e /initramfs/plugin-conf/bootsplash.conf ]; then
  . /initramfs/plugin-conf/bootsplash.conf
  if [ $bootsplash_active -ne 0 ]; then
    if [ ${no_bootsplash} -eq 0 ]; then
      # make the splashy_update binary available in stage4 ...
      testmkd /mnt/var/lib/openslx/bin
      cp -a /bin/splashy_update /mnt/var/lib/openslx/bin
      # ... and create a runlevelscript that will stop splashy somewhere near
      # the end of stage4
      d_mkrlscript init splashy.stop "Stopping Splashy ..."
        echo -e "\t/var/lib/openslx/bin/splashy_update exit 2>/dev/null \
          \n\ttype killall >/dev/null 2>&1 && killall -9 splashy \
          \n\trm -f /var/lib/openslx/bin/splashy_update 2>/dev/null \
          \n\trm -f /etc/${D_INITDIR}/splashy.stop 2>/dev/null" \
            >>/mnt/etc/${D_INITDIR}/splashy.stop
      d_mkrlscript close splashy.stop ""
    fi
  fi
fi
