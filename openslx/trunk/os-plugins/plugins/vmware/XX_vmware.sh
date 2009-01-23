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

    # prepare all needed vmware configuration files
    if [ -d /mnt/etc/vmware ] ; then
      rm -rf /mnt/etc/vmware/*
    else
      testmkd /mnt/etc/vmware
    fi
    # write the /etc/vmware/slxvmconfig file
    # check for the several variables and write the several files:
    #  dhcpd.conf for vmnet* interfaces
    #  nat.conf for the NAT configuration of vmnet8
    #  TODO: vmnet-natd-8.mac not clear if really needed and which mac it
    # should contain (seems to be an average one)
    echo -e "# configuration file for vmware background services written in \
stage3 setup" > /mnt/etc/vmware/slxvmconfig
    # fixme: sollte unnötig sein, das hier zu tun. "vmware-env" kann hier voll
    # determiniert werden, siehe Ticket 240
    echo "vmware_kind=${vmware_kind}" >> /mnt/etc/vmware/slxvmconfig
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
      echo -e "\toption routers $vmip;" \
        >> /mnt/etc/vmware/dhcpd-vmnet1.conf
      echo -e "}" \
        >> /mnt/etc/vmware/dhcpd-vmnet1.conf
      mknod /dev/vmnet1 c 119 1
    fi

    # vmware nat interface configuration
    if [ -n "$vmware_vmnet8" ] ; then
      cp /mnt/etc/vmware/dhcpd-head.conf /mnt/etc/vmware/dhcpd-vmnet8.conf
      local vmip=${vmware_vmnet8%/*}
      local vmpx=${vmware_vmnet8#*/}
      local vmsub=$(echo $vmip |sed 's,\(.*\)\..*,\1,') # x.x.x.x => x.x.x">
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
      echo -e "\toption routers $vmip;" \
        >> /mnt/etc/vmware/dhcpd-vmnet8.conf
      echo -e "}" \
        >> /mnt/etc/vmware/dhcpd-vmnet8.conf
      echo -e "# Linux NAT configuration file" \
        > /mnt/etc/vmware/nat.conf
      echo -e "[host]" \
        >> /mnt/etc/vmware/nat.conf
      echo -e "ip = $vmip/$vmpx" \
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
    # copy the runlevelscript to the proper place and activate it
    cp /mnt/opt/openslx/plugin-repo/vmware/${vmware_kind}/vmware.init \
      /mnt/etc/${D_INITDIR}/vmware-env \
      || echo "  * Error copying runlevel script. Shouldn't happen."
    chmod a+x /mnt/etc/${D_INITDIR}/vmware-env
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
    if [ -n "${vmimgserv}" ] ; then
      testmkd /mnt/var/lib/vmware
      case "${vmimgprot}" in
        *nbd)
          # TODO: to be filled in ...
          ;;
        lbdev)
          # we expect the stuff on toplevel directory, filesystem type should be
          # autodetected here ... (vmimgserv is blockdev here)
          vmbdev=/dev/${vmimgserv}
          waitfor ${vmbdev} 20000
          echo -e "ext2\nreiserfs\nvfat\nxfs" >/etc/filesystems
          mount -o ro ${vmbdev} /mnt/var/lib/vmware || \
            error "$scfg_evmlm" nonfatal
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
    chmod 1777 /mnt/etc/vmware/fd-loop
    chmod 1777 /mnt/var/run/vmware

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
    # needed for VMware 5.5.4 and versions below
    # TODO: isn't boot.slx dead/not functional due of missing ";; esac"?
    echo -e "\tmount -t usbfs usbfs /proc/bus/usb 2>/dev/null" \
      >>/mnt/etc/${D_INITDIR}/boot.slx


    ## Copy version depending files
    cp /mnt/opt/openslx/plugin-repo/vmware/${vmware_kind}/runvmware \
        /mnt/var/X11R6/bin/run-vmware.sh
    chmod 755 /mnt/var/X11R6/bin/run-vmware.sh
    cp /mnt/opt/openslx/plugin-repo/vmware/${vmware_kind}/vmplayer \
        /mnt/var/X11R6/bin/vmplayer
    if [ -e /mnt/opt/openslx/plugin-repo/vmware/${vmware_kind}/vmware ]; then
      cp /mnt/opt/openslx/plugin-repo/vmware/${vmware_kind}/vmware \
          /mnt/var/X11R6/bin/vmware
    fi


    # affects only kernel and config depending configuration of not
    # local installed versions
    if [ "${vmware_kind}" != "local" ]; then
      cp /mnt/opt/openslx/plugin-repo/vmware/${vmware_kind}/config \
        /mnt/etc/vmware
      chmod 644 /mnt/etc/vmware/config
    fi

    # write version information for image problem (v2 images don't run
    # on v1 players)
    if [ "${vmware_kind}" = "vmpl1.0" ]; then
      echo "vmplversion=1" > /mnt/etc/vmware/version
    elif [ "${vmware_kind}" = "vmpl2.0" ]; then
      echo "vmplversion=2" > /mnt/etc/vmware/version
    elif [ "${vmware_kind}" = "local" ]; then
      version=$(strings /usr/lib/vmware/bin/vmplayer|head -n 1|cut -c 1)
      echo "vmplversion=${version}" > /mnt/etc/vmware/version
    fi

    [ $DEBUGLEVEL -gt 0 ] && echo "done with 'vmware' os-plugin ..."

  fi
else
  [ $DEBUGLEVEL -gt 0 ] && echo "  * Configuration of vmware plugin failed"
fi
