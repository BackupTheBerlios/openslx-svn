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
# vmware/OpenSLX/Distro/Base.pm
#    - provides base implementation of the Distro API for the vmware plugin.
# -----------------------------------------------------------------------------
package vmware::OpenSLX::Distro::Base;

use strict;
use warnings;

our $VERSION = 1.01;        # API-version . implementation-version

use Scalar::Util qw( weaken );

use OpenSLX::Basics;
use OpenSLX::Utils;

################################################################################
### interface methods
################################################################################
sub new
{
    my $class = shift;
    my $self = {};
    return bless $self, $class;

}

sub initialize
{
    my $self = shift;
    my $engine = shift;
    weaken($self->{engine});
        # avoid circular reference between plugin and its engine

    return 1;
}

sub fillRunlevelScript
{
    my $self     = shift;
    my $location = shift;
    my $kind     = shift;

#    my $initfile = newInitFile();
#    $initfile->addFunction(
#	'load_modules',
#        '
#         # to be filled in via the stage1 configuration script
#         insmod /lib/modules/\$(uname -r)/misc/vmmon.ko || return 1
#         insmod /lib/modules/\$(uname -r)/misc/vmnet.ko || return 1
#         insmod /lib/modules/\$(uname -r)/misc/vmblock.ko 2>/dev/null || return 0
#        '
#        {param => "value"}
#    );
#
#    $initfile->addFunctionCall(
#	'functionName',
#        'start', # name of block
#        {priority => 5, }
#    );
#
#    $initfile->addDaemon("/bin/mydaemon");
#
#    my $runlevelscript = getInitFileForDistro($initfile, "ubuntu");

    my $script = unshiftHereDoc(<<"    End-of-Here");
        #!/bin/sh
        # completely generic start/stop script, generated via stage1 'vmware' plugin
        # install
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
        load_modules() {
    End-of-Here

    # Load modules
    if ($kind eq 'local' || $kind eq 'local25') {
        $script .= unshiftHereDoc(<<"        End-of-Here");
         # to be filled in via the stage1 configuration script
         insmod /lib/modules/\$(uname -r)/misc/vmmon.ko || return 1
         insmod /lib/modules/\$(uname -r)/misc/vmnet.ko || return 1
         insmod /lib/modules/\$(uname -r)/misc/vmblock.ko 2>/dev/null || return 0
        End-of-Here
    } elsif ($kind eq 'vmpl1.0') {
        $script .= unshiftHereDoc(<<"        End-of-Here");
              vmware_kind_path=/opt/openslx/plugin-repo/vmware/${kind}/
              module_src_path=\${vmware_kind_path}/vmroot/modules
              insmod \${module_src_path}/vmmon.ko
              insmod \${module_src_path}/vmnet.ko
        End-of-Here
    } elsif ($kind eq "vmpl2.0") {
        $script .= unshiftHereDoc(<<"        End-of-Here");
              vmware_kind_path=/opt/openslx/plugin-repo/vmware/${kind}/
              module_src_path=\${vmware_kind_path}/vmroot/modules
              insmod \${module_src_path}/vmmon.ko
              insmod \${module_src_path}/vmnet.ko
              insmod \${module_src_path}/vmblock.ko
        End-of-Here
    } elsif ($kind eq 'vmpl2.5') {
        $script .= unshiftHereDoc(<<"        End-of-Here");
              vmware_kind_path=/opt/openslx/plugin-repo/vmware/${kind}
              module_src_path=\${vmware_kind_path}/vmroot/modules
              insmod \${module_src_path}/vmmon.ko
              insmod \${module_src_path}/vmnet.ko
              insmod \${module_src_path}/vmblock.ko
        End-of-Here
    }

    # unload modules
    $script .= unshiftHereDoc(<<"    End-of-Here");
        }

        unload_modules() {
          # to be filled with the proper list within via the stage1
          # configuration script
          rmmod vmmon vmblock vmnet vmmon 2>/dev/null

        }
    End-of-Here


    # setup vmnet0 and vmnet8
    # depends on specific stage3 setting. I let this if in the code
    # because else this whole if-reducing process will become more
    # complicated and the code will get less understandable
    $script .= unshiftHereDoc(<<"    End-of-Here");
        # the bridged interface
        setup_vmnet0() {
          if [ -n "\$vmnet0" ] ; then
            # the path might be directly point to the plugin dir
    End-of-Here
    if ($kind eq 'vmpl2.5' || $kind eq 'local25') {
      $script .= "    $location/vmnet-bridge -d /var/run/vmnet-bridge-0.pid -n 0\n";
    } else {
      $script .= "    $location/vmnet-bridge -d /var/run/vmnet-bridge-0.pid /dev/vmnet0 eth0\n";
    }
    $script .= unshiftHereDoc(<<"        End-of-Here");
          fi
        }
        # we definately prefer the hostonly interface for NATed operation too
        # distinction is made via enabled forwarding
        setup_vmnet1() {
          if [ -n "\$vmnet1" ] ; then
            # the path might be directly point to the plugin dir
            $location/vmnet-netifup -d /var/run/vmnet-netifup-vmnet1.pid \\
              /dev/vmnet1 vmnet1
            dhcpif="\$dhcpif vmnet1"
            ip addr add \$vmnet1 dev vmnet1
            ip link set vmnet1 up
            if [ -n "\$vmnet1nat" ] ; then
              # needs refinement interface name for eth0 is known in stage3 already
              echo "1" > /proc/sys/net/ipv4/conf/vmnet1/forwarding 2>/dev/null
              echo "1" > /proc/sys/net/ipv4/conf/eth0/forwarding 2>/dev/null
              #iptables -A -s vmnet1 -d eth0
            fi
            $location/vmnet-dhcpd -cf /etc/vmware/dhcpd-vmnet1.conf -lf \\
              /var/run/vmware/dhcpd-vmnet1.leases \\
              -pf /var/run/vmnet-dhcpd-vmnet1.pid vmnet1 2>/dev/null # or logfile 
          fi
        }
        # incomplete ...
        setup_vmnet8() {
          if [ -n "\$vmnet8" ] ; then
            #test -c /dev/vmnet8 || mknod c 119 8 /dev/vmnet8
            $location/vmnet-netifup -d /var/run/vmnet-netifup-vmnet8.pid \\
              /dev/vmnet8 vmnet8
            ip addr add \$vmnet8 dev vmnet8
            ip link set vmnet8 up
            # /etc/vmware/vmnet-natd-8.mac simply contains a mac like 00:50:56:F1:30:50
            $location/vmnet-natd -d /var/run/vmnet-natd-8.pid \\
              -m /etc/vmware/vmnet-natd-8.mac -c /etc/vmware/nat.conf 2>/dev/null # or logfile 
            $location/vmnet-dhcpd -cf /etc/vmware/dhcpd-vmnet8.conf -lf \\
              /var/run/vmware/dhcpd-vmnet8.leases \\
              -pf /var/run/vmnet-dhcpd-vmnet8.pid vmnet8 2>/dev/null # or logfile 
          fi
        }
        case \$1 in
          start)
            echo "Starting vmware background services ..."
            # load the configuration file
            . /etc/vmware/slxvmconfig
            load_modules
            setup_vmnet0
            setup_vmnet1
            setup_vmnet8
          ;;
          stop)
            # message output should match the given vendor-os
            echo "Stopping vmware background services ..."
            killall vmnet-netifup vmnet-natd vmnet-bridge vmware vmplayer \\
              vmware-tray vmnet-dhcpd 2>/dev/null
            # wait for shutting down of interfaces... vmnet needs kinda
            # long
            sleep 1
            unload_modules
          ;;
          #status)
          #  echo "Say something useful here ..."
          #;;
          restart)
            "\$0" stop
            "\$0" start
          ;;
        esac
        exit 0
        End-of-Here
    return $script;
}

1;
