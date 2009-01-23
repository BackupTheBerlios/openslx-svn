if [ -e /initramfs/plugin-conf/bootlog.conf ]; then
    . /initramfs/plugin-conf/bootlog.conf
    if [ $bootlog_active -ne 0 ]; then
        echo "syslogd -R $bootlog_target..."
        syslogd -R $bootlog_target & >/dev/null 2>&1
    fi
fi
