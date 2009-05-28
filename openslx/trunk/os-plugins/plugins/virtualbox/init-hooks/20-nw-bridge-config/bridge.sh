#!/bin/ash
# Copyright (c) 2009 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your feedback to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org
#
# Init hook to create a bridge on the active network interface
# (should be kept identical to the files of virtualbox and qemukvm plugins)
#############################################################################

local bridge=br0
local brnwif=${nwif}
local nwifmac=${macaddr}

# bridge 0 already defined or some other problem
brctl addbr ${bridge} || exit 0
brctl stp ${bridge} 0
brctl setfd ${bridge} 0.000000000001
ip link set addr ${nwifmac} ${bridge}
ip link set dev ${nwif} up
brctl addif ${bridge} ${nwif}

# fixme: sending back the variable to init does not work properly at the
# moment
nwif=${bridge}
