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
# vmware.pm
#    - declares necessary information for the vmware plugin
# -----------------------------------------------------------------------------
package OpenSLX::OSPlugin::vmware;

use strict;
use warnings;

use base qw(OpenSLX::OSPlugin::Base);

use File::Basename;
use File::Path;

use OpenSLX::Basics;
use OpenSLX::Utils;

sub new
{
    my $class = shift;

    my $self = {
        name => 'vmware',
    };

    return bless $self, $class;
}

sub getInfo
{
    my $self = shift;

    return {
        description => unshiftHereDoc(<<'        End-of-Here'),
            !!! descriptive text missing here !!!
        End-of-Here
        mustRunAfter => [],
    };
}

sub getAttrInfo
{
    # returns a hash-ref with information about all attributes supported
    # by this specific plugin
    my $self = shift;

    # This default configuration will be added as attributes to the default
    # system, such that it can be overruled for any specific system by means
    # of slxconfig.
    return {
        # attribute 'active' is mandatory for all plugins
        'vmware::active' => {
            applies_to_systems => 1,
            applies_to_clients => 0,
            description => unshiftHereDoc(<<'            End-of-Here'),
                should the 'vmware'-plugin be executed during boot?
            End-of-Here
            content_regex => qr{^(0|1)$},
            content_descr => '1 means active - 0 means inactive',
            default => '1',
        },
        # attribute 'precedence' is mandatory for all plugins
        'vmware::precedence' => {
            applies_to_systems => 1,
            applies_to_clients => 0,
            description => unshiftHereDoc(<<'            End-of-Here'),
                the execution precedence of the 'vmware' plugin
            End-of-Here
            content_regex => qr{^\d\d$},
            content_descr => 'allowed range is from 01-99',
            default => '70',
        },
        # attribute 'imagesrc' defines where we can find vmware images
        'vmware::imagessrc' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                Where do we store our vmware images? NFS? Filesystem?
            End-of-Here
            content_descr => 'Allowed values: path or URI',
            default => '',
        },
        # attribute 'bridge' defines if bridged network mode should be
        # switched on
        'vmware::bridge' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                Should the bridging (direct access of the vmware clients
                to the ethernet the host is connected to) be enabled
            End-of-Here
            content_descr => 'Allowed values: 0 or 1',
            default => '1',
        },
        # attribute 'vmnet1' defines if the host connection network mode 
        # should be switched on and NAT should be enabled
        'vmware::vmnet1' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                Format ServerIP/Netprefix without NAT
                Format ServerIP/Netprefix,NAT enables NAT/Masquerading
            End-of-Here
            content_descr => 'Allowed value: IP/Prefix[,NAT]',
            default => '192.168.101.1/24,NAT',
        },
        # attribute 'vmnet8' defines if vmware specific NATed network mode
        # should be switched on
        'vmware::vmnet8' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                Format ServerIP/Netprefix
            End-of-Here
            content_descr => 'Allowed value: IP/Prefix',
            default => '192.168.102.1/24',
        },
        # is to be discussed how to handle this - there is no single set of
        # vmware files!! -> to be moved to vmwarebinaries plugin!?
        # attribute 'binaries' defines whether or not VMware binaries shall
        # be provided (by downloading them).
        #'vmware::binaries' => {
        #    applies_to_vendor_os => 1,
        #    applies_to_systems => 0,
        #    applies_to_clients => 0,
        #    description => unshiftHereDoc(<<'            End-of-Here'),
        #        Shall VMware binaries be downloaded and installed?
        #    End-of-Here
        #    content_regex => qr{^(0|1)$},
        #    content_descr => 'Allowed values: 0 or 1',
        #    default => '0',
        #},
        # attribute 'kind' defines which set of VMware binaries should be 
        # activated ('local' provided with the main installation set).
        'vmware::kind' => {
            applies_to_vendor_os => 0,
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                Which set of VMware binaries to use: installed (local) or provided by an
                other plugin (e.g. Workstation 5.5: vmws5.5, Player 2.0: vmpl2.0, ...)
            End-of-Here
            content_regex => qr{^(0|1)$},
            content_descr => 'Allowed values: local, vmws5.5, vmws6.0, vmpl1.0 ...',
            default => 'local',
        },
    };
}

