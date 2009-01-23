# Copyright (c) 2006, 2007 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your suggestions, praise, or complaints to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org/
# -----------------------------------------------------------------------------
# desktop/OpenSLX/Distro/Suse.pm
#    - provides SUSE-specific overrides of the Distro API for the desktop
#      plugin.
# -----------------------------------------------------------------------------
package desktop::OpenSLX::Distro::Suse;

use strict;
use warnings;

use base qw(desktop::OpenSLX::Distro::Base);

use File::Path;

use OpenSLX::Basics;
use OpenSLX::Utils;

################################################################################
### interface methods
################################################################################

sub GDMPathInfo
{
    my $self = shift;
    
    my $pathInfo = $self->SUPER::GDMPathInfo();
    
    # create gdm.conf-custom instead of gdm.conf
    $pathInfo->{config} = '/etc/X11/gdm/gdm.conf-custom';

    return $pathInfo;
}

sub setupGDMScript
{
    my $self     = shift;
    my $repoPath = shift;

    my $script = $self->SUPER::setupGDMScript($repoPath);
    
    $script .= unshiftHereDoc(<<'    End-of-Here');
        rllinker xdm 1 1
        sed -i 's/DISPLAYMANAGER=.*/DISPLAYMANAGER="gdm"/' \
            /mnt/etc/sysconfig/displaymanager
        sed -i "s/DEFAULT_WM=.*/DEFAULT_WM=\"$desktop_kind\"/" \
            /mnt/etc/sysconfig/windowmanager
    End-of-Here

    return $script;
}

sub setupKDMScript
{
    my $self     = shift;
    my $repoPath = shift;

    # SUSE reads /var/adm/kdm/kdmrc.sysconfig, so we link that to
    # our config file
    my $pathInfo   = $self->GDMPathInfo();
    my $configFile = $pathInfo->{config};
    mkpath("/etc/opt/kdm");
    system("ln -sfn /etc/opt/kdm/kdmrc /var/adm/kdm/kdmrc.sysconfig");

    my $script = $self->SUPER::setupKDMScript($repoPath);
    
    $script .= unshiftHereDoc(<<'    End-of-Here');
        rllinker xdm 1 1
        sed -i 's/DISPLAYMANAGER=.*/DISPLAYMANAGER="kdm"/' \
            /mnt/etc/sysconfig/displaymanager
        sed -i "s/DEFAULT_WM=.*/DEFAULT_WM=\"$desktop_kind\"/" \
            /mnt/etc/sysconfig/windowmanager
    End-of-Here

    return $script;
}

1;
