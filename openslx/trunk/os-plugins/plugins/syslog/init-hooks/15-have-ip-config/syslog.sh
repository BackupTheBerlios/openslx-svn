if [ -e /initramfs/plugin-conf/syslog.conf ]; then
    . /initramfs/plugin-conf/syslog.conf
    if [ $syslog_active -ne 0 ] && [ -n "$syslog_host" ]; then
        echo "syslogd -R ${syslog_host}:${syslog_port}..."
        syslogd -R "${syslog_host}:${syslog_port}" & >/dev/null 2>&1
        klogd >/dev/null 2>&1
    fi
fi
