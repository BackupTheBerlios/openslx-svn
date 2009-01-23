#!/bin/ash
#
# Copyright (c) 2008 - RZ Uni Freiburg
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
# stage3 part of 'xserver' plugin - the runlevel script setting up the Xorg
# configuration and checking for 3D capabilities and non-gpl drivers

if [ -e /initramfs/plugin-conf/xserver.conf ]; then
  . /initramfs/plugin-conf/xserver.conf
  if [ $example_active -ne 0 ]; then
    [ $DEBUGLEVEL -gt 0 ] && echo "executing the 'xserver' os-plugin ...";
    


    [ $DEBUGLEVEL -gt 0 ] && echo "done with 'bindrivers' os-plugin ...";
  fi
fi
