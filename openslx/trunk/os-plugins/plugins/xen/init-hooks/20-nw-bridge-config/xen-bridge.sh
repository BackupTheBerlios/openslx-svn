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
# XEN specific init hook to create a bridge on the active network interface
#############################################################################

# configure Xen bridge xenbr0 (would it be possible to make it just br0?)

modprobe ${MODPRV} netloop
local ipls
local vifnum="0"
local bridge="xenbr${vifnum}"
local netdev="eth${vifnum}"    # should be ${nwif}
local pdev="p${netdev}"
local vdev="veth${vifnum}"
local vif0="vif0.${vifnum}"
# fixme: that is the mac address of main ethernet device
local mac=${macaddr}

brctl addbr ${bridge}
brctl stp ${bridge} off
brctl setfd ${bridge} 0.000000000001
brctl addif ${bridge} ${vif0}
for ipls in "${netdev} name ${pdev}" "${vdev} name ${netdev}" \
            "${pdev} down arp off" "${pdev} addr fe:ff:ff:ff:ff:ff" \
            "${netdev} addr ${mac} arp on" "${netdev} addr ${mac} arp on" \
            "${bridge} up" "${vif0} up" "${pdev} up" ; do
  ip link set ${ipls}
done
brctl addif ${bridge} ${pdev}

# fixme: sending back the variable to init does not work properly at the
# moment
nwif=${bridge}
