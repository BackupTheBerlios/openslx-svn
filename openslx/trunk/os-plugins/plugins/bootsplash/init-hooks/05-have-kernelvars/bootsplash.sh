# splashy depends on /proc/fb with VESA
# only activate with kernel option quiet and no debuglevel
if grep -E "(VESA|VGA)" /proc/fb > /dev/null 2>&1 \
  && grep -qie " quiet " -qie "^quiet " -qie " quiet$" /proc/cmdline \
    > /dev/null 2>&1 \
  && [ $DEBUGLEVEL -eq 0 ] \
  && [ -e /bin/splashy ] ; then
    export no_bootsplash=0
else
  export no_bootsplash=1
fi

if [ ${no_bootsplash} -eq 0 ]; then
  /bin/splashy boot 2>/dev/null
  # add splashy.boot runlevel script
  export D_SPLASHY=splashy.boot
fi
