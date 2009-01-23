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
# stage3 part of 'xen' plugin - the runlevel script
#
# script is included from init via the "." load function - thus it has all
# variables and functions available

testmkd /mnt/var/log/xen
testmkd /mnt/var/run/xend
testmkd /mnt/var/run/xenstored

rllinker "xendomains" 14 8
rllinker "xend" 13 9

modprobe loop max_loop=64
