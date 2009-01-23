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

CONFFILE="/initramfs/plugin-conf/vmchooser.conf"

if [ -e $CONFFILE ]; then
	. $CONFFILE
	if [ $vmchooser_active -ne 0 ]; then
		[ $DEBUGLEVEL -gt 0 ] && echo "executing the 'vmchooser' os-plugin ...";
		[ $DEBUGLEVEL -gt 0 ] && echo "copying default .desktop file ...";
		cp /mnt/opt/openslx/plugin-repo/vmchooser/default.desktop /mnt/etc/X11/sessions/
		[ $DEBUGLEVEL -gt 0 ] && echo "done with 'vmchooser' os-plugin ...";
	fi
fi
