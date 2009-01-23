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

# get an idea of the installed graphics hardware - might be needed if the
# automatic Xorg configation fails in this field. If no useable info was
# detected just delete the file.

# tablet detection function
tabletdetect () {
  sleep 1; waitfor /etc/hwinfo.bios 20000
  # quickhack for IBM X61/ACER tablet detection (some kind of positive list
  # or external admin configurable file needed)
  if grep -qiE "tablet|TravelMate C200" /etc/hwinfo.bios ; then
    echo 'wacomdev="ttyS0"' >/etc/tablet.conf
  fi
  # wacom device attached to usb - code to be tested
  if [ ! -e /etc/tablet.conf ]; then
    if hwinfo --usb | grep -qiE "wacom|tablet" ; then
      echo 'wacomdev="input/wacom"' >/etc/tablet.conf
    fi
  fi
}

( hwinfo --gfxcard >/etc/hwinfo.gfxcard ) &
( hwinfo --monitor >/etc/hwinfo.display; grep "Generic Monitor" \
    /etc/hwinfo.display >/dev/null 2>&1 && rm /etc/hwinfo.display ) &
( tabletdetect ) &

