#!/bin/sh
#
# Description:	Modificated /etc/init.d/boot for use with Diskless 
#		X Stations (v3.4)
#		-> replaces /etc/init.d/boot
#
# Author(s):	Dirk von Suchodoletz <dirk@goe.net>, 13-11-2005
#		Thorsten Zitterell, 09-06-2005
# Copyright: 	(c) 2003, 2005 - RZ Universitaet Freiburg
# 
# Version:	0.6.3b
# 
# Some parts taken from /etc/init.d/boot by
#
# Copyright (c) 1996-2004 SuSE Linux AG, Nuernberg, Germany.
# All rights reserved.
#
# Author: Ruediger Oertel <ro@suse.de>, 1996-2002
#         Werner Fink <werner@suse.de>, 1996-2003
#         Burchard Steinbild, 1996-2000
#         Florian La Roche, 1996
#
# /etc/init.d/boot.ld (activated through /etc/inittab)
#
# first script to be executed from init on system startup
#
# Most of preparation is done by this bootup configuration script
# and helper scripts like boot.servconf and boot.hwsetup
#
################################################################
LD_LIBRARY_PATH=/usr/lib

# Before we do anything else, try at first to activate SELinux support
test -d /selinux && mount -n -t selinuxfs none /selinux &>/dev/null

# Configuration and coloring of the boot messages
. /etc/rc.status
. /etc/sysconfig/boot

# Set vendor code identifier for DHCP requests
VCI="DXS2"

# Simple helper script
logwrite () {
    echo -e "boot: $1" >> $LOGFILE
}

# Avoid be interrupted by child or keyboard
trap "echo" SIGINT SIGSEGV SIGQUIT
set +e

# reasonable start values for bootsplash progress
export progress=0
export sscripts=45
export kscripts=45

echo -n "System Boot Control: "
echo "Running $0"

# some important (un)mounts
umount /lib/klibc/dev &>/dev/null
rc_reset
echo -n "Mounting /proc and /ram (tempfs) filesystem"
# file /etc/fstab in some scenarios not available
mount -n -t proc proc /proc &>/dev/null
mount -n -t tmpfs tmpfs /ram
rc_status -v -r

################################################################
#
# try to mount mulafs or unionfs (check that way if present/loadable)
# module should be loaded within initial ramdisk!!
rc_reset
echo "Setting up linux diskless client (LDC) environment ..."
if cat /proc/modules|grep -e "^mini_fo" &>/dev/null && \
    cat /proc/cmdline|grep -e " mini_fo " &>/dev/null ; then
	echo -n "Using mini_fo for rw access"
	mkdir -p /ram/union /ram/uniontmp
	mount -t tmpfs none /ram/uniontmp
	mount -t mini_fo -o base=/,sto=/ram/uniontmp / /ram/union &>/dev/null
	mkdir -p /ram/union/uniontmp
	mount --move /ram/uniontmp /ram/union/uniontmp
	mount --move /dev /ram/union/dev
	# mount --move /lib/klibc/events /ram/union/events
	mount --move /proc /ram/union/proc
	pivot_root /ram/union /ram/union
        mfspresent=yes
	rc_status -v -r
# multilayer filesystem ((c) by Thorsten Zitterell)
elif cat /proc/modules|grep -e "^mulafs" &>/dev/null && \
    cat /proc/cmdline|grep -e " mulafs " &>/dev/null ; then
	echo -n "Using MuLaFS (multilayer filesystem) for rw access"
	mkdir -p /ram/union /ram/uniontmp
	mount -t tmpfs none /ram/uniontmp
	mount -t mulafs -o /,/ram/uniontmp none /ram/union &>/dev/null
	mkdir -p /ram/union/uniontmp
	mount --move /ram/uniontmp /ram/union/uniontmp
	mount --move /dev /ram/union/dev
	# mount --move /lib/klibc/events /ram/union/events
	mount --move /proc /ram/union/proc
	pivot_root /ram/union /ram/union
	mfspresent=yes
	rc_status -v -r
# unionfs, see homepage:
elif cat /proc/modules|grep -e "^unionfs" &>/dev/null && \
    cat /proc/cmdline|grep -e " unionfs " &>/dev/null ; then
	echo -n "Using UnionFS for rw access"
	mkdir -p /ram/union /ram/uniontmp
	mount -t tmpfs none /ram/uniontmp
	mount -t unionfs -o dirs=/ram/uniontmp=rw:/=ro none /ram/union
	mkdir -p /ram/union/uniontmp
	mount --move /ram/uniontmp /ram/union/uniontmp
	mount --move /dev /ram/union/dev
	# mount --move /lib/klibc/events /ram/union/events
	mount --move /proc /ram/union/proc
	pivot_root /ram/union /ram/union
        mfspresent=yes
	rc_status -v -r
