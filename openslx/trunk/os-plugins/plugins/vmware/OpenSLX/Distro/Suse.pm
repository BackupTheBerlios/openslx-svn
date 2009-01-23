# Copyright (c) 2008 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your suggestions, praise, or complaints to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org/
# -----------------------------------------------------------------------------
# vmware/OpenSLX/Distro/Suse.pm
#    - provides SUSE-specific overrides of the Distro API for the vmware plugin.
# -----------------------------------------------------------------------------
package vmware::OpenSLX::Distro::Suse;

use strict;
use warnings;

use base qw(vmware::OpenSLX::Distro::Base);

use OpenSLX::Basics;
use OpenSLX::Utils;

################################################################################
### interface methods
################################################################################

sub fillRunlevelScript
{
    my $self     = shift;
    my $location = shift;
    my $kind     = shift;

    my $script = unshiftHereDoc(<<"    End-of-Here");
        #! /bin/sh
        # SuSE compatible start/stop script, generated via stage1 'vmware' plugin
        # installation
        #
        # inspiration taken from vmware start script:
        #   Copyright 1998-2007 VMware, Inc.  All rights reserved.
        #
        # This script manages the services needed to run VMware software
        
        # Basic support for the Linux Standard Base Specification 1.3
        ### BEGIN INIT INFO
        # Provides: VMware
        # Required-Start: \$syslog
        # Required-Stop:
        # Default-Start: 2 3 5
        # Default-Stop: 0 6
        # Short-Description: Manages the services needed to run VMware software
        # Description: Manages the services needed to run VMware software
        ### END INIT INFO

        # helper functions
        load_modules() {
    End-of-Here

    # Load modules
    if ($kind eq 'local' || $kind eq 'local25') {
        $script .= unshiftHereDoc(<<"        End-of-Here");
              # to be filled in via the stage1 configuration script
              insmod /lib/modules/\$(uname -r)/misc/vmmon.o || return 1
              insmod /lib/modules/\$(uname -r)/misc/vmnet.o || return 1
              insmod /lib/modules/\$(uname -r)/misc/vmblock.o 2>/dev/null || return 0
              #insmod /lib/modules/\$(uname -r)/misc/vmci.o 2>/dev/null || return 0
              # most probably nobody wants to run the parallel port driver ...
              #modprobe vm...
        End-of-Here
    } elsif ($kind eq 'vmpl1.0') {
        $script .= unshiftHereDoc(<<"        End-of-Here");
              # load module manuall
              vmware_kind_path=/opt/openslx/plugin-repo/vmware/\${vmware_kind}/
              module_src_path=\${vmware_kind_path}/vmroot/modules
              insmod \${module_src_path}/vmmon.o
              insmod \${module_src_path}/vmnet.o
        End-of-Here
    } elsif ($kind ne "vmpl2.0") {
        $script .= unshiftHereDoc(<<"        End-of-Here");
              # load module manuall
              vmware_kind_path=/opt/openslx/plugin-repo/vmware/\${vmware_kind}/
              module_src_path=\${vmware_kind_path}/vmroot/modules
              insmod \${module_src_path}/vmmon.o
              insmod \${module_src_path}/vmnet.o
              insmod \${module_src_path}/vmblock.o
        End-of-Here
    } elsif ($kind eq 'vmpl2.5') {
        $script .= unshiftHereDoc(<<"        End-of-Here");
              # load module manuall
              vmware_kind_path=/opt/openslx/plugin-repo/vmware/\${vmware_kind}/
              module_src_path=\${vmware_kind_path}/vmroot/modules
              insmod \${module_src_path}/vmmon.o
              insmod \${module_src_path}/vmnet.o
              #insmod \${module_src_path}/vmci.o
              insmod \${module_src_path}/vmmon.o
        End-of-Here
    }

    # unload modules
    $script .= unshiftHereDoc(<<"    End-of-Here");
        }

        unload_modules() {
          # to be filled with the proper list within via the stage1
          # configuration script
          rmmod vmmon vmblock vmnet vmci vmmon 2>/dev/null
        }
    End-of-Here

    # setup vmnet0 and vmnet8
    # depends on specific stage3 setting. A complete rewrite would be
    # needed (generation of proper runlevel scripts depending on distro
    # and VMware version, see tickets #211, 290)
    $script .= unshiftHereDoc(<<"    End-of-Here");
        # the bridged interface
        setup_vmnet0() {
          if [ -n "\$vmnet0" ] ; then
            # the path might be directly point to the plugin dir
    End-of-Here
    if ($kind eq 'vmpl2.5'||$kind eq 'local25') {
        $script .= "\$location/vmnet-bridge -d /var/run/vmnet-bridge-0.pid -n 0\n";
    } else {
        $script .= "\$location/vmnet-bridge -d /var/run/vmnet-bridge-0.pid /dev/vmnet0 eth0\n";
    }
    $script .= unshiftHereDoc(<<"    End-of-Here");
            exit 0
          fi
        }
        # we definately prefer the hostonly interface for NATed operation too
        # distinction is made via enabled forwarding
        setup_vmnet1() {
          if [ -n "\$vmnet1" ] ; then
            # we don't need the following test. It's handled by
            # XX_vmware.sh
            #test -c /dev/vmnet1 || mknod c 119 1 /dev/vmnet1
            # the path might be directly point to the plugin dir
            $location/vmnet-netifup -d /var/run/vmnet-netifup-vmnet1.pid \\
              /dev/vmnet1 vmnet1
            dhcpif="\$dhcpif vmnet1"
            ip addr add \$vmnet1 dev vmnet1
            ip link set vmnet1 up
            if [ -n "\$vmnet1nat" ] ; then
              # needs refinement interface name for eth0 is known in stage3 already
              # available from \$nwif
              echo "1" > /proc/sys/net/ipv4/conf/vmnet1/forwarding 2>/dev/null
              echo "1" > /proc/sys/net/ipv4/conf/eth0/forwarding 2>/dev/null
              #iptables -A -s vmnet1 -d eth0
            fi
            $location/vmnet-dhcpd -cf /etc/vmware/dhcpd-vmnet1.conf \\
              -lf /var/run/vmware/dhcpd-vmnet1.leases \\
              -pf /var/run/vmnet-dhcpd-vmnet1.pid vmnet1 2>/dev/null # or logfile
          fi
        }
        # incomplete ...
        setup_vmnet8() {
          if [ -n "\$vmnet8" ] ; then
            # we don't need the following test. It's handled by
            # XX_vmware.sh
            #test -c /dev/vmnet8 || mknod c 119 8 /dev/vmnet8
            $location/vmnet-netifup -d /var/run/vmnet-netifup-vmnet8.pid \\
              /dev/vmnet8 vmnet8
            ip addr add \$vmnet8 dev vmnet8
            ip link set vmnet8 up
            # /etc/vmware/vmnet-natd-8.mac simply contains a mac like 00:50:56:F1:30:50
            $location/vmnet-natd -d /var/run/vmnet-natd-8.pid \\
              -m /etc/vmware/vmnet-natd-8.mac -c /etc/vmware/nat.conf 2>/dev/null # or logfile
            $location/vmnet-dhcpd -cf /etc/vmware/dhcpd-vmnet8.conf \\
              -lf /var/run/vmware/dhcpd-vmnet8.leases \\
              -pf /var/run/vmnet-dhcpd-vmnet8.pid vmnet8 2>/dev/null # or logfile
          fi
        }
        # load the helper stuff
        . /etc/rc.status
        # reset the script status
        rc_reset
    
        case \$1 in
          start)
            echo -n "Starting vmware background services ..."
            # load the configuration file
            . /etc/vmware/slxvmconfig
            load_modules
            setup_vmnet0
            setup_vmnet1
            setup_vmnet8
            rc_status -v
          ;;
          stop)
            # message output should match the given vendor-os
            echo -n "Stopping vmware background services ..."
            killall vmnet-netifup vmnet-natd vmnet-bridge vmware vmplayer \\
              vmware-tray vmnet-dhcpd 2>/dev/null
            # workaround, because we can kill more as we have started
            rc_reset
            # wait for shutting down of interfaces. vmnet needs kinda
            # long
            sleep 1
            unload_modules
            rc_status -v
          ;;
          # we don't need a status yet... at least as long as it is
          # unclear in which path the corresponding binary (see original
          # /etc/init.d/vmware) is in our case
          #status)
          #  echo -n "Say something useful here ..."
          #;;
          restart)
            "\$0" stop
            "\$0" start
          ;;
          *)
            echo "Usage: `basename "\$0"` {start|stop|restart}"
            exit 1
         ;;
        esac
        exit 0
    End-of-Here
    return $script;
}

1;
