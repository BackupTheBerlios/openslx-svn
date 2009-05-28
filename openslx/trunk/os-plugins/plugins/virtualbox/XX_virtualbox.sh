# Copyright (c) 2009 - OpenSLX GmbH
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
if [ -e /initramfs/plugin-conf/virtualbox.conf ]; then

  # load needed variables
  . /initramfs/plugin-conf/virtualbox.conf

  # Test if this plugin is activated... more or less useless with the
  # new plugin system
  if [ $virtualbox_active -ne 0 ]; then

    [ $DEBUGLEVEL -gt 0 ] && echo "executing the 'virtualbox' os-plugin ...";
    # load general configuration
    . /initramfs/machine-setup

    # get source of virtualbox image server (get type, server and path)
    if strinstr "/" "${virtualbox_imagesrc}" ; then
      vbimgprot=$(uri_token ${virtualbox_imagesrc} prot)
      vbimgserv=$(uri_token ${virtualbox_imagesrc} server)
      vbimgpath="$(uri_token ${virtualbox_imagesrc} path)"
    fi
    if [ -n "${vbimgserv}" ] ; then
      # directory where qemu images are expected in
      testmkd /mnt/var/lib/virt/virtualbox
      case "${vbimgprot}" in
        *nbd)
          # TODO: to be filled in ...
          ;;
        lbdev)
          # we expect the stuff on toplevel directory, filesystem type should be
          # autodetected here ... (vbimgserv is blockdev here)
          vbbdev=/dev/${vbimgserv}
          waitfor ${vbbdev} 20000
          echo -e "ext2\nreiserfs\nvfat\nxfs" >/etc/filesystems
          mount -o ro ${vbbdev} /mnt/var/lib/virt/virtualbox || \
            error "$scfg_evmlm" nonfatal
          ;;
        *)
          # we expect nfs mounts here ...
          for proto in tcp udp fail; do
            [ $proto = "fail" ] && { error "$scfg_nfs" nonfatal;
            noimg=yes; break;}
          mount -n -t nfs -o ro,nolock,$proto ${vbimgserv}:${vbimgpath} \
            /mnt/var/lib/virt/virtualbox && break
          done
          ;;
      esac
    fi
    # copy version depending files - the vmchooser expects for every virtua-
    # lization plugin a file named after it (here run-virtualbox.include)
    testmkd /mnt/etc/opt/openslx
    cp /mnt/opt/openslx/plugin-repo/virtualbox/run-virt.include \
      /mnt/etc/opt/openslx/run-virtualbox.include

  fi
else
  [ $DEBUGLEVEL -gt 0 ] && echo "  * Configuration of virtualbox plugin failed"
fi
