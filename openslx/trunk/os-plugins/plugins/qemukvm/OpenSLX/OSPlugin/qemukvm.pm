# Copyright (c) 2009 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your suggestions, praise, or complaints to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org/
# -----------------------------------------------------------------------------
# qemukvm.pm
#    - Declares necessary information for the qemukvm plugin
# -----------------------------------------------------------------------------
package OpenSLX::OSPlugin::qemukvm;

use strict;
use warnings;

use base qw(OpenSLX::OSPlugin::Base);

use File::Basename;
use File::Path;

use OpenSLX::Basics;
use OpenSLX::Utils;
use OpenSLX::DistroUtils;

sub new
{
    my $class = shift;
    my $self = {
        name => 'qemukvm',
    };

    return bless $self, $class;
}

sub getInfo
{
    my $self = shift;

    return {
        description => unshiftHereDoc(<<'        End-of-Here'),
           Module for enabling services for the Linux kvm using qemu for
           IO on an OpenSLX stateless client.
        End-of-Here
        precedence => 70,
        required => [ qw( desktop ) ],
    };
}

sub getAttrInfo
{
    # Returns a hash-ref with information about all attributes supported
    # by this specific plugin
    my $self = shift;

    # This default configuration will be added as attributes to the default
    # system, such that it can be overruled for any specific system by means
    # of slxconfig.
    return {
        # attribute 'active' is mandatory for all plugins
        'qemukvm::active' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                should the 'qemukvm'-plugin be executed during boot?
            End-of-Here
            content_regex => qr{^(0|1)$},
            content_descr => '1 means active - 0 means inactive',
            default => '1',
        },
        # attribute 'imagesrc' defines where we can find qemukvm images
        'qemukvm::imagesrc' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                Where do we store our qemukvm images? NFS? Filesystem?
            End-of-Here
            #TODO: check if the input is valid
            #content_regex => qr{^(0|1)$},
            content_descr => 'Allowed values: local path or URI',
            default => '',
        },
        # attribute 'bridge' defines if bridged network mode should be
        # switched on
        'qemukvm::bridge' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                Should the bridging (direct access of the qemukvm clients
                to the ethernet the host is connected to) be enabled
            End-of-Here
            content_regex => qr{^(0|1)$},
            content_descr => 'Allowed values: 0 or 1',
            default => '1',
        },

    };
}

sub installationPhase
{
    my $self = shift;
    my $info = shift;
    
    $self->{pluginRepositoryPath} = $info->{'plugin-repo-path'};
    $self->{pluginTempPath}       = $info->{'plugin-temp-path'};
    $self->{openslxBasePath}      = $info->{'openslx-base-path'};
    $self->{openslxConfigPath}    = $info->{'openslx-config-path'};
    $self->{attrs}                = $info->{'plugin-attrs'};

    my $engine = $self->{'os-plugin-engine'};
    my $pluginRepoPath = "$self->{pluginRepositoryPath}";
    
    # Different names of the tool (should be unified somehow!?)
    if (!isInPath('qemu-kvm') || !isInPath('kvm')) {
        $engine->installPackages(
            $engine->getInstallablePackagesForSelection('qemu-kvm')
        );
    }
    # Sudo is needed to get access to certain system network commands
    if (!isInPath('sudo')) {
        $engine->installPackages($self->{distro}->getPackageName('sudo'));
    }
    # Copy run-virt.include to the appropriate place for inclusion in stage4
    copyFile("$self->{openslxBasePath}/lib/plugins/qemukvm/files/run-virt.include",
        "$self->{pluginRepositoryPath}/");
    # Copy the later /etc/qemu-ifup,down
    copyFile("$self->{openslxBasePath}/lib/plugins/qemukvm/files/qemu-if*",
        "$self->{pluginRepositoryPath}/");

    my $initFile = newInitFile();
    $initfile->setDesc("Setup environment for QEMU/KVM");
    my $do_start = unshiftHereDoc(<<'    End-of-Here');
          # Adding the tap0 interface to the existing bridge configured in stage3
          for i in 0 1 2; do
            /opt/openslx/uclib-rootfs/sbin/tunctl -t tap${i} >/dev/null 2>&1
            ip link set dev tap${i} up
          done
          /opt/openslx/uclib-rootfs/usr/sbin/brctl addif br0 tap0
          echo "1" >/proc/sys/net/ipv4/conf/br0/forwarding
          echo "1" >/proc/sys/net/ipv4/conf/tap0/forwarding
    End-of-Here
    my $do_stop = unshiftHereDoc(<<'    End-of-Here');
          /opt/openslx/uclib-rootfs/usr/sbin/brctl delif br0 tap0
          echo "0" >/proc/sys/net/ipv4/conf/br0/forwarding
          echo "0" >/proc/sys/net/ipv4/conf/tap0/forwarding
    End-of-Here
   
    # add helper functions to initfile
    # first parameter name of the function
    # second parameter content of the function
    $initFile->addFunction('do_start', $do_start);
    $initFile->addFunction('do_stop', $do_stop);
    $initFile->addFunction('do_restart', "  : # do nothing here");
    
    # place a call of the helper function in the stop block of the init file
    # first parameter name of the function
    # second parameter name of the block
    $initFile->addFunctionCall('do_start', 'start');
    $initFile->addFunctionCall('do_stop', 'stop');
    $initFile->addFunctionCall('do_restart', 'restart');
    
    my $distro = (split('-',$self->{'os-plugin-engine'}->distroName()))[0];
    
    # write qemukvm initfile to plugin path
    spitFile(
        "$pluginRepoPath/qemukvm",
        getInitFileForDistro($initFile, ucfirst($distro))
    );
    return;
}

sub removalPhase
{
    my $self = shift;
    my $info = shift;

    return;
}

sub checkStage3AttrValues
{
    my $self          = shift;
    my $stage3Attrs   = shift;
    my $vendorOSAttrs = shift;
    #my @problems;

    #my $vmimg = $stage3Attrs->{'qemukvm::imagesrc'} || '';

    return;
}

# The bridge configuration needs the bridge module to be present in early
# stage3
sub suggestAdditionalKernelModules
{
    my $self                = shift;
    my $makeInitRamFSEngine = shift;

    my @suggestedModules;

    push @suggestedModules, qw( bridge );

    return @suggestedModules;
}

1;