sub installationPhase
{
    my $self                      = shift;

    $self->{pluginRepositoryPath} = shift;
    $self->{pluginTempPath}       = shift;
    $self->{openslxPath}          = shift;
    $self->{attrs}                = shift;

    my $vmpath = "";
    my $vmbin  = "";

    # get path of files we need to install
    my $pluginFilesPath 
        = "$self->{'openslxPath'}/lib/plugins/$self->{'name'}/files";

    # copy all needed files (TODO: nvram should depend on the "kind" of vmware ...)
    my @files = qw( vmware-init nvram.5.0 runvmware-v2 );
    foreach my $file (@files) {
        copyFile("$pluginFilesPath/$file", $self->{'pluginRepositoryPath'});
    }
    # generate the runlevel scripts for all existing vmware installations,
    # variants because we do not know which on is selected on client level 
    # (code depends on distro/version and vmware location)
    # for local ... other vm-installations (TODO: generate list)
    @files = qw( local );
    foreach my $file (@files) {
        #  location of the vmware stuff, "local" for directly installed
        # package (more sophisticated assignment might be needed ...)
        if ( $file eq "local" ) {
            my $vmpath = "/usr/lib/vmware";
            my $vmbin  = "/usr/bin";
        }
        # if provided via another plugin (TODO: pathname not completely clear ...)
        else {
            my $vmpath = "/opt/openslx/plugin-repo/vmwareXXX/$file";
            my $vmbin  = "$vmpath/bin";
        }
        my $runlevelScript = "$self->{'pluginRepositoryPath'}/vmware.$file";
        $self->_writeRunlevelScript($vmbin, $runlevelScript);
    }

    # generate links for the user executables vmware and player and a 
    # simplified version of the start script
    @files = qw( vmware vmplayer );
    foreach my $file (@files) {
    # OLTA: this backup strategy is useless if invoked twice, so I have
    #       deactivated it
#        rename ("/usr/bin/$file", "/usr/bin/$file.slx-bak");
        linkFile("/var/X11R6/bin/$file", "/usr/bin/$file");
        my $script = unshiftHereDoc(<<"        End-of-Here");
            #!/bin/sh
            # written by OpenSLX-plugin 'vmware' in Stage1
            # radically simplified version of the original script $file by VMware Inc.
            PREFIX=$vmpath # depends on the vmware location
            exec "\$PREFIX"'/lib/wrapper-gtk24.sh' \
                 "\$PREFIX"'/lib' \
                 "\$PREFIX"'/bin/vmware' \
                 "\$PREFIX"'/libconf' "$@"
        End-of-Here
        spitFile("$self->{'pluginRepositoryPath'}/$file", $script);
    }
}

sub removalPhase
{
    my $self                 = shift;
    my $pluginRepositoryPath = shift;
    my $pluginTempPath       = shift;
    
    rmtree ( [ $pluginRepositoryPath ] );
    # restore old start scripts - to be discussed
    #my @files = qw( vmware vmplayer );
    #foreach my $file (@files) {
    #    rename ("/usr/bin/$file.slx-bak", "/usr/bin/$file");
    #}
    # TODO: path is distro specific
    #rename ("/etc/init.d/vmware.slx-bak", "/etc/init.d/vmware");
    return;
}