# just get important directories somehow writeable (old style)
else
	echo -n "Using bind mounts to ramdisk for rw access"
	for i in tmp root media home ; do
          mkdir /ram/$i >/dev/null 2>&1
          mount -n --bind /ram/$i /$i
	done
	# mount -n --move /lib/klibc/events /events
	mkdir -p /ram/etc/sysconfig /ram/var/{run,log,tmp}
	chmod a+rwxt /ram/var/tmp >/dev/null 2>&1
	rc_status -v -r
	etc="/ram"
fi

################################################################
#
# setting debugging output and a log information destination
if grep -i debug /proc/cmdline >/dev/null 2>&1 ; then
    export DEBUGLEVEL=2
    export LOGFILE="/var/log/ld-boot.log"
    echo "Setting debugging output to level $DEBUGLEVEL"
    rc_reset; rc_status -v1
else
    export DEBUGLEVEL=0
    echo "0 0 0 0" >/proc/sys/kernel/printk
    export LOGFILE="/dev/null"
fi
echo -e "# /etc/sysconfig/logfile - file created by $0\n#\n# logfile \
for linux diskless client specific debugging output\nLOGFILE=\"\
$LOGFILE\"\n#\n# debug level\nDEBUGLEVEL=\"$DEBUGLEVEL\"" > \
	${etc}/etc/sysconfig/logfile

