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

# check if the plugin config directory is generally available or if the client
# configuration failed somehow
[ -d /initramfs/plugin-conf ] && error "${init_picfg}" nonfatal

if [ -e /initramfs/plugin-conf/x11vnc.conf ]; then
  . /initramfs/plugin-conf/x11vnc.conf
  if [ $x11vnc_active -ne 0 ]; then
    [ $DEBUGLEVEL -gt 0 ] && echo "executing the 'x11vnc' os-plugin ...";
    # create config dir for stage 3
    mkdir -p /mnt/etc/x11vnc  
    # default parameters
    PARAMS="-bg -forever"
    # client restrictions
    if [ -z x11vnc_allowed_hosts ]; then
      PARAMS="$PARAMS -allow $x11vnc_allowd_hosts"
    fi
    # mode
      case "$x11vnc_mode" in
        x11)
          PARAMS="$PARAMS -display :0"
          X11VNC_X11=1
        ;;
        fb)
          PARAMS="$PARAMS -rawfb console"
        ;;
      esac
      # auth type
      case "$x11vnc_auth_type" in
        passwd)
          # use x11vnc passwd style - recommended
          echo "$x11vnc_pass" > /mnt/etc/x11vnc/passwd
          echo "__BEGIN_VIEWONLY__" >> /mnt/etc/x11vnc/passwd
          echo "$x11vnc_viewonlypass" >> /mnt/etc/x11vnc/passwd
          # multiuser handling
          sed -i "s/,/\n/" /mnt/etc/x11vnc/passwd
          # add parameter to commandline  
          PARAMS="$PARAMS -passwdfile rm:/etc/x11vnc/passwd"
        ;;
        rfbauth)
          # use rfbauth
          vncpasswd "$x11vnc_pass" > /mnt/etc/x11vnc/passwd
          PARAMS="$PARAMS -rfbauth /etc/x11vnc/passwd"
        ;;
        *)
          # no password
          PARAMS="$PARAMS -nopw"
        ;;
      esac

      # force viewonly
      if [ "$x11vnc_force_viewonly" = "1" \
        -o "$x11vnc_force_viewonly" = "yes" ]; then
        PARAMS="$PARAMS -viewonly" 
      fi

     # force localhost
     if [ "$x11vnc_force_localhost" = "1" \
       -o "$x11vnc_force_localhost" = "yes" ]; then
       PARAMS="$PARAMS -localhost" 
     fi

     # enable logging
     if [ "$x11vnc_logging" = "1" -o "$x11vnc_logging" = "yes" ]; then
       PARAMS="$PARAMS -o /var/log/x11vnc.log" 
     fi

     # shared desktops
    if [ "$x11vnc_shared" = "1" -o  "$x11vnc_shared" = "yes" ]; then
      PARAMS="$PARAMS -shared" 
    fi

    # scale desktop
    if [ "$x11vnc_scale" != "" ]; then
      $PARAMS="$PARAMS -scale $x11vnc_scale"
    fi

    # write config file
    echo "# parameters generated by $0" > /mnt/etc/x11vnc/x11vnc.conf
    echo "X11VNC_PARAMS=\"$PARAMS\"" >> /mnt/etc/x11vnc/x11vnc.conf
    echo "X11VNC_X11=\"$X11VNC_X11\"" >> /mnt/etc/x11vnc/x11vnc.conf

    rllinker "x11vnc" 30 10

    [ $DEBUGLEVEL -gt 0 ] && echo "done with 'x11vnc' os-plugin ...";
  fi
fi