sub _writeRunlevelScript
{
    my $self     = shift;
    my $location = shift;
    my $file     = shift;
    
    # $location points to the path where vmware helpers are installed
    my $script = unshiftHereDoc(<<"    End-of-Here");
        #!/bin/sh
        #
        # generated via stage1 'vmware' plugin install
        # inspiration taken from vmware start script:
        #   Copyright 1998-2007 VMware, Inc.  All rights reserved.
        #
        # This script manages the services needed to run VMware software
        
        # Basic support for the Linux Standard Base Specification 1.3
        # Used by insserv and other LSB compliant tools.
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
          # to be filled in via the stage1 configuration script
          modprobe -qa vmmon vmnet vmblock 2>/dev/null
          # most probably nobody wants to run the parallel port driver ...
          #modprobe vm...
        }
        unload_modules() {
          # to be filled with the proper list within via the stage1 configuration
          # script
          rmmod vmmon vmblock vmnet 2>/dev/null
        }
        # the bridged interface
        setup_vmnet0() {
          if [ -n "\$vmnet0" ] ; then
            # the path might be directly point to the plugin dir
            $location/vmnet-bridge -d /var/run/vmnet-bridge-0.pid /dev/vmnet0 eth0
          fi
        }
        # we definately prefer the hostonly interface for NATed operation too
        # distinction is made via enabled forwarding
        setup_vmnet1() {
          if [ -n "\$vmnet1" ] ; then
            test -c /dev/vmnet1 || mknod c 119 1 /dev/vmnet1
            # the path might be directly point to the plugin dir
            $location/vmnet-netifup -d /var/run/vmnet-netifup-vmnet1.pid \
              /dev/vmnet1 vmnet1
            dhcpif="\$dhcpif vmnet1"
            ip addr add \$vmnet1 dev vmnet1
            if [ -n "\$vmnet1nat" ] ; then
              # needs refinement interface name for eth0 is known in stage3 already
              echo "1" > /proc/sys/net/ipv4/conf/vmnet1/forwarding 2>/dev/null
              echo "1" > /proc/sys/net/ipv4/conf/eth0/forwarding 2>/dev/null
              #iptables -A -s vmnet1 -d eth0
            fi
          fi
        }
        # incomplete ...
        setup_vmnet8() {
          if [ -n "\$vmnet8" ] ; then
            test -c /dev/vmnet1 || mknod c 119 8 /dev/vmnet8
            # /etc/vmware/vmnet-natd-8.mac simply contains a mac like 00:50:56:F1:30:50
            $location/vmnet-natd -d /var/run/vmnet-natd-8.pid \
              -m /etc/vmware/vmnet-natd-8.mac -c /etc/vmware/nat.conf
            dhcpif="\$dhcpif vmnet8"
            ip addr add \$vmnet8 dev vmnet8
          fi
        }
        runvmdhcpd() {
          if [ -n "\$dhcpif" ] ; then
            # the path might be directly point to the plugin dir
            mkdir /var/run/vmware 2>/dev/null
            $location/vmnet-dhcpd -cf /etc/vmware/dhcpd.conf -lf \
              /var/run/vmware/dhcpd.leases -pf /var/run/vmnet-dhcpd-vmnet8.pid \$dhcpif
          fi
        }
        
        # Ubuntu
        # . /lib/lsb/init-functions
        # SuSE
        # . /etc/rc.status
        # rc_reset
        case \$1 in
          start)
            # SuSE
            echo -n "Starting vmware background services ..."
            # Ubuntu
            # log_begin_msg "Starting vmware background services ..."
            load_modules
            setup_vmnet0
            setup_vmnet1
            setup_vmnet8
            runvmdhcpd
            # message output should match the given vendor-os
            # Ubuntu ####
            # log_warning_msg "Not starting because of something ...
            # SuSE ####
            # rc_status -v
          ;;
          stop)
            # message output should match the given vendor-os
            echo -n "Stopping vmware background services ..."
            killall vmnet-netifup vmnet-natd vmnet-bridge vmware vmplayer \
              vmware-tray 2>/dev/null
            # wait for shutting down of interfaces
            usleep 50000
            unload_modules
            # SuSE
            # rc_status -v
          ;;
          status)
            echo "Say something useful here ..."
          ;;
        esac
        # Ubuntu
        exit 0
        # SuSE (10.2)
        # rc_exit
    End-of-Here

    # OLTA: this backup strategy is useless if invoked twice, so I have
    #       deactivated it
#    rename($file, "${file}.slx-bak") if -e $file;

    spitFile($file, $script);
}

1;
