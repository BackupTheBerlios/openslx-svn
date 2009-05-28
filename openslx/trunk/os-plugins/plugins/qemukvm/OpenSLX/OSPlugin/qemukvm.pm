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
    
    # Different names of the tool (should be unified somehow!?)
    if (!isInPath('qemu-kvm') || !isInPath('kvm')) {
        $engine->installPackages(
            $engine->getInstallablePackagesForSelection('qemu-kvm')
        );
    }
    # Copy run-virt.include to the appropriate place for inclusion in stage4
    copyFile("$self->{openslxBasePath}/lib/plugins/qemukvm/files/run-virt.include",
        "$self->{pluginRepositoryPath}/");

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

# Write the runlevelscript
sub _writeRunlevelScript
{
    my $self     = shift;
    my $location = shift;
    my $file     = shift;
    my $kind     = shift;
    
    my $runlevelScript = $self->{distro}->fillRunlevelScript($location, $kind);

    spitFile($file, $runlevelScript);
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
