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
# infoscreen.pm
# -----------------------------------------------------------------------------
package OpenSLX::OSPlugin::infoscreen;

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
        name => 'infoscreen',
    };

    return bless $self, $class;
}

sub getInfo
{
    my $self = shift;

    return {
        description => unshiftHereDoc(<<'        End-of-Here'),
            infoscreen plugin ..
        End-of-Here
        precedence => 82, 
    };
}

sub getAttrInfo
{
    my $self = shift;

    return {
        # attribute 'active' is mandatory for all plugins
        'infoscreen::active' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                should the 'infoscreen'-plugin be executed during boot?
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

    my $filesDir = "$openslxBasePath/lib/plugins/infoscreen/files";
    
    copyFile("$filesDir/empty.xbm","$pluginRepoPath");
    copyFile("$filesDir/kiosk.dpms","$pluginRepoPath");
    

    my @requirements = $self->{distro}->getRequirements();

    my $pcmd = $self->{distro}->getPackagemanagerCommand();
    my $req = join(' ', @requirements);
    
    slxsystem("$pcmd $req") or _tr(
        "failed to install requirements"
    );
    
    slxsystem("tar -xzf $filesDir/infoscreenClient.tgz -C / ");
    
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
