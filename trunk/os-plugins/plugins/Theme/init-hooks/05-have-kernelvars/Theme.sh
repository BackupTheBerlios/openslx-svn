# splashy stuff seems to depend on /proc/fb with VESA!?
# only activate with kernel option quiet
if grep -E "(VESA|VGA)" /proc/fb > /dev/null 2>&1 \
  && grep -qi " quiet " /proc/cmdline > /dev/null 2>&1 ; then
  export Theme_nosplash=0
else
  export Theme_nosplash=1
fi

[ ${Theme_nosplash} -eq 0 ] &&	/bin/splashy boot 2>/dev/null
