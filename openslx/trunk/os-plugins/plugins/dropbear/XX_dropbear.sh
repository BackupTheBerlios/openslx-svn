
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
# stage3 part of 'dropbear' plugin - the runlevel script
#
# script is included from init via the "." load function - thus it has all
# variables and functions available

if [ -e /initramfs/plugin-conf/dropbear.conf ]; then
  . /initramfs/plugin-conf/dropbear.conf
  if [ $dropbear_active -ne 0 ]; then
    [ $DEBUGLEVEL -gt 0 ] && echo "executing the 'dropbear' os-plugin ...";

       # setup links to multibinary
       ln -sf /mnt/opt/openslx/plugin-repo/dropbear/dropbearmulti /sbin/dropbear
       ln -sf /mnt/opt/openslx/plugin-repo/dropbear/dropbearmulti /sbin/dropbearkey
       ln -sf /mnt/opt/openslx/plugin-repo/dropbear/dropbearmulti /sbin/dropbearconvert
       ln -sf /mnt/opt/openslx/plugin-repo/dropbear/dropbearmulti /bin/dbclient
       ln -sf /mnt/opt/openslx/plugin-repo/dropbear/dropbearmulti /bin/scp

       # create dropbear config dir
       mkdir -p /etc/dropbear
       
       # convert openssh rsa key to dropbear key - if available
       if [ -e /mnt/etc/ssh/ssh_host_rsa_key ]
         dropbearconvert openssh dropbear /mnt/etc/ssh/ssh_host_rsa_key \
           /etc/dropbear/dropbear_rsa_host_key
       else 
         dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key
       fi
  
       /sbin/dropbear 

    [ $DEBUGLEVEL -gt 0 ] && echo "done with 'dropbear' os-plugin ...";

  fi
fi
