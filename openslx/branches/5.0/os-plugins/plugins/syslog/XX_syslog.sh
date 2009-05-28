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
# stage3 part of 'syslog' plugin - the runlevel script
#
# script is included from init via the "." load function - thus it has all
# variables and functions available

# check if the plugin config directory is generally available or if the client
# configuration failed somehow
[ -d /initramfs/plugin-conf ] || error "${init_picfg}" nonfatal

if [ -e /initramfs/plugin-conf/syslog.conf ]; then
  . /initramfs/plugin-conf/syslog.conf
  if [ $syslog_active -ne 0 ]; then
    [ $DEBUGLEVEL -gt 0 ] && echo "executing the 'syslog' os-plugin ..."
  
    . /mnt/opt/openslx/plugin-repo/syslog/syslog.sh

    [ $DEBUGLEVEL -gt 0 ] && echo "done with 'syslog' os-plugin ..."

  fi
fi
