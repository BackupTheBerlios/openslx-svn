#!/lib/klibc/bin/sh
#
# mkinitramfs extension to SuSE linux 9.3 for linux diskless clients (v3.3)
# version 0.2.0b. This script tries to use a translucent filesystem if 
# present (mulafs by Th. Zitterell). You have to fetch the source and compile
# the kernel module matching to your kernel you would like to use.
# 
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 59 Temple
# Place, Suite 330, Boston, MA 02111-1307 USA
#
# Author: Dirk von Suchodoletz <dirk@goe.net>, 18-04-2005
#
# proper error reporting should be included here ...
#
# Important notice: After any change made here -> run mkinitrd!!

echo "Setting up linux diskless client (LDC) environment ..."

# change PATH variable to get access to binaries on the nfs
export PATH=$PATH:/root/bin:/root/sbin:/root/usr/bin:/root/usr/sbin
export LD_LIBRARY_PATH=/root/lib:/root/usr/lib
#rwrootdir=/root/ram
# do not use mount binary provided by initrd
mountbin=/root/bin/mount

# quickhack remove if fixed

#$mountbin -n -o remount,ro /root

# check if splash is enabled
#dosplash () { }
#if [ -f /proc/splash ]; then
#    cat /proc/splash|grep -i " on"&>/dev/null && {
#	splash=yes;
#	dosplash () { echo "show $1" >/proc/splash; }
#    }
#fi
#[ x$splash = "xyes" ] && dosplash 10000
                    

	# mounting ram filesystem for rw parts
#	$mountbin -n -t tmpfs tmpfs /root/ram




# setting debugging output and a log information destination
#if grep -i debug /proc/cmdline >/dev/null 2>&1 ; then
#	export DEBUGLEVEL=2
#	export LOGFILE="$rwrootdir/var/log/ld-boot.log"
#else
#	export DEBUGLEVEL=0
#	echo "0 0 0 0" >/proc/sys/kernel/printk
#	export LOGFILE="/dev/null"
#fi





# hacks because of my misunderstanding of SuSEs init
$mountbin -n --bind /root/lib/klibc/dev /root/dev

# mount /tmp/dxs from server (unclean hack -> better idea??)
#read cmdline </proc/cmdline
#serverip=`echo $cmdline|sed -e "s,.*nfsroot=,," -e "s,:/.*,,"`
#/lib/klibc/bin/nfsmount $serverip:/tmp/dxs /root/tmp/scratch >/dev/null 2>&1
# ensure the /tmp/scratch is usable/writeable by normal accounts
#chmod a+rwxt $rwrootdir/tmp/scratch


#mkdir -p /ram 
touch /etc/fstab
cat /proc/mounts | sed -e "s/v3,//" >/etc/mtab
$mountbin -n -o remount,ro /root

#/root/bin/mount -t unionfs -o dirs=/ram=rw:/root=ro none /root

mkdir /root/dev/shm
ln -s /proc/self/fd /root/dev/fd
mknod -m 666 /root/dev/tty c 5 0
mknod -m 600 /root/dev/console c 5 1
mknod -m 666 /root/dev/ptmx c 5 2
mknod -m 666 /dev/null c 1 3
for i in 1 2 3 4 5 6 7 8 9; do
	mknod -m 660 /root/dev/tty$i c 4 $i
done

