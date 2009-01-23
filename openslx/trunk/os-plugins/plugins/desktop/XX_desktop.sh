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
# stage3 part of 'desktop' plugin - the runlevel script
#
# script is included from init via the "." load function - thus it has all
# variables and functions available

if [ -e /initramfs/plugin-conf/desktop.conf ]; then
  . /initramfs/plugin-conf/desktop.conf
  if [ $desktop_active -ne 0 ]; then
    [ $DEBUGLEVEL -gt 0 ] && echo "executing the 'desktop' os-plugin ...";
  
    testmkd /mnt/var/lib/openslx/themes
    testmkd /mnt/var/lib/openslx/config

    # problem which occurs if exporting was forgotten (quick fix code)
    if [ -e /mnt/opt/openslx/plugin-repo/desktop/${desktop_manager}/desktop.sh ]
      then . /mnt/opt/openslx/plugin-repo/desktop/${desktop_manager}/desktop.sh
    else
      error "This shouldn't fail - you might have forgotten to export \
your system." fatal
    fi

    # TODO: move the following stuff into the gdm-specific desktop.sh
    #       (and perhaps handle through a template?)
    if [ "${desktop_manager}" = "XXXkdm" ]; then
      cp -a /usr/share/themes/kdm /mnt/var/lib/openslx/themes
      sed "s,Theme=.*,Theme=/var/lib/openslx/themes/kdm," \
        -i /mnt/etc/kde3/kdm/kdmrc
      sed "s,UseTheme=.*,UseTheme=true," -i /mnt/etc/kde3/kdm/kdmrc
    fi

    [ $DEBUGLEVEL -gt 0 ] && echo "done with 'desktop' os-plugin ...";

  fi
fi
