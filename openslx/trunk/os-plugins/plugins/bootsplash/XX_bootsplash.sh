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
# script is included from init via the "." load function - thus it has all
# variables and functions available

if [ -e /initramfs/plugin-conf/bootsplash.conf ]; then
  . /initramfs/plugin-conf/bootsplash.conf
  if [ $bootsplash_active -ne 0 ]; then
    if [ -e /tmp/bootsplash ]; then
      # create a runlevelscript that will stop splashy before the start of KDM
      d_mkrlscript init splashy.stop "Stopping Splashy ..."
        echo -e "\t/opt/openslx/plugin-repo/bootsplash/bin/splashy_update.glibc\
            exit 2>/dev/null \
          \n\ttype killall >/dev/null 2>&1 && killall -9 splashy \
          \n\trm -f /etc/init.d/splashy.stop 2>/dev/null" \
            >>/mnt/etc/init.d/splashy.stop
      d_mkrlscript close splashy.stop ""
    fi
  fi
fi

