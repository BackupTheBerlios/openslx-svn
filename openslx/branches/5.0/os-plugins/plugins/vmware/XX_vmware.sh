# Copyright (c) 2007..2009 - RZ Uni Freiburg
# Copyright (c) 2008..2009 - OpenSLX GmbH
#
# This program/file is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your feedback to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org
#
# script is included from init via the "." load function - thus it has all
# variables and functions available

# TODO: nvram,functions
# write /etc/vmware/config (if a non-standard location of vmware basedir is
# to be configured), /etc/init.d/vmware

# check if the configuration file is available
if [ -e /initramfs/plugin-conf/vmware.conf ]; then

  # load needed variables
  . /initramfs/plugin-conf/vmware.conf

  # Test if this plugin is activated... more or less useless with the
  # new plugin system
  if [ $vmware_active -ne 0 ]; then

    [ $DEBUGLEVEL -gt 0 ] && echo "executing the 'vmware' os-plugin ...";
    # Load general configuration
    . /initramfs/machine-setup

    testmkd /mnt/tmp/vmware 1777
    testmkd /dev/shm/vmware 1777

    # write the /etc/vmware/slxvmconfig file
    # check for the several variables and write the several files:
    #  dhcpd.conf for vmnet* interfaces
    #  nat.conf for the NAT configuration of vmnet8
    #  TODO: vmnet-natd-8.mac not clear if really needed and which mac it
    # should contain (seems to be an average one)
    echo -e "# configuration file for vmware background services written in \
stage3 setup" > /mnt/etc/vmware/slxvmconfig
    if [ "$vmware_bridge" = 1 ] ; then
      echo "vmnet0=true" >> /mnt/etc/vmware/slxvmconfig
    fi
    # write the common dhcpd.conf header for vmnet1,8
    if [ -n "$vmware_vmnet1" -o -n "$vmware_vmnet8" ] ; then
      # use the dns servers known to the vmware host
      local dnslist=$(echo "$domain_name_servers"|sed "s/ /,/g")
      echo "# Common dhcpd.conf header written in stage3 ..." \
        > /mnt/etc/vmware/dhcpd-head.conf
      echo "allow unknown-clients;" \
        >> /mnt/etc/vmware/dhcpd-head.conf
      echo "default-lease-time 1800;" \
        >> /mnt/etc/vmware/dhcpd-head.conf
      echo "max-lease-time 7200;" \
        >> /mnt/etc/vmware/dhcpd-head.conf
      echo "option domain-name-servers $dnslist;" \
        >> /mnt/etc/vmware/dhcpd-head.conf
     echo "option domain-name \"vm.local\";" \
        >> /mnt/etc/vmware/dhcpd-head.conf
    fi

    # variable might contain ",NAT" which is to be taken off
    if [ -n "$vmware_vmnet1" ] ; then
      cp /mnt/etc/vmware/dhcpd-head.conf /mnt/etc/vmware/dhcpd-vmnet1.conf
      local vmnet1=${vmware_vmnet1%,*} # x.x.x.x/yy,NAT => 'x.x.x.x/yy'
      local vmnat=${vmware_vmnet1#$vmnet1*} # x.x.x.x/yy,NAT => ',NAT'
      local vmip=${vmnet1%/*} # x.x.x.x/yy => 'x.x.x.x'">
      local vmpx=${vmnet1#*/} # x.x.x.x/yy => 'yy'
      local vmsub=$(echo $vmip |sed 's,\(.*\)\..*,\1,') # x.x.x.x => x.x.x
      echo -e "vmnet1=$vmnet1" >> /mnt/etc/vmware/slxvmconfig
      [ -n "$vmnat" ] && echo "vmnet1nat=true" >> /mnt/etc/vmware/slxvmconfig
      echo -e "\n# definition for virtual vmnet1 interface" \
        >> /mnt/etc/vmware/dhcpd-vmnet1.conf
      echo -e "subnet $(ipcalc -n $vmnet1|sed s/.*=//) netmask \
$(ipcalc -m $vmnet1|sed s/.*=//) {" \
        >> /mnt/etc/vmware/dhcpd-vmnet1.conf 
      echo -e "\trange ${vmsub}.10 ${vmsub}.20;" \
        >> /mnt/etc/vmware/dhcpd-vmnet1.conf 
      echo -e "\toption broadcast-address $(ipcalc -b $vmnet1|sed s/.*=//);" \
        >> /mnt/etc/vmware/dhcpd-vmnet1.conf 
      # Maybe a different ip is needed s. nat: vmnet="${vmsub}.2"
      echo -e "\toption routers $vmip;" \
        >> /mnt/etc/vmware/dhcpd-vmnet1.conf
      echo -e "}" \
        >> /mnt/etc/vmware/dhcpd-vmnet1.conf
      mknod /dev/vmnet1 c 119 1
    fi

    # vmware nat interface configuration
    if [ -n "$vmware_vmnet8" ] ; then
      cp /mnt/etc/vmware/dhcpd-head.conf /mnt/etc/vmware/dhcpd-vmnet8.conf
      local vmnet8ip=${vmware_vmnet8%/*}
      local vmpx=${vmware_vmnet8#*/}
      local vmsub=$(echo $vmnet8ip |sed 's,\(.*\)\..*,\1,') # x.x.x.x => x.x.x">
      # vmip is user for vmnet8 device
      # vmnet is user for config files nat.conf/dhcp
      local vmip="${vmsub}.1"
      local vmnet="${vmsub}.2"
      echo -e "vmnet8=$vmip/$vmpx" >> /mnt/etc/vmware/slxvmconfig
      echo -e "\n# definition for virtual vmnet8 interface" \
        >> /mnt/etc/vmware/dhcpd-vmnet8.conf
      echo -e "subnet $(ipcalc -n $vmip/$vmpx|sed s/.*=//) netmask \
$(ipcalc -m $vmip/$vmpx|sed s/.*=//) {" \
        >> /mnt/etc/vmware/dhcpd-vmnet8.conf
      echo -e "\trange ${vmsub}.10 ${vmsub}.20;" \
        >> /mnt/etc/vmware/dhcpd-vmnet8.conf
      echo -e "\toption broadcast-address $(ipcalc -b $vmip/$vmpx|sed s/.*=//);" \
        >> /mnt/etc/vmware/dhcpd-vmnet8.conf
      echo -e "\toption routers $vmnet;" \
        >> /mnt/etc/vmware/dhcpd-vmnet8.conf
      echo -e "}" \
        >> /mnt/etc/vmware/dhcpd-vmnet8.conf
      echo -e "# Linux NAT configuration file" \
        > /mnt/etc/vmware/nat.conf
      echo -e "[host]" \
        >> /mnt/etc/vmware/nat.conf
      echo -e "ip = $vmnet/$vmpx" \
        >> /mnt/etc/vmware/nat.conf
      echo -e "device = /dev/vmnet8" \
        >> /mnt/etc/vmware/nat.conf
      echo -e "activeFTP = 1" \
        >> /mnt/etc/vmware/nat.conf
      echo -e "[udp]" \
        >> /mnt/etc/vmware/nat.conf
      echo -e "timeout = 60" \
        >> /mnt/etc/vmware/nat.conf
      echo -e "[incomingtcp]" \
        >> /mnt/etc/vmware/nat.conf
      echo -e "[incomingudp]" \
        >> /mnt/etc/vmware/nat.conf
      echo "00:50:56:F1:30:50" > /mnt/etc/vmware/vmnet-natd-8.mac
      mknod /dev/vmnet8 c 119 8
    fi
    # copy the runlevel script to the proper place and activate it
    sed "s/eth0/$nwif/g" \
      /mnt/opt/openslx/plugin-repo/vmware/${vmware_kind}/vmware.init \
      > /mnt/etc/init.d/vmware-env \
      || echo "  * Error copying runlevel script. Shouldn't happen."
    chmod a+x /mnt/etc/init.d/vmware-env
    rllinker "vmware-env" 20 2

    #############################################################################
    # vmware stuff first part: two scenarios
    # * VM images in /usr/share/vmware - then simply link
    # * VM images via additional mount (mount source NFS, NBD, ...)

    # get source of vmware image server (get type, server and path)
    if strinstr "/" "${vmware_imagesrc}" ; then
      vmimgprot=$(uri_token ${vmware_imagesrc} prot)
      vmimgserv=$(uri_token ${vmware_imagesrc} server)
      vmimgpath="$(uri_token ${vmware_imagesrc} path)"
    fi
    if [ -n "${vmimgserv}" -a -n ${vmimgpath} -a -n ${vmimgprot} ] ; then
      mnttarget=/mnt/var/lib/virt/vmware
      # mount the vmware image source readonly (ro)
      fsmount ${vmimgprot} ${vmimgserv} ${vmimgpath} ${mnttarget} ro
    else
      [ $DEBUGLEVEL -gt 1 ] && error "  * Incomplete information in variable \
${vmware_imagesrc}." nonfatal
    fi
    
    #############################################################################
    # vmware stuff second part: setting up the environment
    
    # create needed directories and files
    for i in /var/run/vmware /etc/vmware/loopimg \
             /etc/vmware/fd-loop /var/X11R6/bin; do
      testmkd /mnt/$i
    done

    # make vmware dhcpd more silent
    touch /mnt/var/run/vmware/dhcpd-vmnet1.leases \
          /mnt/var/run/vmware/dhcpd-vmnet8.leases

    # create the needed devices which effects all vmware options
    # they are not created automatically via module load
    for i in "/dev/vmnet0 c 119 0" "/dev/vmmon c 10 165"; do
      mknod $i
    done

    chmod 0700 /dev/vmnet*
    chmod 1777 /mnt/var/run/vmware

    echo -e "usbfs\t\t/proc/bus/usb\tusbfs\t\tauto\t\t 0 0" >> /mnt/etc/fstab
    # needed for VMware 5.5.4 and versions below
    echo -e "\tmount -t usbfs usbfs /proc/bus/usb 2>/dev/null" \
      >>/mnt/etc/init.d/boot.slx

    # disable VMware swapping 
    echo -e '.encoding = "UTF-8"\nprefvmx.minVmMemPct = "100"
prefvmx.useRecommendedLockedMemSize = "TRUE"' | sed -e "s/^ *//" \
      >/mnt/etc/vmware/config

    # copy version depending files - the vmchooser expects for every virtua-
    # lization plugin a file named after it (here run-vmware.include)
    testmkd /mnt/etc/opt/openslx
    cp /mnt/opt/openslx/plugin-repo/vmware/run-virt.include \
      /mnt/etc/opt/openslx/run-vmware.include
    # copy version depending files
    cp /mnt/opt/openslx/plugin-repo/vmware/${vmware_kind}/vmplayer \
        /mnt/var/X11R6/bin/vmplayer
    if [ -e /mnt/opt/openslx/plugin-repo/vmware/${vmware_kind}/vmware ]; then
      cp /mnt/opt/openslx/plugin-repo/vmware/${vmware_kind}/vmware \
          /mnt/var/X11R6/bin/vmware
    fi

    # affects only kernel and config depending configuration of not
    # local installed versions
    cat /mnt/opt/openslx/plugin-repo/vmware/${vmware_kind}/config \
      >>/mnt/etc/vmware/config
    chmod 644 /mnt/etc/vmware/config
    echo "# stage1 variables produced during plugin install" \
      >>/mnt/etc/vmware/slxvmconfig
    cat /mnt/opt/openslx/plugin-repo/vmware/${vmware_kind}/slxvmconfig \
      >>/mnt/etc/vmware/slxvmconfig

    # if /tmp resides on nfs: create an empty container file for vmware *.vmem
    # it does not like to live on NFS exports (still needed??)
    #if [ cat /proc/mounts|grep -qe "^/tmp "|grep -qe "nfs" ] ; then
    #  dd if=/dev/zero of=/mnt/tmp/vm-container count=1 seek=2048000
    #  diskfm /mnt/tmp/vm-container /mnt/tmp/vmware
    #  chmod a+rwxt /mnt/tmp/vmware
    #fi
    [ $DEBUGLEVEL -gt 0 ] && echo "done with 'vmware' os-plugin ..."

  fi
else
  [ $DEBUGLEVEL -gt 0 ] && echo "  * Configuration of vmware plugin failed"
fi
