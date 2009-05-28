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
# example.pm
#    - an example implementation of the OSPlugin API (i.e. an os-plugin)
# -----------------------------------------------------------------------------
package OpenSLX::OSPlugin::example;

use strict;
use warnings;

use base qw(OpenSLX::OSPlugin::Base);

use OpenSLX::Basics;
use OpenSLX::Utils;

################################################################################
# if you have any questions regarding the concept of OS-plugins and their
# implementation, please drop a mail to: ot@openslx.com, or join the IRC-channel
# '#openslx' (on freenode).
################################################################################
sub new
{
    my $class = shift;

    my $self = {
        name => 'example',
    };

    return bless $self, $class;
}

sub getInfo
{
    my $self = shift;

    return {
        description => unshiftHereDoc(<<'        End-of-Here'),
            just an exemplary plugin that prints a smiley when the client boots
        End-of-Here
        precedence => 50,
    };
}

sub getAttrInfo
{   # returns a hash-ref with information about all attributes supported
    # by this specific plugin
    my $self = shift;

    # This default configuration will be added as attributes to the default
    # system, such that it can be overruled for any specific system by means
    # of slxconfig.
    return {
        # attribute 'active' is mandatory for all plugins
        'example::active' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                should the 'example'-plugin be executed during boot?
            End-of-Here
            content_regex => qr{^(0|1)$},
            content_descr => '1 means active - 0 means inactive',
            default => '1',
        },

        # plugin specific attributes start here ...
        'example::preferred_side' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                determines to which side you have to tilt your head in order
                to read the smiley
            End-of-Here
            content_regex => qr{^(left|right)$},
            content_descr => q{'left' will print ';-)' - 'right' will print '(-;'},
            default => 'left',
        },
    };
}

sub installationPhase
{   # called while chrooted to the vendor-OS root in order to give the plugin
    # a chance to install required files into the vendor-OS.
    my $self = shift;
    my $info = shift;
    
    my $pluginRepoPath = $info->{'plugin-repo-path'};
        # The folder where the stage1-plugin should store all files
        # required by the corresponding stage3 runlevel script.
        # As this method is being executed while chrooted into the vendor-OS,
        # this path is relative to that root (i.e. directly usable).
    my $pluginTempPath = $info->{'plugin-temp-path'};
        # A temporary playground that will be cleaned up automatically.
        # As this method is being executed while chrooted into the vendor-OS,
        # this path is relative to that root (i.e. directly usable).
    my $openslxBasePath = $info->{'openslx-base-path'};
        # the openslx base path (/opt/openslx) bind-mounted into the chroot
    my $openslxConfigPath = $info->{'openslx-config-path'};
        # the openslx config path (/etc/opt/openlsx) bind-mounted into the 
        # chroot
    my $attrs = $info->{'plugin-attrs'};
        # attributes in effect for this installation
    
    # for this example plugin, we simply create two files:
    spitFile("$pluginRepoPath/right", "(-;\n");
    spitFile("$pluginRepoPath/left", ";-)\n");

    # Some plugins have to copy files from their plugin folder into the
    # vendor-OS. Here's an example for how to do that:
    #
    # # get our own name:
    # my $pluginName = $self->{'name'};
    #
    # # get our own base path:
    # my $pluginBasePath = "$openslxBasePath/lib/plugins/$pluginName";
    #     
    # # copy all needed files now:
    # foreach my $file ( qw( file1, file2 ) ) {
    #     copyFile("$pluginBasePath/$file", "$pluginRepoPath/");
    # }

    # name of current os
    # my $vendorOSName = $self->{'os-plugin-engine'}->{'vendor-os-name'} 

    return;
}

sub removalPhase
{   # called while chrooted to the vendor-OS root in order to give the plugin
    # a chance to uninstall no longer required files from the vendor-OS.
    my $self = shift;
    my $info = shift;
    
    my $pluginRepoPath = $info->{'plugin-repo-path'};
        # The folder where the stage1-plugin should store all files
        # required by the corresponding stage3 runlevel script.
        # As this method is being executed while chrooted into the vendor-OS,
        # this path is relative to that root (i.e. directly usable).
    my $pluginTempPath = $info->{'plugin-temp-path'};
        # A temporary playground that will be cleaned up automatically.
        # As this method is being executed while chrooted into the vendor-OS,
        # this path is relative to that root (i.e. directly usable).

    return;
}

1;
