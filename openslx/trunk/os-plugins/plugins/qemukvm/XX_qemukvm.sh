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


# check if the configuration file is available
if [ -e /initramfs/plugin-conf/qemukvm.conf ]; then

  # load needed variables
  . /initramfs/plugin-conf/qemukvm.conf

  # Test if this plugin is activated... more or less useless with the
  # new plugin system
  if [ $qemukvm_active -ne 0 ]; then

    [ $DEBUGLEVEL -gt 0 ] && echo "executing the 'qemukvm' os-plugin ...";
    # Load general configuration
    . /initramfs/machine-setup

    # get source of qemukvm image server (get type, server and path)
    if strinstr "/" "${qemukvm_imagesrc}" ; then
      qkimgprot=$(uri_token ${qemukvm_imagesrc} prot)
      qkimgserv=$(uri_token ${qemukvm_imagesrc} server)
      qkimgpath="$(uri_token ${qemukvm_imagesrc} path)"
    fi
    if [ -n "${qkimgserv}" ] ; then
      # directory where qemu images are expected in
      testmkd /mnt/var/lib/qemukvm
      case "${qkimgprot}" in
        *nbd)
          # TODO: to be filled in ...
          ;;
        lbdev)
          # we expect the stuff on toplevel directory, filesystem type should be
          # autodetected here ... (vmimgserv is blockdev here)
          qkbdev=/dev/${qkimgserv}
          waitfor ${qkbdev} 20000
          echo -e "ext2\nreiserfs\nvfat\nxfs" >/etc/filesystems
          mount -o ro ${qkbdev} /mnt/var/lib/qemukvm || \
            error "$scfg_evmlm" nonfatal
          ;;
        *)
          # we expect nfs mounts here ...
          for proto in tcp udp fail; do
            [ $proto = "fail" ] && { error "$scfg_nfs" nonfatal;
            noimg=yes; break;}
          mount -n -t nfs -o ro,nolock,$proto ${qkimgserv}:${qkimgpath} \
            /mnt/var/lib/qemukvm && break
          done
          ;;
      esac
    fi

  fi
else
  [ $DEBUGLEVEL -gt 0 ] && echo "  * Configuration of qemukvm plugin failed"
fi
