# Copyright (c) 2009 - RZ Uni Freiburg
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
# Stage3 part of 'vmchooser' plugin - this script detects additionally to the
# the standard hardware configuration the availability of optical and floppy
# drives for virtual machines.
#
# The script is included from init via the "." load function - thus it has all
# variables and functions available.

waitfor /tmp/hwcfg
( hwinfo --cdrom | grep -i "Device File:" | awk {'print $3'} >/etc/hwinfo.cdrom ) & 
( hwinfo --floppy | grep -i "Device File:" | awk {'print $3'} >/etc/hwinfo.floppy ) &
