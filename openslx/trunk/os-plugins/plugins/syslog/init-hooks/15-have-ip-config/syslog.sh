if [ -e /initramfs/plugin-conf/syslog.conf ]; then
    . /initramfs/plugin-conf/syslog.conf
    if [ $syslog_active -ne 0 ]; then
        echo "syslogd -R $syslog_target..."
        syslogd -R $syslog_target & >/dev/null 2>&1
    fi
fi
