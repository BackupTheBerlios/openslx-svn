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
        # vmware files!!
        # attribute 'binaries' defines whether or not VMware binaries shall
        # be provided (by downloading them).
        'vmware::binaries' => {
            applies_to_vendor_os => 1,
            applies_to_systems => 0,
            applies_to_clients => 0,
            description => unshiftHereDoc(<<'            End-of-Here'),
                Shall VMware binaries be downloaded and installed?
            End-of-Here
            content_regex => qr{^(0|1)$},
            content_descr => 'Allowed values: 0 or 1',
            default => '1',
        },

    };
}

sub installationPhase
{
    my $self                 = shift;
    
    $self->{pluginRepositoryPath} = shift;
    $self->{pluginTempPath}       = shift;
    $self->{openslxPath}          = shift;
    $self->{attrs}                = shift;

    # get path of files we need to install
    my $pluginFilesPath = "$self->{'openslxPath'}/lib/plugins/$self->{'name'}/files";

    # copy all needed files now
    my @files = qw( vmware-init nvram.5.0 runvmware-v2 );
    foreach my $file (@files) {
        copyFile("$pluginFilesPath/$file", $self->{'pluginRepositoryPath'});
    }
}

sub removalPhase
{
    my $self                 = shift;
    my $pluginRepositoryPath = shift;
    my $pluginTempPath       = shift;
    
    rmtree ( [ $pluginRepositoryPath ] );
    
    return;
}

1;
