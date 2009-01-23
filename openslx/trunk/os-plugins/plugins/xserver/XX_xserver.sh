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

xfc="/mnt/etc/X11/xorg.conf"

if [ -e /initramfs/plugin-conf/xserver.conf ]; then
  . /initramfs/plugin-conf/xserver.conf
  # do not start any configuration if the admin provided a preconfigured
  # xorg.conf in /rootfs/etc/X11/xorg.conf
  if [ $xserver_active -ne 0 -a ! -f /rootfs/${xfc#/mnt} ]; then
    [ $DEBUGLEVEL -gt 0 ] && echo "executing the 'xserver' os-plugin ...";
    xmodule=$(grep -i -m 1 "XFree86 v4 Server Module" /etc/hwinfo.data | \
      sed "s/.*v4 Server Module: //")
    [ -z "$xmodule" ] || error "${hcfg_hwsetup}" nonfatal
    echo -e "# $xfc\n# autogenerated X hardware configuration by the xserver \
plugin in OpenSLX stage3\n# DO NOT EDIT THIS FILE BUT THE PLUGIN INSTEAD" \
      > $xfc
    echo '
Section "Files"
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
  Option       "XkbLayout"         "XKEYBOARD"
  Option       "XkbVariant"        "nodeadkeys"
EndSection
Section "InputDevice"
  Identifier   "Generic Mouse"
  Driver       "mouse"
  Option       "CorePointer"
  Option       "Device"            "/dev/input/mice"
  Option       "Protocol"          "ImPS/2"
  Option       "ZAxisMapping"      "4 5"
  Option       "Emulate3Buttons"   "true"
EndSection
Section "InputDevice"
  Driver       "wacom"
  Identifier   "stylus"
  Option       "Device"            "/dev/input/wacom"
  Option       "Type"              "stylus"
  Option       "ForceDevice"       "ISDV4"         # Tablet PC ONLY
EndSection
Section "InputDevice"
  Driver       "wacom"
  Identifier   "eraser"
  Option       "Device"            "/dev/input/wacom"
  Option       "Type"              "eraser"
  Option       "ForceDevice"       "ISDV4"         # Tablet PC ONLY
EndSection
Section "InputDevice"
  Driver       "wacom"
  Identifier   "cursor"
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
EndSection
Section "Screen"
  Identifier   "Default Screen"
  Device       "Generic Video Card"
  Monitor      "Generic Display"
  DefaultDepth 24
  SubSection "Display"
    Depth        24
    Modes        "1024x768" "800x600"
  EndSubSection
EndSection
Section "ServerLayout"
  Identifier   "Default Layout"
  Screen       "Default Screen"
  InputDevice  "Generic Keyboard"
  InputDevice  "Generic Mouse"
  InputDevice  "stylus"            "SendCoreEvents"
  InputDevice  "cursor"            "SendCoreEvents"
  InputDevice  "eraser"            "SendCoreEvents"
EndSection
Section "DRI"
  Mode    0666
EndSection
'   >> $xfc
    sed "s/vesa/$xmodule/" -i $xfc

    [ $DEBUGLEVEL -gt 0 ] && echo "done with 'xserver' os-plugin ...";
  fi
fi
