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

if [ -e /etc/slxsystem.conf ]; then
  . /etc/slxsystem.conf
fi

# Xorg configuration file location
xfc="/mnt/etc/X11/xorg.conf"
# directory for libGL, DRI library links to point to proper library set
# depending on the hardware environment
glliblinks="/mnt/var/X11R6/lib/"
testmkd ${glliblinks}

# check for the existance of plugin configuration and non-existance of an
# admin provided config file in ConfTGZ
if [ -e /initramfs/plugin-conf/xserver.conf -a \
   ! -f /rootfs/etc/X11/xorg.conf ]; then
  . /initramfs/plugin-conf/xserver.conf
  # check if driver set via xserver_driver
  # if so check for xserver_prefnongpl and xserver_driver because you want to
  # force driver even if xserver_prefnongpl=0
  # eg: [ -n "$xserver_driver" -o "$xserver_prefnongpl" -eq 1 ]
  if [ -n "$xserver_driver" ]; then
    if `grep -qi "Server Module" /etc/hwinfo.gfxcard`; then
      sed -i "s,XFree86.*,FORCED XFree86 v4 Server Module: ${xserver_driver}," \
        /etc/hwinfo.gfxcard
      echo -e "\n# File modified by $1" >> /etc/hwinfo.gfxcard
      echo "# Reason: attribute server_driver set to ${xserver_driver}" \
        >> /etc/hwinfo.gfxcard
	else
	  echo -e "\n# File modified by $1" >> /etc/hwinfo.gfxcard
	  echo "# Reason: attribute server_driver set to ${xserver_driver}" \
        >> /etc/hwinfo.gfxcard
      echo "FORCED XFree86 v4 Server Module: ${xserver_driver}" >> /etc/hwinfo.gfxcard
    fi
  fi
  # do not start any configuration if the admin provided a preconfigured
  # xorg.conf in /rootfs/etc/X11/xorg.conf
  if [ $xserver_active -ne 0 -a ! -f /rootfs/${xfc#/mnt} ]; then
    [ $DEBUGLEVEL -gt 0 ] && echo "executing the 'xserver' os-plugin ...";
    xmodule=$(grep -i -m 1 "XFree86 v4 Server Module" /etc/hwinfo.gfxcard | \
      sed "s/.*v4 Server Module: //")
    # proprietary ATI/NVidia modules listed a different way with hwinfo
    [ -z "$xmodule" ] || error "${hcfg_hwsetup}" nonfatal

    ######################################################################
    # begin proprietary drivers section (xorg.conf part)
    ######################################################################

	
	if $(grep -iq -m 1 'Module: fglrx' /etc/hwinfo.gfxcard) && \
      [ -n "$xserver_driver" -o "$xserver_prefnongpl" -eq 1 ]
    then
      # we have an ati card here
      PLUGIN_ROOTFS="/opt/openslx/plugin-repo/xserver/ati"
	  if [  -f /mnt${PLUGIN_ROOTFS}/usr/X11R6/lib/dri/fglrx_dri.so -o \
		   -f /mnt${PLUGIN_ROOTFS}/usr/lib/dri/fglrx_dri.so ]; then

	      # this will be written before standard module path into xorg.conf
	      MODULE_PATH="${PLUGIN_ROOTFS}/usr/lib/xorg/modules/\,\
${PLUGIN_ROOTFS}/usr/X11R6/lib/modules/\,"
	      xmodule="fglrx"
	      PLUGIN_PATH="/mnt/${PLUGIN_ROOTFS}"

          # impossible to load it directly via stage3 insmod - yes, somehow this is too big
          chroot /mnt /sbin/insmod ${PLUGIN_ROOTFS}/modules/fglrx.ko

          #  workaround for bug #453 (for some ati graphics cards)
          if [ $? -gt 0 -a "${slxconf_distro_name}" = "ubuntu" ]; then
            xmodule="radeon"
            MODULE_PATH="/usr/lib/xorg/modules/,/usr/X11R6/lib/xorg/modules/"
          else

	      # we need some database for driver initialization
	      cp -r "${PLUGIN_PATH}/etc/ati" /mnt/etc

          if [ "${slxconf_distro_name}" = "ubuntu" ]; then
            echo "${PLUGIN_ROOTFS}/usr/lib/libGL.so.1" >> /mnt/etc/ld.so.preload
          fi
	
	      # if fglrx_dri.so is linked wrong -> we have to link it here
	      if [ "1" -eq "$( ls -l /mnt/usr/lib/dri/fglrx_dri.so \
	        | grep -o "/var/X11R6.*so$" | wc -l )" ]; then
	          ln -s ${PLUGIN_ROOTFS}/usr/lib/dri/fglrx_dri.so \
	            ${glliblinks}dri/fglrx_dri.so
	      fi
              BUSID=$(grep -m1 -i " SysFS BusID: .*" /etc/hwinfo.gfxcard | \
                awk -F':' '{print "PCI:"$3":"$4}' | sed -e 's,\.,:,g')
	      echo -e "\t${PLUGIN_ROOTFS}/usr/bin/aticonfig --initial &>/dev/null"\
                >> /mnt/etc/init.d/boot.slx
	      ATI=1
          fi # if kernel module not loaded properly
	  fi
    elif $(grep -iq -m 1 'Module: nvidia' /etc/hwinfo.gfxcard) && \
      [ -n "$xserver_driver" -o "$xserver_prefnongpl" -eq 1 ]
    then
      # we have an nvidia card here
      NVIDIA=1
      PLUGIN_ROOTFS="/opt/openslx/plugin-repo/xserver/nvidia"
      MODULE_PATH="${PLUGIN_ROOTFS}/usr/lib/xorg/modules/\,\
${PLUGIN_ROOTFS}/usr/X11R6/lib/modules/\,"
      xmodule="nvidia"
      PLUGIN_PATH="/mnt${PLUGIN_ROOTFS}"

      # if we can't find the nongpl kernel module, use gpl xorg
      # nvidia driver
      if [ -e ${PLUGIN_PATH}/modules/nvidia.ko ]; then
        # sometimes the kernel module needs agpgart
        modprobe agpgart
        # insert kernel driver
        chroot /mnt /sbin/insmod ${PLUGIN_ROOTFS}/modules/nvidia.ko


        #  workaround for bug #453 (Xorg does not start with ld.so.preload)
        if [ "${slxconf_distro_name}" = "ubuntu" -a "${xmodule}" != "nvidia" ]; then
          echo "${PLUGIN_ROOTFS}/usr/lib/libGL.so.1" >> /mnt/etc/ld.so.preload
        fi

      else
         xmodule="nv"
      fi

    fi

    ######################################################################
    # end proprietary drivers xorg.conf section
    ######################################################################


    echo -e "# ${xfc#/mnt*}\n# autogenerated X hardware configuration by the \
xserver plugin in OpenSLX stage3\n# DO NOT EDIT THIS FILE BUT THE PLUGIN \
INSTEAD" > $xfc
    echo '
Section "Files"
# ModulePath "/usr/lib/xorg/modules/,/usr/lib64/xorg/modules/"
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
  Identifier   "Generic Keyboard"
  Driver       "kbd"
  Option       "CoreKeyboard"
  Option       "XkbRules"          "xorg"
  Option       "XkbModel"          "pc105"
  Option       "XkbLayout"         "us"
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
Section "Device"
  Identifier   "Generic Video Card"
  Driver       "vesa"
# BusID        "PCI:xx" #especially needed for fglrx
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
EndSection
Section "DRI"
  Mode    0666
EndSection' >> $xfc
    # keyboard setup (fill XKEYBOARD)
    localization "${country}"
    # if no module was detected, stick to vesa module
    if [ -n "$xmodule" ] ; then
      sed "s/vesa/$xmodule/;s/\"us\"/\"${XKEYBOARD}\"/" -i $xfc
    else
      sed "s/\"us\"/\"${XKEYBOARD}\"/" -i $xfc
    fi

    if [ -n "${BUSID}" ]; then
      sed -e "s,^#.*BusID .*,  BusID \"${BUSID}\",g" -i ${xfc}
    fi

    # set nodeadkeys for special layouts
    if [ ${XKEYBOARD} = "de" ]; then
      sed -e '/\"XkbLayout\"/a\\ \ Option       "XkbVariant"        "nodeadkeys"' \
          -i $xfc
    fi
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

    # ModulePath for proprietary drivers (otherwise disabled)
    if [ -n "$xserver_driver" -o "$xserver_prefnongpl" -eq "1" ]; then
      sed -e "s,# ModulePath \",  ModulePath \"${MODULE_PATH},g" \
          -i $xfc
    fi

    ############################################
    # Copy the appropriate ld.so.cache file
    ############################################
    if [ "${xmodule}" = "fglrx" -o  "${xmodule}" = "nvidia" ]; then
      cp ${PLUGIN_PATH}/ld.so.cache /mnt/etc/ld.so.cache

      # just in case somebody needs to run ldconfig - insert GL-Libs at the beginning
      sed -e "1s,^,include ${PLUGIN_ROOTFS}/ld.so.conf\n,g" -i /mnt/etc/ld.so.conf 

      if [ "${xmodule}" = "nvidia" ]; then
        sed -i "s,\(Driver.*\"nvidia\"\),\1\n  Option \"NoLogo\" \"True\"," $xfc
      fi
    fi
 
    # check if tablet hardware available, read device information from file
    if [ -e /etc/tablet.conf ]; then
      . /etc/tablet.conf
      echo -e 'Section "InputDevice"
  Driver       "wacom"
  Identifier   "Stylus"
  Option       "Device"            "/dev/input/wacom"
  Option       "Type"              "stylus"
  Option       "ForceDevice"       "ISDV4"         # Tablet PC ONLY
EndSection
Section "InputDevice"
  Driver       "wacom"
  Identifier   "Pad"
  Option       "Device"            "/dev/input/wacom"
  Option       "Type"              "pad"
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
EndSection' >> ${xfc}
      sed -e "s,/dev/input/wacom,/dev/${wacomdev}," \
          -e '/e  \"Generic Mouse\"/a\\ \ InputDevice  "Stylus"            "SendCoreEvents"' \
          -e '/e  \"Generic Mouse\"/a\\ \ InputDevice  "Pad"               "SendCoreEvents"' \
          -e '/e  \"Generic Mouse\"/a\\ \ InputDevice  "Cursor"            "SendCoreEvents"' \
          -e '/e  \"Generic Mouse\"/a\\ \ InputDevice  "Eraser"            "SendCoreEvents"' \
          -i ${xfc}
    fi

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
      modes=$(grep -i "Resolution: .*@" /etc/hwinfo.display | \
        awk '{print $2}'| sort -unr| awk -F '@' '{print "\"" $1 "\""}'|\
        tr "\n" " ")
      [ -n "$vert" -a -n "$horz" ] && \
        sed -e "s|# Horizsync.*|  Horizsync    $horz|;\
                s|# Vertrefre.*|  Vertrefresh  $vert|;\
                s|# Modelname.*|  Modelname    \"$modl\"|" -i $xfc
      [ -n "$size" ] && \
        sed -e "s|# DisplaySi.*|  DisplaySize  $size|" -i $xfc
      [ -n "$modes" ] && \
        sed -e "s|# SubSection.*|  SubSection \"Display\"|;\
                s|#   Depth        24.*|    Depth        24|;\
                s|#   Modes.*|    Modes	$modes|;\
                s|# EndSubSection.*|  EndSubSection|;" -i $xfc

    fi
    # run distro specific generated stage3 script
    [ -e /mnt/opt/openslx/plugin-repo/xserver/xserver.sh ] && \
      . /mnt/opt/openslx/plugin-repo/xserver/xserver.sh

    [ $DEBUGLEVEL -gt 0 ] && echo "done with 'xserver' os-plugin ..."

  fi
elif [ ! -e /initramfs/plugin-conf/xserver.conf ]; then
  [ $DEBUGLEVEL -gt 2 ] && \
    echo "No configuration file found for xserver plugin."
fi
