#!/bin/ash
# get an idea of the installed graphics hardware - might be needed if the
# automatic Xorg configation fails in this field. If no useable info was
# detected just delete the file.

( hwinfo --monitor >/etc/hwinfo.display; grep "Generic Monitor" \
    /etc/hwinfo.display >/dev/null 2>&1 && rm /etc/hwinfo.display ) &

