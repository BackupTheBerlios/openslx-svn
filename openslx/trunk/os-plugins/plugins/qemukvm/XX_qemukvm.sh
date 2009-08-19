# Copyright (c) 2008, 2009 - OpenSLX GmbH
#
# This program/file is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your feedback to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org
#
# Script is included from init via the "." load function - thus it has all
# variables and functions available

write_udhcpd_conf ()
{
local cfgfile=$1
echo "
# udhcpd configuration file written by $0 during OpenSLX stage3 configuration

# The start and end of the IP lease block
start 		192.168.101.20
end		192.168.101.100

# The interface that udhcpd will use
interface	NWIF

# How long an offered address is reserved (leased) in seconds
offer_time	6000

# The location of the leases file
lease_file	/tmp/qemu-USER/udhcpd.leases

# The location of the pid file
pidfile		/tmp/qemu-USER/udhcpd.pid

opt	dns	${domain_name_servers}
option	subnet	255.255.255.0
opt	router	192.168.101.254
opt	wins	192.168.101.10
option	domain	virtual.site ${domain_name}

# Additional options known to udhcpd
#subnet			#timezone
#router			#timesvr
#namesvr		#dns
#logsvr			#cookiesvr
#lprsvr			#bootsize
#domain			#swapsvr
#rootpath		#ipttl
#mtu			#broadcast
#wins			#lease
#ntpsrv			#tftp
#bootfile
" >${cfgfile}
}

# check if the configuration file is available
if [ -e /initramfs/plugin-conf/qemukvm.conf ]; then

  # check for the virtualization CPU features
  if grep -q "svm" /proc/cpuinfo && modprobe ${MODPRV} kvm_amd ; then
    [ $DEBUGLEVEL -gt 0 ] && echo "  * Loaded kvm_amd module"
  elif grep -q "vmx" /proc/cpuinfo &&  modprobe  ${MODPRV} kvm_intel ; then
    [ $DEBUGLEVEL -gt 0 ] && echo "  * Loaded kvm_intel module"
  elif modprobe ${MODPRV} kqemu ; then
    [ $DEBUGLEVEL -gt 0 ] && \
    error "  * Successfully loaded the kqemu module, but loading of kvm_amd \
or kvm_intel\n  failed, because no virtualization extenstion found in this \
CPU. Please\n  enable the extension within your machines BIOS or get another \
CPU." nonfatal
  else
    error "  * All module loading failed including the kqemu module, which \
was either\n  not found or couldn't be loaded for other reasons. Thus using \
qemu(-kvm)\n  makes not much sense."
    exit 1
  fi
  # load the tunnel device module
  modprobe tun 2>/dev/null
    
  # load needed variables
  . /initramfs/plugin-conf/qemukvm.conf

  # Test if this plugin is activated... more or less useless with the
  # new plugin system
  if [ $qemukvm_active -ne 0 ]; then

    [ $DEBUGLEVEL -gt 0 ] && echo "executing the 'qemukvm' os-plugin ...";
    # load general configuration
    . /initramfs/machine-setup

    # get source of qemukvm image server (get type, server and path)
    if strinstr "/" "${qemukvm_imagesrc}" ; then
      qkimgprot=$(uri_token ${qemukvm_imagesrc} prot)
      qkimgserv=$(uri_token ${qemukvm_imagesrc} server)
      qkimgpath="$(uri_token ${qemukvm_imagesrc} path)"
    fi
    if [ -n "${qkimgserv}" ] ; then
      # directory where qemu images are expected in
      mnttarget=/mnt/var/lib/virt/qemukvm
      # mount the qemukvm image source readonly (ro)
      fsmount ${qkimgprot} ${qkimgserv} ${qkimgpath} ${mnttarget} ro
    else
      [ $DEBUGLEVEL -gt 1 ] && error "  * Incomplete information in variable \
${qemukvm_imagesrc}." nonfatal
    fi
    # copy version depending files - the vmchooser expects for every virtua-
    # lization plugin a file named after it (here run-qemukvm.include)
    testmkd /mnt/etc/opt/openslx
    cp /mnt/opt/openslx/plugin-repo/qemukvm/run-virt.include \
      /mnt/etc/opt/openslx/run-qemukvm.include
    # create a template udhcpd configuration file
    write_udhcpd_conf /mnt/etc/opt/openslx/udhcpd.qemukvm

    # copy the runlevel script (proper place for all distros??)
    cp /mnt/opt/openslx/plugin-repo/qemukvm/qemukvm /mnt/etc/init.d
    rllinker "qemukvm" 22 2

    # copy the /etc/qemu-ifup script and enable extended rights for running
    # the emulator and certain network commands via sudo
    cp /mnt/opt/openslx/plugin-repo/qemukvm/qemu-if* /mnt/etc
    chmod 0755 /mnt/etc/qemu-if* /mnt/etc/init.d/qemukvm
    for qemubin in qemu kvm ; do
      qemu="$(binfinder ${qemubin})"
      [ -n "${qemu}" ] && \
        echo "ALL ALL=NOPASSWD: ${qemu}" >>/mnt/etc/sudoers
    done
    echo -e "#ALL ALL=NOPASSWD: /opt/openslx/uclib-rootfs/sbin/tunctl -t tap*\n\
#ALL ALL=NOPASSWD: /opt/openslx/uclib-rootfs/sbin/ip addr add * dev tap*\n\
#ALL ALL=NOPASSWD: /opt/openslx/uclib-rootfs/usr/sbin/brctl addif br0 tap*\n\
ALL ALL=NOPASSWD: /opt/openslx/uclib-rootfs/usr/sbin/udhcpd -S /tmp/qemu*" \
      >>/mnt/etc/sudoers
  fi
else
  [ $DEBUGLEVEL -gt 0 ] && echo "  * Configuration of qemukvm plugin failed"
fi
