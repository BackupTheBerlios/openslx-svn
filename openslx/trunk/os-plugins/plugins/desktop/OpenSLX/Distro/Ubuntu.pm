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
# desktop/OpenSLX/Distro/Ubuntu.pm
#    - provides Ubuntu-specific overrides of the distro API for the desktop
#      plugin.
# -----------------------------------------------------------------------------
package desktop::OpenSLX::Distro::Ubuntu;

use strict;
use warnings;

use base qw(desktop::OpenSLX::Distro::Base);

use OpenSLX::Basics;
use OpenSLX::Utils;

################################################################################
### interface methods
################################################################################

sub GDMPathInfo
{
    my $self = shift;
    
    my $pathInfo = $self->SUPER::GDMPathInfo();
    
    # link gdm.conf-custom instead of gdm.conf
    $pathInfo->{config} = '/etc/gdm/gdm.conf-custom';

    return $pathInfo;
}

sub setupGDMScript
{
    my $self     = shift;
    my $repoPath = shift;

    my $script = $self->SUPER::setupGDMScript($repoPath);

    my $configFile = $self->GDMPathInfo->{config};
    
    $script .= unshiftHereDoc(<<"    End-of-Here");
        rllinker gdm 1 10
        echo '/usr/sbin/gdm' >/mnt/etc/X11/default-display-manager
        chroot /mnt update-alternatives --set x-window-manager /usr/bin/metacity
        chroot /mnt update-alternatives --set x-session-manager \\
          /usr/bin/gnome-session
        testmkd /mnt/var/lib/gdm root:gdm 1770
        sed '/^\\[daemon\\]/ a\\BaseXsession=/etc/gdm/Xsession' \\
          -i /mnt$configFile
    End-of-Here

    return $script;
}

sub KDMPathInfo
{
    my $self = shift;
    
    my $pathInfo = $self->SUPER::KDMPathInfo();
    
    $pathInfo = {
        config => '/etc/kde3/kdm/kdmrc',
        paths => [
            '/var/lib/kdm',
            '/var/run/kdm',
        ],
    };

    return $pathInfo;
}

sub KDMConfigHashForWorkstation
{
    my $self = shift;
    
    my $configHash = $self->SUPER::KDMConfigHashForWorkstation();
    $configHash->{'General'}->{PidFile} = '/var/run/kdm.pid';
    $configHash->{'X-:0-Core'}->{Setup} = '/etc/kde3/kdm/Xsetup';
    $configHash->{'X-:0-Core'}->{Startup} = '/etc/kde3/kdm/Xstartup';
    $configHash->{'X-:0-Core'}->{Session} = '/etc/kde3/kdm/Xsession';
    $configHash->{'X-:0-Core'}->{Reset} = '/etc/kde3/kdm/Xreset';

    return $configHash;
}

sub setupKDMScript
{
    my $self     = shift;
    my $repoPath = shift;

    my $script = $self->SUPER::setupKDMScript($repoPath);
    
    $script .= unshiftHereDoc(<<'    End-of-Here');
        rllinker kdm 1 10
        echo '/usr/bin/kdm' >/mnt/etc/X11/default-display-manager
        chroot /mnt update-alternatives --set x-window-manager /usr/bin/kwin
        chroot /mnt update-alternatives --set x-session-manager \
          /usr/bin/startkde
    End-of-Here

    return $script;
}
1;
