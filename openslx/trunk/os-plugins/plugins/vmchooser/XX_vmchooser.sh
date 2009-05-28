# Copyright (c) 2008, 2009 - RZ Uni Freiburg
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

CONFFILE="/initramfs/plugin-conf/vmchooser.conf"

if [ -e $CONFFILE ]; then
  . $CONFFILE
  if [ $vmchooser_active -ne 0 ] ; then
    [ $DEBUGLEVEL -gt 0 ] && echo "vmchooser: copying default .desktop file ..."
    # we expect to have this directory to be interpreted by gdm/kdm
    testmkd /mnt/etc/X11/sessions
    cp /mnt/opt/openslx/plugin-repo/vmchooser/default.desktop \
      /mnt/etc/X11/sessions/
    testmkd /mnt/etc/opt/openslx
    cp $CONFFILE /mnt/etc/opt/openslx/vmchooser-stage3.conf

	testmkd /mnt/var/X11R6/bin
    cp /mnt/opt/openslx/plugin-repo/vmchooser/run-virt.sh \
	  /mnt/var/X11R6/bin

    # setup all generic virtualization / starting stuff like the floppy image
    testmkd /mnt/var/lib/virt/vmchooser/fd-loop 1777
    testmkd /mnt/var/lib/virt/vmchooser/loopimg

    # loop file for exchanging information between linux and vm guest
    if modprobe ${MODPRV} loop; then
      mdev -s
    else
      : #|| error "" nonfatal
    fi
    # mount a clean tempfs (bug in UnionFS prevents loopmount to work)
    strinfile "unionfs" /proc/mounts && \
      mount -n -o size=1500k -t tmpfs vm-loopimg /mnt/var/lib/virt/vmchooser/loopimg
    # create an empty floppy image of 1.4MByte size
    dd if=/dev/zero of=/mnt/var/lib/virt/vmchooser/loopimg/fd.img \
      count=2880 bs=512 2>/dev/null
    chmod 0777 /mnt/var/lib/virt/vmchooser/loopimg/fd.img
    # use dos formatter copied into stage3
    mkdosfs /mnt/var/lib/virt/vmchooser/loopimg/fd.img >/dev/null 2>&1 #|| error
    mount -n -t msdos -o loop,umask=000 /mnt/var/lib/virt/vmchooser/loopimg/fd.img \
      /mnt/var/lib/virt/vmchooser/fd-loop

    waitfor /etc/hwinfo.cdrom
    j=0
    for i in $(cat /etc/hwinfo.cdrom); do
      echo "cdrom_$j=$i" >> /mnt/etc/opt/openslx/run-virt.include
      j=$(expr $j + 1)
    done

    waitfor /etc/hwinfo.floppy
    j=0
    for i in $(cat /etc/hwinfo.floppy); do
      echo "floppy_$j=$i" >> /mnt/etc/opt/openslx/run-virt.include
      j=$(expr $j + 1)
    done

    # finished ...
    [ $DEBUGLEVEL -gt 0 ] && echo "done with 'vmchooser' os-plugin ..."
  fi
fi
