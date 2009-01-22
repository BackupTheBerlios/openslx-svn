# splashy depends on /proc/fb with VESA
# only activate with kernel option quiet and no debuglevel
if grep -E "(VESA|VGA)" /proc/fb > /dev/null 2>&1 \
  && grep -qi " quiet " /proc/cmdline > /dev/null 2>&1 \
  && [ $DEBUGLEVEL -eq 0 ] \
  && [ -e /bin/splashy ] ; then
  export theme_nosplash=0
else
  export theme_nosplash=1
fi

if [ ${theme_nosplash} -eq 0 ]; then
        # start splashy
        /bin/splashy boot 2>/dev/null
        
        # add splashy.stop (XX_theme) to runlevel scripts 
        echo 'D_INITSCRIPTS="${D_INITSCRIPTS} splashy.stop"' \
                >> /etc/sysconfig/config
fi
