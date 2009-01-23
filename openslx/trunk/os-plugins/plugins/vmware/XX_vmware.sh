#!/bin/ash
#
# Copyright (c) 2007, 2008 - RZ Uni Freiburg
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

# TODO: nvram,functions
# check if we really need locations and config if we create our own
# vmware start script ...
# to be decided where: Stage1 or here in Stage3 --> 
#  write /etc/vmware/locations, /etc/vmware/config, /etc/init.d/vmware

# check if the configuration file is available
if [ -e /initramfs/plugin-conf/vmware.conf ]; then

  # load needed variables
  . /initramfs/plugin-conf/vmware.conf

  # Test if this plugin is activated...
  if [ $vmware_active -ne 0 ]; then

    [ $DEBUGLEVEL -gt 0 ] && echo "executing the 'vmware' os-plugin ...";
    # Load general configuration
    . /initramfs/machine-setup
    . /etc/functions
    . /etc/sysconfig/config

    # prepare all needed vmware configuration files
    if [ -d /mnt/etc/vmware ] ; then
      rm -rf /mnt/etc/vmware/*
    else
      mkdir -p /mnt/etc/vmware
    fi
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
      # use the dns servers know to the vmware host
      # TODO: to be checked!!
      local dnslist=$(echo "$domain_name_servers"|sed "s/ /,/g")
      echo -e "# /etc/vmware/dhcpd.conf written in stage3 ...\nallow \
unknown-clients;\ndefault-lease-time 1800;\nmax-lease-time 7200;\n\
option domain-name-servers $dnslist;\noption domain-name \"vm.local\";" \
        > /mnt/etc/vmware/dhcpd.conf
    fi
    # variable might contain ",NAT" which is to be taken off
    if [ -n "$vmware_vmnet1" ] ; then
      local vmnt=${vmware_vmnet1%,*}
      local vmnet1=${vmware_vmnet%,*}
      local vmip=${vmnet1%/*}
      local vmpx=${vmnet1#*/}
      echo "$vmnt, $vmnet1, $vmip, $vmpx"
      echo -e "vmnet1=$vmip/$vmpx" >> /mnt/etc/vmware/slxvmconfig
      [ -n "$vmnt" ] && echo "vmnet1nat=true" >> /mnt/etc/vmware/slxvmconfig
      echo -e "subnet $(ipcalc -n $vmip/$vmpx|sed s/.*=//) netmask \
$(ipcalc -n $vmip/$vmpx|sed s/.*=//) {\n\trange $rstart $rend;\n\
\toption broadcast $(ipcalc -b $vmip/$vmpx|sed s/.*=//);\n\
\toption routers $vmip;\n}" > /mnt/etc/vmware/dhcpd.conf
    fi
    # vmware nat interface
    if [ -n "$vmware_vmnet8" ] ; then
      local vmip=${vmware_vmnet8%/*}
      local vmpx=${vmware_vmnet8#*/}
      echo "vmnet8=$vmip/$vmpx" >> /mnt/etc/vmware/slxvmconfig
      echo "\nsubnet $(ipcalc -n $vmip/$vmpx|sed s/.*=//) netmask \
$(ipcalc -n $vmip/$vmpx|sed s/.*=//) {\n\trange $rstart $rend;\n\
\toption broadcast $(ipcalc -b $vmip/$vmpx|sed s/.*=//);\n\
\toption routers $vmip;\n}" > /mnt/etc/vmware/dhcpd.conf
      # generate the NAT configuration file
      echo "# Linux NAT configuration file\n[host]\nip = $vmip/$vmpx\n\
device = /dev/vmnet8\nactiveFTP = 1\n[udp]\ntimeout = 60\n[incomingtcp]\n\
[incomingudp]" > /mnt/etc/vmware/nat.conf
      echo "00:50:56:F1:30:50" > /mnt/etc/vmware/vmnet-natd-8.mac
    fi
    # copy the runlevelscript to the proper place
    cp /mnt/opt/openslx/plugin-repo/vmware/vmware-init \
      /mnt/etc/${D_INITDIR}/vmware
    rllinker "vmware" 20 2


    echo "  * vmware part 1"
    #############################################################################
    # vmware stuff first part: two scenarios
    # * VM images in /usr/share/vmware - then simply link
    # * VM images via additional mount (mount source NFS, NBD, ...)

    # map slxgrp to pool, so it's better to understand
    pool=${slxgrp}
    # if we dont have slxgrp defined
    [ -z "${pool}" ] && pool="default"

    # get source of vmware image server (get type, server and path)
    if strinstr "/" "${vmware_imagesrc}" ; then
      vmimgprot=$(uri_token ${vmware_imagesrc} prot)
      vmimgserv=$(uri_token ${vmware_imagesrc} server)
      vmimgpath="$(uri_token ${vmware_imagesrc} path)"
    fi
    if [ -n "${vmimgserv}" ] ; then
      testmkd /mnt/var/lib/vmware
      case "${vmimgprot}" in
        *nbd)
          ;;
        lbdev)
          # we expect the stuff on toplevel directory, filesystem type should be
          # autodetected here ... (vmimgserv is blockdev here)
          vmbdev=/dev/${vmimgserv}
          waitfor ${vmbdev} 20000
          echo -e "ext2\nreiserfs\nvfat\nxfs" >/etc/filesystems
          mount -o ro ${vmbdev} /mnt/var/lib/vmware || error "$scfg_evmlm" nonfatal
          ;;
        *)
          # we expect nfs mounts here ...
          for proto in tcp udp fail; do
            [ $proto = "fail" ] && { error "$scfg_nfs" nonfatal;
            noimg=yes; break;}
          mount -n -t nfs -o ro,nolock,$proto ${vmimgserv}:${vmimgpath} \
            /mnt/var/lib/vmware && break
          done
          ;;
      esac
    fi
    
    echo "  * vmware part 2"
    
    #############################################################################
    # vmware stuff second part: setting up the environment
    
    # create needed directories and files
    for i in /var/run/vmware /etc/vmware/loopimg \
      /etc/vmware/fd-loop /var/X11R6/bin /etc/X11/sessions; do
      testmkd /mnt/$i
    done

    # create needed devices (not created automatically via module load)
    for i in "/dev/vmnet0 c 119 0" "/dev/vmnet1 c 119 1" \
      "/dev/vmnet8 c 119 8" "/dev/vmmon c 10 165"; do
      mknod $i
    done

    # create the vmware startup configuration file /etc/vmware/locations
    # fixme --> ToDo
    # echo -e "answer VNET_8_NAT yes\nanswer VNET_8_HOSTONLY_HOSTADDR \n\
    #192.168.100.1\nanswer VNET_8_HOSTONLY_NETMASK 255.255.255.0\n\
    #file /etc/vmware/vmnet8/dhcpd/dhcpd.conf\n\
    # remove_file /etc/vmware/not_configured" >/mnt/etc/vmware/locations
    
    chmod 0700 /dev/vmnet*
    chmod 1777 /mnt/etc/vmware/fd-loop

    # loop file for exchanging information between linux and vmware guest
    if modprobe ${MODPRV} loop; then
      mdev -s
    else
      : #|| error "" nonfatal
    fi
    # mount a clean tempfs (bug in UnionFS prevents loopmount to work)
    strinfile "unionfs" /proc/mounts && \
      mount -n -o size=1500k -t tmpfs vm-loopimg /mnt/etc/vmware/loopimg
    # create an empty floppy image of 1.4MByte size
    dd if=/dev/zero of=/mnt/etc/vmware/loopimg/fd.img \
      count=2880 bs=512 2>/dev/null
    chmod 0777 /mnt/etc/vmware/loopimg/fd.img
    # use dos formatter from rootfs (later stage4)
    LD_LIBRARY_PATH=/mnt/lib /mnt/sbin/mkfs.msdos \
      /mnt/etc/vmware/loopimg/fd.img >/dev/null 2>&1 #|| error
    mount -n -t msdos -o loop,umask=000 /mnt/etc/vmware/loopimg/fd.img \
      /mnt/etc/vmware/fd-loop
    echo -e "usbfs\t\t/proc/bus/usb\tusbfs\t\tauto\t\t 0 0" >> /mnt/etc/fstab
    # needed for VMware 5.5.3 and versions below
    echo -e "\tmount -t usbfs usbfs /proc/bus/usb 2>/dev/null" \
      >>/mnt/etc/${D_INITDIR}/boot.slx
    
    chmod 1777 /mnt/var/run/vmware
    # define a variable where gdm/kdm should look for additional sessions
    # do we really need it? looks like we can delete it...
    # export vmsessions=/var/lib/vmware/vmsessions
    
    # TODO: perhaps we can a) kick out vmdir
    #            b) configure vmdir by plugin configuration
    # TODO: How to start it. See Wiki. Currently a) implemnted
    #   a) we get get information and start the programm with
    #    /var/X11R6/bin/run-vmware.sh "$imagename" "$name_for_vmwindow" "$ostype_of_vm" "$kind_of_network"
    #   b) we write a wrapper and get the xml-file as attribute
    cp /mnt/opt/openslx/plugin-repo/vmware/runvmware-v2 \
      /mnt/var/X11R6/bin/run-vmware.sh

    [ $DEBUGLEVEL -gt 0 ] && echo "done with 'vmware' os-plugin ...";

  fi
fi
