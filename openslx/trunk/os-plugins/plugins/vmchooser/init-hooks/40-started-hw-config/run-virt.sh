waitfor /tmp/hwcfg
hwinfo --cdrom | grep -i "Device File:" | awk {'print $3'} >/etc/hwinfo.cdrom & 
hwinfo --floppy | grep -i "Device File:" | awk {'print $3'} >/etc/hwinfo.floppy &
