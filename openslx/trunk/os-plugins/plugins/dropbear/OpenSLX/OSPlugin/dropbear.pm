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
# dropbear.pm
#    - an dropbear implementation of the OSPlugin API (i.e. an os-plugin)
# -----------------------------------------------------------------------------
package OpenSLX::OSPlugin::dropbear;

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
        name => 'dropbear',
    };

    return bless $self, $class;
}

sub getInfo
{
    my $self = shift;

    return {
        description => unshiftHereDoc(<<'        End-of-Here'),
            dropbear is a simple/small ssh daemon (for stage 3)
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
        'dropbear::active' => {
            applies_to_systems => 1,
            applies_to_clients => 0,
            description => unshiftHereDoc(<<'            End-of-Here'),
                should the 'dropbear'-plugin be executed during boot?
            End-of-Here
            content_regex => qr{^(0|1)$},
            content_descr => '1 means active - 0 means inactive',
            default => '1',
        },
    };
}

sub installationPhase
{
    my $self = shift;
    my $info = shift;

    my $pluginRepoPath = $info->{'plugin-repo-path'};
    my $pluginTempPath = $info->{'plugin-temp-path'};
    my $openslxBasePath = $info->{'openslx-base-path'};
    my $openslxConfigPath = $info->{'openslx-config-path'};
    my $attrs = $info->{'plugin-attrs'};

    my $filesDir = "$openslxBasePath/lib/plugins/dropbear/files";

	copyFile("$filesDir/bin/dropbear","$pluginRepoPath/bin");
	copyFile("$filesDir/bin/dropbearkey","$pluginRepoPath/bin");

    return;
}

sub removalPhase
{
    my $self = shift;
    my $info = shift;
    
    my $pluginRepoPath = $info->{'plugin-repo-path'};
    my $pluginTempPath = $info->{'plugin-temp-path'};

    return;
}

1;
