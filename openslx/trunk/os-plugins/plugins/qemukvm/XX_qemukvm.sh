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
# script is included from init via the "." load function - thus it has all
# variables and functions available


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
  fi
else
  [ $DEBUGLEVEL -gt 0 ] && echo "  * Configuration of qemukvm plugin failed"
fi