################################################################
#
# park some needed directories for later rebind - required if mulafs
# or unionfs modules are not present
[ x$mfspresent != "xyes" ] && {
  for i in  /etc/opt/gnome/gconf \
          /etc/X11/xkb \
          /var/adm \
          /var/lib/texmf \
          /var/lib/rpm; do
        if [ -d $i ] ; then
          list=$i" "$list
          # exclude them from etc copy process too
          echo $i|sed -e "s,/root/,," >/tmp/etc.exclude
          mkdir -p /root/$i >>/dev/null 2>&1
          #[ $DEBUGLEVEL -gt 0 ] && \
          #echo "  $i (without /root path component)" >>$LOGFILE
          mount -n --bind $i /root/$i >>/dev/null 2>&1
        fi
  done

  # fill etc directory but exclude some files (check here for files
  # you could need or does not really!) ...
  echo -e "opt/gnome/gconf/*\n*.old\n*-\n*.rpmorig\n*.rpmnew\n\
*.YaST2save\netc/autoinstall\nlogrotate*\nbootloader\n*~\n\
*.SuSEconfig.saved\npptp.d\nisdn\nyouservers\nhardware/hwcfg*\n\
mtab*\nfstab*\nissue*\nX11/xdm/pixmaps\n*.rpmsave\n\
dhclient.script\nXF86Config*">>/tmp/etc.exclude
  cd /tmp; tar -cp -X /tmp/etc.exclude /etc/* 2>/dev/null|\
    tar -xp -C /ram >/dev/null 2>&1;  cd /
  # it is OK to bind /etc and /var now
  mount -n --bind /ram/etc /etc
  mount -n --bind /ram/var /var
  rm /tmp/etc.exclude >/dev/null 2>&1
}

################################################################
#
# try to get basic ip and dns configuration
# where to get configuration information
cfgtype=`grep -i -e "dhcp" -e "ldap" -e "file" /proc/cmdline 2>/dev/null`
iscbin=`which dhclient`
dhcbin=`which dhcpcd`
rm /etc/resolv.conf &>/dev/null
mkdir -p /var/lib/dhcp

#if [ -z "$iscbin" -a "$cfgtype" = "dhcp" ] || \
#   [ "$cfgtype" != "dhcp" ] ; then
#	if [ -n "$dhcbin" ]; then
#	  # try to get a lease with specific VCI first, then any
#	  # fixme!! dhcpcd has to be killed ...
#	  $dhcbin -i $VCI -D -H -t 1 eth0 || $dhcbin -D -H -t 4 eth0 &	
#	elif [ -n "$dhcbin" ]; then
#	  echo -e "send vendor-class-identifier \"$VCI\";\n\
#	  send dhcp-lease-time 86400;\nsend dhcp-max-message-size 1400;\n\
#	  request;\nscript \"/usr/local/bin/dhclient-script\";" \
#	    >> /etc/dhclient.conf
#          $iscbin eth0 &>/dev/null || {
#          echo -e "send dhcp-lease-time 86400;\n\
#	  send dhcp-max-message-size 1400;\n\
#	  request;\nscript \"/usr/local/bin/dhclient-script\";" \
#            >> /etc/dhclient.conf
#          $iscbin eth0 &>/dev/null &
#          }
#	else
#	  logwrite "no dhcp client program available"    
#	fi
#fi

################################################################
#
# create some important standard directories and files if they
# are not present at this state
for i in  /tmp/scratch /var/log /var/X11R6/compose-cache \
          /var/run/sysconfig/tmp /var/adm /var/cache/sax/files \
	  /var/lib/rpm /var/cache/sax/sysp/rdbms \
	  /var/lib/nobody /var/lib/pam_devperm \
	  /var/lib/texmf /var/lib/nfs/sm /var/lib/nfs/state \
	  /var/lib/bluetooth \
	  /var/lib/misc /var/lib/acpi /var/spool/cron \
	  /var/lock/subsys/sysconfig ; do
	test -d $i || mkdir -p $i &>/dev/null
done
# if not created, last, w, who and similar will not work 
# correctly
touch /var/run/utmp /var/log/wtmp /var/log/lastlog

# correct permissions for /tmp and other directories
chmod a+rwxt /tmp /tmp/scratch 2>/dev/null &
chown 65534:0 /var/lib/nobody &
# clear event log (comment this if boot.coldplug should be used)
rm -rf /lib/klibc/events/* &>/dev/null &
grep dxs-user /etc/passwd &>/dev/null && {
  mkdir /tmp/dxs-user
  chown dxs-user:users /tmp/dxs-user &>/dev/null &
}
test -p /lib/bootsplash/control || \
	mknod /lib/bootsplash/control p

################################################################
#
# get rewritable directories within the ramdisk if no multilayer
# filesyste is present
[ x$mfspresent != "xyes" ] && {
  # get the "covered" mounts back into filesystem structure
  for i in $list; do
        #rm -rf $i/* >/dev/null 2>&1
        mount -n --move /root/$i $i >>$LOGFILE 2>&1
  done
  rm -rf /root/* >/dev/null 2>&1
}

################################################################
#
# Generating /etc/fstab and mounting /dev/pts and /sys
rc_reset
echo -e "# /etc/fstab - file generated by\n#\t$0:\n\
#\tDirk von Suchodoletz, dirk@goe.net\n\n\
rootfs\t\t/\t\trootfs\t\tro\t\t 0 0\n\
proc\t\t/proc\t\tproc\t\tdefaults\t 0 0\n\
initramdevs\t/dev\t\ttmpfs\t\trw\t\t 0 0\n\
devpts\t\t/dev/pts\tdevpts\t\tmode=0620,gid=5\t 0 0\n\
usbfs\t\t/proc/bus/usb\tusbfs\t\tnoauto\t\t 0 0">/etc/fstab
echo -n "Mounting /dev/pts"
mount -t devpts -o mode=0620,gid=5 devpts /dev/pts
rc_status -v -r
if [ -d /sys ] ; then
    while read a b c  ; do
        case "$b" in
            sysfs)
		echo -n "Mounting /sys filesystem"
		echo -e "sysfs\t\t/sys\t\tsysfs\t\trw\t\t 0 0\n" \
		  >>/etc/fstab
		mount -t sysfs sysfs /sys
		rc_status -v -r
                break
                ;;
        esac
    done < /proc/filesystems
else
   logwrite "Sysfs (/sys) not mounted, directory non existent?"
fi

# Start blogd, requires /proc and /dev/pts.
# Export the real device in variable REDIRECT.
test -x /sbin/blogd -a -n "$REDIRECT" && /sbin/blogd $REDIRECT
if test -z "$REDIRECT" ; then
    if (echo -n > /dev/tty) 2>/dev/null ; then
        REDIRECT=/dev/tty
    else
        REDIRECT=/dev/console
    fi
fi

################################################################
#
# Let ld.so rebuild its cache.
test -x /sbin/ldconfig && {
    echo -n "Setting up /etc/ld.so.cache"
    # runlevel script not needed
    rm /etc/init.d/boot.d/*boot.ldconfig &>/dev/null
    if [ -s /etc/ld.so.cache ] ; then
	echo " as background process"
	  /sbin/ldconfig -X -C /etc/ld.so.cache &    \
	  >> $LOGFILE 2>&1 || rc_failed
    else
	echo " ..."
	/sbin/ldconfig -X -C /etc/ld.so.cache      \
	  >> $LOGFILE 2>&1 || rc_failed
    fi
    rc_status -v1; rc_reset
}

################################################################
#
# get and set configuration info
touch /etc/sysconfig/machine-setup /etc/sysconfig/machine-setup.default
# set default if no strategy is given
[ "x$cfgtype" = "x" ] && cfgtype="dhcp"
case "$cfgtype" in
  *ldap*|*LDAP*)
    logwrite "configuring machine via ldap"
    # rm /etc/resolv.conf &>/dev/null
    set > /tmp/set.cfg
    if [ -s /usr/local/share/dxsadmin/dxshostcfg ] ; then
        if macaddr=`(ifconfig eth0 | grep eth0 | \
                     sed 's/^.*\(Adresse\|HWaddr\)\ \([0-9A-Fa-f:]*\).*$/\2/') 2>/dev/null` ; then
                /usr/local/share/dxsadmin/dxshostcfg /etc/dxshostcfg.conf $macaddr >>/etc/sysconfig/machine-setup
        else
                echo "no MACaddress found, sorry"
        fi
    else
        echo "!!!!        dxshostcfg not found        !!!!"
        echo "!!!! no configuration via ldap possible !!!!"
    fi
    ;;
  *dhcp*|*DHCP*)
    if [ -n "$iscbin" ] ; then
      logwrite "configuring machine via dhcp" 
      echo -e "# /etc/dhclient.conf - file generated by\n#\t$0:\
\n#\t$daut\n" > /etc/dhclient.conf
      # provide dhclient with proper configuration
      echo -e "option bootlocal-script code 221\t= string;\n\
option language code 222\t\t= string;\n\
option start-x code 223\t\t\t= string;\n\
option start-snmp code 224\t\t= string;\n\
option start-sshd code 225\t\t= string;\n\
option start-xdmcp code 226\t\t= string;\n\
option start-cron code 227\t\t= string;\n\
option crontab-entries code 228\t\t= string;\n\
option start-rwhod code 229\t\t= string;\n\
option start-printdaemon code 230\t= string;\n\
option desktop-session code 231\t= string;\n\
option tex-enable code 232\t\t= string;\n\
option netbios-workgroup code 233\t= string;\n\
option vmware code 234\t\t\t= string;\n\
option hw-mouse code 252\t\t= string;\n\
option hw-graphic code 253\t\t= string;\n\
option hw-monitor code 254\t\t= string;\n\n\
send vendor-class-identifier \"DXS2\";\n\
send dhcp-lease-time 86400;\nsend dhcp-max-message-size 1400;\n\
request;\nscript \"/usr/local/bin/dhclient-script\";" >> /etc/dhclient.conf
      $iscbin eth0 &>/dev/null #|| echo -e "send dhcp-lease-time 86400;\n\
#send dhcp-max-message-size 1400;\n\
#request;\nscript \"/usr/local/bin/dhclient-script\";" \
#            >> /etc/dhclient.conf
#      $iscbin eth0 &>/dev/null &
    else
      logwrite "configuring via dhcp restricted because of missing \
dhclient\nprogram! please install ISC dhcp."
    fi
    ;;
  *file*|*file*)
    logwrite "configuring machine from file"
    ;;
esac

################################################################
#
# Save old terminal settings and set -nl to avoid staircase
# effect, do not lock scrolling, and avoid break characters.
otty=$(stty -g)
if test "$FLOW_CONTROL" = "yes" ; then
    stty -nl  ixon ignbrk -brkint
else
    stty -nl -ixon ignbrk -brkint
fi

################################################################
#
# Should we ask for interactive boot mode
DO_CONFIRM=""
read -t 2 check < /proc/cmdline 2> /dev/null
case "$check" in
    *confirm*) DO_CONFIRM=yes ;;
esac
test -z "$CONFIRM_PROMPT_TIMEOUT" && CONFIRM_PROMPT_TIMEOUT=5
if test "$PROMPT_FOR_CONFIRM" = "yes" -a "$DO_CONFIRM" != "yes" ; then
    echo -en "${extd}Enter Interactive startup mode?${norm}"
    rc_timer_on "$CONFIRM_PROMPT_TIMEOUT" 37
    read -t "$CONFIRM_PROMPT_TIMEOUT" -n 1 \
        -p " ${extd}y${norm}/[${extd}n${norm}]\
("${CONFIRM_PROMPT_TIMEOUT}s") " answer
    rc_timer_off
    case "$answer" in
    [yYiI]) DO_CONFIRM=yes ;;
    *)      DO_CONFIRM=    ;;
    esac
    unset answer
    echo
fi
export DO_CONFIRM

################################################################
#
# Common used variables
bootrc=/etc/init.d/boot.d
rex="[0-9][0-9]"
failed=""
skipped=""
callord=""

#
# Initialize boosplash progressbar variables
#
. /etc/rc.splash B
splashtrigger "rlchange B"

################################################################
#
# Do we stop/start script in parallel?
startpar=$(type -p startpar)
test "$RUN_PARALLEL" = "yes" || startpar=""
test "$DO_CONFIRM"   = "yes" && startpar=""

# Start bootup client scripts.
if test -d ${bootrc}/ ; then
    for i in ${bootrc}/S*; do
        test -f $i || continue

        B=${i##*/}
        script=${B#*S$rex}
        B=${B%$script}

        rc_splash "$script start"

        if test "$DO_CONFIRM" = "yes" ; then
            rc_confirm -t 5 "Start bootup script ${script}" \
		< $REDIRECT > $REDIRECT 2>&1
            case "$?" in
            0) true     ;;
            1) continue ;;
            2) DO_CONFIRM=""
            esac
        fi

        if test -z "$startpar" ; then
            blogger "$script start"

            if test -x "$i" ; then
                $i start
            else
                echo Running $i
                /bin/sh $i b
                rc_status -v1 -r
            fi
            status=$?
            echo -en "$rc_reset"

            case $status in
            [1-4])   failed="${failed:+$failed }$script"   ;;
            [56])   skipped="${skipped:+$skipped }$script" ;;
            [07]|*) ;;
            esac

            blogger "'$script start' exits with status $status"
        else
            # Parallel boot only for valid scripts
            test -x $i || continue

            # Current vector
            eval cur=\${$B}
            test -n "$cur" || callord="${callord:+$callord }$B"

            # Remember scripts
            eval $B="\${cur:+$i }\${cur:-$i}"
        fi
    done
