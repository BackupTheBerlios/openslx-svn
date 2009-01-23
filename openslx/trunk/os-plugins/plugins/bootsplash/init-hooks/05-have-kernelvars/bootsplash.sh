# splashy depends on /proc/fb with VESA
# only activate with kernel option quiet and no debuglevel
if grep -E "(VESA|VGA)" /proc/fb > /dev/null 2>&1 \
  && grep -qie " quiet " -qie "^quiet " -qie " quiet$" /proc/cmdline \
    > /dev/null 2>&1 \
  && [ $DEBUGLEVEL -eq 0 ] \
  && [ -e /bin/splashy ] ; then
    echo "we have bootsplash" >/tmp/bootsplash
    /bin/splashy boot 2>/dev/null
    # add splashy.stop runlevel script (does not work any more here,
    # temporarily moved to init awaiting a proper solution)
    #D_SPLASHY=splashy.stop
fi
