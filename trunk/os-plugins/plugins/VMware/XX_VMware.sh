#! /bin/sh

# check if the configuration file is available
if [ -e /initramfs/plugin-conf/VMware.conf ]; then

	# load needed variables
	. /initramfs/plugin-conf/VMware.conf

	# Test if this plugin is activated
	if [ $VMware_active -ne 0 ]; then

		[ $DEBUGLEVEL -gt 0 ] && echo "executing the 'VMware' os-plugin ...";
		
		# Load general configuration
		. /initramfs/machine-setup
		# we need to load the function file for:
		# uri_token, testmkd
		. /etc/functions
		# D_INITDIR is defined in the following file:
		. /etc/sysconfig/config
		
		echo "  * VMware part 1"
		#############################################################################
		# vmware stuff first part: two scenarios
		# * VM images in /usr/share/vmware - then simply link
		# * VM images via additional mount (mount source NFS, NBD, ...)
		if [ "x${vmware}" != "x" ] && [ "x${vmware}" != "xno" ] ; then
		  # map slxgrp to pool, so it's better to understand
		  pool=${slxgrp}
		  # if we dont have slxgrp defined
		  [ -z "${pool}" ] && pool="default"
		
		  # get source of vmware image server (get type, server and path)
		  if strinstr "/" "${vmware}" ; then
		    vmimgprot=$(uri_token ${vmware} prot)
		    vmimgserv=$(uri_token ${vmware} server)
		    vmimgpath="$(uri_token ${vmware} path)"
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
		fi
		
		echo "  * VMware part 2"
		
		#############################################################################
		# vmware stuff second part: setting up the environment
		
		# create needed directories and files
		if [ "x${vmware}" != "x" ] && [ "x${vmware}" != "xno" ] ; then
		  for i in /etc/vmware/vmnet1/dhcpd /etc/vmware/vmnet8/nat \
		           /etc/vmware/vmnet8/dhcpd /var/run/vmware /etc/vmware/loopimg \
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
		  # TODO: we still use this function? Prove if we can delete it.
		  config_vmware                                                                 chmod 1777 /mnt/var/run/vmware                                                # define a variable where gdm/kdm should look for additional sessions         # do we really need it?                                                       # export vmsessions=/var/lib/vmware/vmsessions
		
		  # directory of templates and xdialog files
		  vmdir=/mnt/var/lib/vmware
		
		  if cp ${vmdir}/templates/xdialog.sh /mnt/var/X11R6/bin/ 2>/dev/null; then
		    # create default.desktop for kdm
		    echo -e "[Desktop Entry]\nEncoding=UTF8\nName=Default\nName[de]=Standard"\
		      >/mnt/etc/X11/sessions/default.desktop
		
		    #I dont like this part, but there is no simple workaround. We need to
		    #create xdialog.sh on every box :(
		    echo "Exec=/var/X11R6/bin/xdialog.sh" \
		      >>/mnt/etc/X11/sessions/default.desktop
		    echo "Type=Application" >>/mnt/etc/X11/sessions/default.desktop
		
		    # /usr/share/xsessions/* files for the menu
		    for i in /mnt/usr/share/xsessions/*.desktop; do
		      # execute
		      echo "\"$(grep '^Exec=' ${i}|sed 's/^Exec=//')\" \\" \
		        >>/mnt/var/X11R6/bin/xdialog.sh
		      # short description
		      echo "\"$(grep '^Name=' ${i}|sed 's/^Name=//')\" \\" \
		        >>/mnt/var/X11R6/bin/xdialog.sh
		      # long description
		      echo "\"$(grep '^Comment=' ${i}|sed 's/^Comment=//')\" \\" \
		        >>/mnt/var/X11R6/bin/xdialog.sh
		    done
		    # all virtual machine clients
		    cat ${vmdir}/xdialog-files/${pool}/*.xdialog \
		      >>/mnt/var/X11R6/bin/xdialog.sh
		    # closing bracket as last line ends with '\'
		    echo ")" >>/mnt/var/X11R6/bin/xdialog.sh
		    chmod 755 /mnt/var/X11R6/bin/xdialog.sh
		
		    # copy xdm files, so we could choose them before we log in
		    for i in ${vmdir}/xdmsessions/${pool}/*.desktop;do
		      cp ${i} /mnt/etc/X11/sessions/
		    done
		  else
		    error "$scfg_vmchs" nonfatal
		  fi
		  # we configured vmware, so we can delete the not_configured file
		  rm /mnt/etc/vmware/not_configured 2>/dev/null
		
		  # copy dhcpd.conf and nat for vmnet8 (nat)
		  # fixme: It should be possible to start just one vmware dhcp which should
		  # listen to both interfaces vmnet1 and vmnet8 ...
		  cp /mnt/var/lib/vmware/templates/dhcpd.conf \
		    /mnt/etc/vmware/vmnet8/dhcpd 2>/dev/null
		  cp /mnt/var/lib/vmware/templates/nat.conf \
		    /mnt/etc/vmware/vmnet8/nat 2>/dev/null
		fi
		
		[ $DEBUGLEVEL -gt 0 ] && echo "done with 'VMware' os-plugin ...";

	fi
fi