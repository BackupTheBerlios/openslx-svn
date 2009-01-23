# get an idea of the installed graphics hardware - might be needed if the
# automatic Xorg configation fails in this field. If no useable info was
# detected just delete the file.

# tablet detection function
tabletdetect () {
  sleep 1; waitfor /etc/hwinfo.bios 20000
  # quickhack for IBM X61 tablet detection
  if grep -qi tablet /etc/hwinfo.bios ; then
    echo 'wacomdev="ttyS0"' >/etc/tablet.conf
  fi
  # wacom device attached to usb - code to be tested
  if [ ! -e /etc/tablet.conf ]; then
    if hwinfo --usb | grep -qi tablet ; then
      echo 'wacomdev="input/wacom"' >/etc/tablet.conf
    fi
  fi
}

( hwinfo --gfxcard >/etc/hwinfo.gfxcard ) &
( hwinfo --monitor >/etc/hwinfo.display; grep "Generic Monitor" \
    /etc/hwinfo.display >/dev/null 2>&1 && rm /etc/hwinfo.display ) &
( tabletdetect ) &

