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

#CONFFILE="/initramfs/plugin-conf/virtualbox.conf"

if [ -e $CONFFILE ]; then
  . $CONFFILE
  if [ $virtualbox_active -ne 0 ] ; then
     echo "here should be some stuff..."
  fi
fi
