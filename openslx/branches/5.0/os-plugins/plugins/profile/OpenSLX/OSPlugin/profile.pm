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
# profile.pm
# -----------------------------------------------------------------------------
package OpenSLX::OSPlugin::profile;

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
        name => 'profile',
    };

    return bless $self, $class;
}

sub getInfo
{
    my $self = shift;

    return {
        description => unshiftHereDoc(<<'        End-of-Here'),
            profile plugin ..
        End-of-Here
        precedence => 82, 
    };
}

sub getAttrInfo
{
    my $self = shift;

    return {
        # attribute 'active' is mandatory for all plugins
        'profile::active' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                should the 'profile'-plugin be executed during boot?
            End-of-Here
            content_regex => qr{^(0|1)$},
            content_descr => '1 means active - 0 means inactive',
            default => '1',
        },
    };
}

sub _writeKdehomeEnv
{
    my $self = shift;
	
    my $profileFile = unshiftHereDoc(<<'    End-of-Here');
        # Do not modify this file.
        # File generated by profile plugin.
        # For more information have a look at
        # http://lab.openslx.org/wiki/openslx/profile
        
        export KDEHOME=${HOME}/%s
    End-of-Here
    
    $profileFile = sprintf(
        $profileFile,
        $self->{distro}->getKdeHome()
    );
    
    spitFile($self->{distro}->getProfileDPAth(), $profileFile);
    
    return $self->{distro}->getKdeHome();
}

sub _modifyGconfPaths
{
    my $self = shift;

    my $cmd = "sed -i \"s,readwrite:\\\$(HOME)/.gconf,readwrite:\\\$(HOME)/%s,\" %s";
    $cmd = sprintf (
        $cmd, 
        $self->{distro}->getGconfHome(),
        $self->{distro}->getGconfPathConfig()
    );
    
    slxsystem($cmd);

    return $self->{distro}->getGconfHome();
}

sub _writeXsessionScript
{
    my $self = shift;
    my @paths = @_;

    my $xsessionFile= unshiftHereDoc(<<'    End-of-Here');
        # Do not modify this file.
        # File generated by profile plugin.
        # For more information have a look at
        # http://lab.openslx.org/wiki/openslx/profile

        %s
    End-of-Here

    my $cmd = "mkdir -p ";

    while (@paths) {
        my $path = shift(@paths);
        $cmd .= "\${HOME}/$path \\\n";
    }

    $cmd .= "> /dev/null 2>&1 \n";

    $xsessionFile = sprintf(
         $xsessionFile,
         $cmd
    );

    spitFile($self->{distro}->getXsessionDPath(), $xsessionFile);

    return;
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
    
    if (!$self->{distro}->isStable()) {
        vlog(
            0,
            _tr(
                "profile plugin is only stable for ubuntu!"
            )
        );
        die();
    }

    my @slxHomeEnv;

    push (@slxHomeEnv, $self->_writeKdehomeEnv());
    push (@slxHomeEnv, $self->_modifyGconfPaths());    
    
    $self->_writeXsessionScript(@slxHomeEnv);

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
