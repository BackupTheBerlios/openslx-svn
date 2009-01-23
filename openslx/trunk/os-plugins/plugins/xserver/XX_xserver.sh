# Copyright (c) 2008 - RZ Uni Freiburg
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
# stage3 part of 'xserver' plugin - the runlevel script setting up the Xorg
# configuration and checking for 3D capabilities and non-gpl drivers
#
# script is included from init via the "." load function - thus it has all
# variables and functions available

# read the central configuration file (fixme: should the keyboard layout
# defined within the xserver plugin settings - probably not, dvs)
if [ -e /initramfs/machine-setup ] ; then
  . /initramfs/machine-setup
else
  error "  The central configuration file 'machine-setup' (produced by the \
slxconfig-demuxer\n  and transported via fileget) is not present" nonfatal
fi

xfc="/mnt/etc/X11/xorg.conf"

if [ -e /initramfs/plugin-conf/xserver.conf ]; then
  . /initramfs/plugin-conf/xserver.conf
  # keyboard setup
  localization "${country}"
  # do not start any configuration if the admin provided a preconfigured
  # xorg.conf in /rootfs/etc/X11/xorg.conf
  if [ $xserver_active -ne 0 -a ! -f /rootfs/${xfc#/mnt} ]; then
    [ $DEBUGLEVEL -gt 0 ] && echo "executing the 'xserver' os-plugin ...";
    xmodule=$(grep -i -m 1 "XFree86 v4 Server Module" /etc/hwinfo.data | \
      sed "s/.*v4 Server Module: //")
    # proprietary ATI/NVidia modules listed a different way with hwinfo
    [ -z "$xmodule" ] || error "${hcfg_hwsetup}" nonfatal
    set -x

    if [ $(grep -i -m 1 'Driver Activation Cmd: "modprobe fglrx"' \
        /etc/hwinfo.data | wc -l) -eq "1"  -a $xserver_prefnongpl -eq 1 ]
    then
      # we have an ati card here
      ATI=1
      MODULE_PATH="/opt/openslx/plugin-repo/xserver/ati/usr/lib/xorg/modules/\,\
/opt/openslx/plugin-repo/xserver/ati/usr/X11R6/lib/modules/\,"
      xmodule="fglrx"
      LINKAGE="/mnt/var/lib/X11R6/xserver/usr/lib/"
      cp -r /mnt/opt/openslx/plugin-repo/xserver/ati/etc/* /mnt/etc/
      ln -s \
      /mnt/opt/openslx/plugin-repo/xserver/ati/usr/lib/libGL.so.1.2 \
      ${LINKAGE}libGL.so.1
      ln -s \
      /mnt/opt/openslx/plugin-repo/xserver/ati/usr/lib/libGL.so.1.2 \
      ${LINKAGE}libGL.so.1.2
      
      # TODO: This is probably Ubuntu-specific
      echo "/opt/openslx/plugin-repo/xserver/ati/usr/lib/\n\
/opt/openslx/plugin-repo/xserver/ati/usr/X11R6/lib/" \
      > /mnt/etc/ld.so.conf.d/999opengl.conf
      ldsc="1" # regenerate ld.so.cache
    fi

    set +x

    # TODO: nvidia module

    echo -e "# $xfc\n# autogenerated X hardware configuration by the xserver \
plugin in OpenSLX stage3\n# DO NOT EDIT THIS FILE BUT THE PLUGIN INSTEAD" \
      > $xfc
    echo '
Section "Files"
  ModulePath "/usr/lib/xorg/modules/"
EndSection
Section "ServerFlags"
  Option       "AllowMouseOpenFail"
  Option       "blank time"        "5"
  Option       "standby time"      "10"
  Option       "suspend time"      "15"
  Option       "off time"          "20"
EndSection
Section "Module"
  Load         "i2c"
  Load         "bitmap"
  Load         "ddc"
  Load         "extmod"
  Load         "freetype"
  Load         "int10"
  Load         "vbe"
  Load         "glx"
  Load         "dri"
EndSection
Section "InputDevice"
  Identifier "Generic Keyboard"
  Driver       "kbd"
  Option       "CoreKeyboard"
  Option       "XkbRules"          "xorg"
  Option       "XkbModel"          "pc105"
  Option       "XkbLayout"         "us"
  Option       "XkbVariant"        "nodeadkeys"
EndSection
Section "InputDevice"
  Identifier   "Generic Mouse"
  Driver       "mouse"
# Option       "Device"            "/dev/input/mice"
# Option       "Protocol"          "ImPS/2"
# Option       "ZAxisMapping"      "4 5"
# Option       "Emulate3Buttons"   "true"
  Option       "CorePointer"
EndSection
Section "InputDevice"
  Driver       "wacom"
  Identifier   "Stylus"
  Option       "Device"            "/dev/input/wacom"
  Option       "Type"              "stylus"
  Option       "ForceDevice"       "ISDV4"         # Tablet PC ONLY
EndSection
Section "InputDevice"
  Driver       "wacom"
  Identifier   "Eraser"
  Option       "Device"            "/dev/input/wacom"
  Option       "Type"              "eraser"
  Option       "ForceDevice"       "ISDV4"         # Tablet PC ONLY
EndSection
Section "InputDevice"
  Driver       "wacom"
  Identifier   "Cursor"
  Option       "Device"            "/dev/input/wacom"
  Option       "Type"              "cursor"
  Option       "ForceDevice"       "ISDV4"         # Tablet PC ONLY
EndSection
Section "Device"
  Identifier   "Generic Video Card"
  Driver       "vesa"
EndSection
Section "Monitor"
  Identifier   "Generic Display"
  Option       "DPMS"
# Modelname    "could be enabled via xserver::ddcinfo attribute"
# Vertrefresh  ...
# Horizsync    ...
# DisplaySize  ...
EndSection
Section "Screen"
  Identifier   "Default Screen"
  Device       "Generic Video Card"
  Monitor      "Generic Display"
  DefaultDepth 24
# SubSection "Display"
#   Depth        24
#   Modes        "1024x768" "800x600"
# EndSubSection
EndSection
Section "ServerLayout"
  Identifier   "Default Layout"
  Screen       "Default Screen"
  InputDevice  "Generic Keyboard"
  InputDevice  "Generic Mouse"
  InputDevice  "Stylus"            "SendCoreEvents"
  InputDevice  "Cursor"            "SendCoreEvents"
  InputDevice  "Eraser"            "SendCoreEvents"
EndSection
Section "DRI"
  Mode    0666
EndSection
'   >> $xfc
    # if no module was detected, stick to vesa module
    if [ -n "$xmodule" ] ; then
      sed "s/vesa/$xmodule/;s/\"us\"/\"${XKEYBOARD}\"/" -i $xfc
    else
      sed "s/\"us\"/\"${XKEYBOARD}\"/" -i $xfc
    fi
    # these directories might be distro specific
    for file in /var/lib/xkb/compiled ; do
      testmkd /mnt/${file}
    done
    # if a synaptic touchpad is present, add it to the device list
    if grep -q -E "ynaptics" /etc/hwinfo.mouse || \ 
       dmesg | grep -q -E "ynaptics" ; then
      sed -e '/\"CorePointer\"/ {
a\
EndSection\
Section "InputDevice"\
  Identifier   "Synaptics TP"\
  Driver       "synaptics"\
  Option       "Device"            "/dev/input/mice"\
  Option       "SendCoreEvents"    "true"
}' -e '/Device  "Generic Mouse"/ {
a\ \ InputDevice\ \ "Synaptics TP"\ \ \ \ \ \ "SendCoreEvents"
}'    -i $xfc
    fi


    if [ "$xserver_prefnongpl" -eq "1" ]; then
      sed -e "s,ModulePath \",ModulePath \"${MODULE_PATH},g" \
          -i $xfc
    fi

    [ $DEBUGLEVEL -gt 0 ] && echo "done with 'xserver' os-plugin ...";
    # some configurations produce no proper screen resolution without
    # Horizsync and Vertrefresh set (more enhancements might be needed for
    # really old displays like CRTs)
    if [ $xserver_ddcinfo -ne 0 ] ; then
      # read /etc/hwinfo.display started at "runinithook '00-started'"
      vert=$(grep -m 1 "Vert.*Range:" /etc/hwinfo.display | \
        sed 's|.*Range:\ ||;s|\ Hz||')
      horz=$(grep -m 1 "Hor.*Range:" /etc/hwinfo.display | \
        sed 's|.*Range:\ ||;s|\ kHz||')
      modl=$(grep -m 1 " Model: " /etc/hwinfo.display | \
        sed 's|.*Model:\ ||;s|"||g')
      size="$(grep -m 1 " Size: " /etc/hwinfo.display | \
        sed 's|.*ize:\ ||;s|\ mm||;s|x|\ |')"
      [ -n "$vert" -a -n "$horz" ] && \
        sed -e "s|# Horizsync.*|  Horizsync    $horz|;\
                s|# Vertrefre.*|  Vertrefresh  $vert|;\
                s|# Modelname.*|  Modelname    \"$modl\"|" -i $xfc
      [ -n "$size" ] && \
        sed -e "s|# DisplaySi.*|  DisplaySize  $size|" -i $xfc
    fi
    # run distro specific generated stage3 script
    [ -e /mnt/opt/openslx/plugin-repo/xserver/xserver.sh ] && \
      . /mnt/opt/openslx/plugin-repo/xserver/xserver.sh
  fi
fi