fi

################################################################
#
# Call the scripts in correct order
if test -n "$startpar" ; then
    declare -i s
    for p in $callord ; do
        vect=$p
        eval p=(\${$p})

        blogger "run boot scripts (${p[@]##*S$rex})"
        if test ${#p[@]} -eq 1 ; then
            ${p} start
            status=($?)
        else
            status=($($startpar -t 30 -T 3 -a start ${p[@]}))
        fi
        echo -en "$rc_reset"
        blogger "exit status of (${p[@]##*S$rex}) is (${status[@]})"

        s=0
        for script in ${p[@]##*S$rex} ; do
            case "${status[$s]}" in
            [1-4])  failed="${failed:+$failed }$script"   ;;
            [56])  skipped="${skipped:+$skipped }$script" ;;
            0|*)   ;;
            esac
            : $((s++))
        done
    done
fi

################################################################
#
# Be verbose and print stats
echo -n "System Boot Control: "
echo -e "The system has been ${stat}${extd}set up${norm}"
if test -n "$failed" ; then
    n=$((${#failed} + 7))
    echo -n  "Failed features: "
    test $n -lt 47 && echo -en "\033[${COLUMNS}C\033[${n}D"
    echo -e  "${warn}${failed}${norm}"
fi
if test -n "$skipped" ; then
    n=$((${#skipped} + 7))
    echo -n  "Skipped features: "
    test $n -lt 47 && echo -en "\033[${COLUMNS}C\033[${n}D"
    echo -e  "${attn}${skipped}${norm}"
fi


################################################################
#
# Check for boot cycle detection
test -s /lib/bootcycle/stats && . /lib/bootcycle/stats


# Remember for master resource script
if test "$DO_CONFIRM" = "yes" ; then
    touch /var/run/do_confirm
fi

# Restore old terminal settings
stty $otty

################################################################
#
# Let zic set timezone - if present (from boot.ldconfig).
if test -n "$TIMEZONE" -a -x /usr/sbin/zic ; then
	echo -n Setting up timezone data
	/usr/sbin/zic -l $TIMEZONE
	rc_status -v -r
fi
				 
################################################################
#
# start user defined bootup script.
if test -f /etc/init.d/boot.local ; then
        ECHO_RETURN=$rc_done_up
	echo "Running /etc/init.d/boot.local"
        /bin/sh /etc/init.d/boot.local || rc_failed
	rc_status -v1; rc_reset
	rc_splash "boot.local start"
fi

rc_reset
exit 0
