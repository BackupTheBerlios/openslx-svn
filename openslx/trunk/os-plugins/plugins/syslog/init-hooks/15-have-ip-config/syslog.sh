if [ -e /initramfs/plugin-conf/syslog.conf ]; then
  . /initramfs/plugin-conf/syslog.conf
  if [ $syslog_active -ne 0 ]; then
    # TODO: maybe limit the maximum log file size via rotation?
    params="-s 0"
    if [ -n "$syslog_host" ]; then
      params="$params -R ${syslog_host}:${syslog_port}"
    fi
    echo "syslogd $params ..."
    syslogd $params >/dev/null 2>&1
    klogd >/dev/null 2>&1
  fi
fi
