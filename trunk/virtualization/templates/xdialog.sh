#!/bin/sh

# This script will run Xdialog. menulist-create will add all menu entrys
# from the different .xdialog files
#
#TODO: change path_to_this_script to path of this file. needed, because
#      a return will exit Xdialog


themesdir="/var/lib/openslx/themes"
res=$(xvidtune -show | grep -wo "\".*\"" | sed "s/\"//g") 
if ! [ -f ${themesdir}/bootsplash/images/silent-${res}.jpg ]; then     
  img=$(ls ${themesdir}/bootsplash/images/ | grep -m 1 "silent")
  display -window root ${themesdir}/bootsplash/images/${img}
else
  display -window root ${themesdir}/bootsplash/images/silent-${res}.jpg
fi


$($(which Xdialog) --rc-file /var/lib/openslx/themes/Xdialog/gtkrc \
    --title "Desktop / VMware-ImageMenu" \
    --screen-center \
    --fill --no-wrap \
    --stdout \
    --no-tags \
    --ok-label "START" \
    --item-help \
    --menubox "Please choose the image you would like to run:" \
    35 80 0 \
    "/var/X11R6/bin/xdialog.sh" "No Image - Don't press return too fast" "" \
