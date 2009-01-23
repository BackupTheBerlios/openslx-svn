
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
# stage3 part of 'dropbear' plugin - the runlevel script
#
# script is included from init via the "." load function - thus it has all
# variables and functions available

if [ -e /initramfs/plugin-conf/dropbear.conf ]; then
  . /initramfs/plugin-conf/dropbear.conf
  if [ $dropbear_active -ne 0 ]; then
    [ $DEBUGLEVEL -gt 0 ] && echo "executing the 'dropbear' os-plugin ...";
  
       /mnt/opt/openslx/plugin-repo/dropbear/bin/dropbear \
        -d /mnt/etc/ssh/ssh_host_dsa_key \
        -r /mnt/etc/ssh/ssh_host_rsa_key

    [ $DEBUGLEVEL -gt 0 ] && echo "done with 'dropbear' os-plugin ...";

  fi
fi
