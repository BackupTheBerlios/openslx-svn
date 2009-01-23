if [ -e /initramfs/plugin-conf/syslog.conf ]; then
    . /initramfs/plugin-conf/syslog.conf
    if [ $syslog_active -ne 0 ] && [ -n "$syslog_host" ]; then
        # kill syslogd, as it is going to be replaced by system's syslog soon
        killall syslogd
        # remove links to boot.klog, as that will hang (I suppose that is 
        # because we already emptied /dev/kmsg)
        rm /mnt/etc/init.d/boot.d/*.klog
    fi
fi
