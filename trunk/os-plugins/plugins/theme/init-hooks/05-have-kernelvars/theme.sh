# splashy depends on /proc/fb with VESA
# only activate with kernel option quiet and no debuglevel
if grep -E "(VESA|VGA)" /proc/fb > /dev/null 2>&1 \
  && grep -qi " quiet " /proc/cmdline > /dev/null 2>&1 \
  && [ $DEBUGLEVEL -eq 0 ] ; then
  export theme_nosplash=0
else
  export theme_nosplash=1
fi

[ ${theme_nosplash} -eq 0 ] &&	/bin/splashy boot 2>/dev/null
