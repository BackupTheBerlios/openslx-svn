#! /bin/sh
#
# stage3 part of 'xen' plugin - the runlevel script
#
mkdir -p /mnt/var/log/xen &
mkdir -p /mnt/var/run/xend &
mkdir -p /mnt/var/run/xenstored &
cd /mnt/etc/init.d/rc5.d
ln -s ../xendomains K08xendomains
ln -s ../xend K09xend
ln -s ../xend S13xend
ln -s ../xendomains S14xendomains
modprobe loop max_loop=64
