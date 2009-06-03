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
# kiosk.pm
# -----------------------------------------------------------------------------
package OpenSLX::OSPlugin::kiosk;

use strict;
use warnings;

use base qw(OpenSLX::OSPlugin::Base);

use File::Path;

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
        name => 'kiosk',
    };
    
    mkpath("$openslxConfig{'config-path'}/plugins/kiosk/profiles");
    
    return bless $self, $class;
}

sub getInfo
{
    my $self = shift;

    return {
        description => unshiftHereDoc(<<'        End-of-Here'),
            kiosk plugin ..
        End-of-Here
        precedence => 50,
    };
}

sub getAttrInfo
{
    my $self = shift;

    return {
        # attribute 'active' is mandatory for all plugins
        'kiosk::active' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                should the 'kiosk'-plugin be executed during boot?
            End-of-Here
            content_regex => qr{^(0|1)$},
            content_descr => '1 means active - 0 means inactive',
            default => '1',
        },
        'kiosk::profile' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                should the 'kiosk'-plugin setup a specific profile for the
                kiosk user? (profile data should be placed in 
                /etc/opt/openslx/plugins/kiosk/profiles/<profilename>/)
            End-of-Here
            #content_regex => qr{^(0|1)$},
            content_descr => 'name of profile',
            default => 'plain',
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

    my $filesDir = "$openslxBasePath/lib/plugins/kiosk/files";

	copyFile("$filesDir/kgetty","$pluginRepoPath");
	
	system(qq{cp -r $filesDir/profiles/* $openslxConfig{'config-path'}/plugins/kiosk/profiles/});
	
    my $scriptpath = "$pluginRepoPath/setup.kgetty";
	my $script = $self->{distro}->getKgettySetupScript();

    spitFile($scriptpath, $script);
    chmod (0744, "$scriptpath");

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
