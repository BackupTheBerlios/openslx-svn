#! /bin/ash
#
# stage3 part of 'desktop' plugin - the runlevel script
#
. /etc/functions
. /etc/distro-functions
. /etc/sysconfig/config
if [ -e /initramfs/plugin-conf/desktop.conf ]; then
  . /initramfs/plugin-conf/desktop.conf
  if [ $desktop_active -ne 0 ]; then
    [ $DEBUGLEVEL -gt 0 ] && echo "executing the 'desktop' os-plugin ...";
  
    testmkd /mnt/var/lib/openslx/themes
    testmkd /mnt/var/lib/openslx/config

    # problem which occures if exporting was forgotten (quick fix code)
    if [ -e /mnt/opt/openslx/plugin-repo/desktop/${desktop_manager}/desktop.sh ]
      then . /mnt/opt/openslx/plugin-repo/desktop/${desktop_manager}/desktop.sh
    else
      error fatal "This shouldn't fail - you might have forgotten to export \
your system."
    fi

    # TODO: move the following stuff into the gdm-specific desktop.sh
    #       (and perhaps handle through a template?)
    if [ "${desktop_manager}" = "XXXgdm" ]; then
      cp -a /usr/share/themes/gdm /mnt/var/lib/openslx/themes
      sed -i "s,GraphicalThemeDir=.*,GraphicalThemeDir=/var/lib/openslx/themes," \
        /mnt/etc/gdm/gdm.conf
      sed -i "s,GraphicalTheme=.*GraphicalTheme=gdm," /mnt/etc/gdm/gdm.conf
    fi

    if [ "${desktop_manager}" = "XXXkdm" ]; then
      cp -a /usr/share/themes/kdm /mnt/var/lib/openslx/themes
      sed -i "s,Theme=.*,Theme=/var/lib/openslx/themes/kdm," /mnt/etc/kde3/kdm/kdmrc
      sed -i "s,UseTheme=.*,UseTheme=true," /mnt/etc/kde3/kdm/kdmrc
    fi

    [ $DEBUGLEVEL -gt 0 ] && echo "done with 'desktop' os-plugin ...";

  fi
fi
