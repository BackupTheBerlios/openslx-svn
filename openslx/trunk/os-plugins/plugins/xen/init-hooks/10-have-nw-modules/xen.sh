# configure Xen bridge xenbr0
modprobe ${MODPRV} netloop
local ipls
local vifnum="0"
local bridge="xenbr${vifnum}"
local netdev="eth${vifnum}"
local pdev="p${netdev}"
local vdev="veth${vifnum}"
local vif0="vif0.${vifnum}"
# fixme: that is the mac address of main ethernet device
local mac=`ip link show ${netdev} | grep 'link\/ether' | sed -e 's/.*ether \(..:..:..:..:..:..\).*/\1/'`

brctl addbr ${bridge}
brctl stp ${bridge} off
brctl setfd ${bridge} 0
brctl addif ${bridge} ${vif0}
for ipls in "${netdev} name ${pdev}" "${vdev} name ${netdev}" \
            "${pdev} down arp off" "${pdev} addr fe:ff:ff:ff:ff:ff" \
            "${netdev} addr ${mac} arp on" "${bridge} up" "${vif0} up" \
            "${pdev} up" "${netdev} up"; do
  ip link set ${ipls}
done
brctl addif ${bridge} ${pdev}
