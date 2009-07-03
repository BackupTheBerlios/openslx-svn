# Copyright (c) 2006..2009 - OpenSLX GmbH
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

    $script .= unshiftHereDoc(<<'    End-of-Here');
        # cleanup after users Xorg session
        sed 's,^#!.*,,' /mnt/etc/gdm/PostSession/Default \
          >/mnt/etc/gdm/PostSession/Default.system
        echo -e '#! /bin/sh\n#\n# modified by desktop plugin in Stage3\n#\n
        # remove safely any remaining files of the leaving user in /tmp
        ( su -c "rm -rf /tmp/*"
          echo "$USER files removed by $0" >/tmp/files.removed 2>/dev/null ) &
        . /etc/gdm/PostSession/Default.system' >/mnt/etc/gdm/PostSession/Default
        chmod a+x /mnt/etc/gdm/PostSession/Default*
        # gdm should be started after dbus/hal
        rllinker gdm 5 10
        echo '/usr/sbin/gdm' >/mnt/etc/X11/default-display-manager
        chroot /mnt update-alternatives --set x-window-manager /usr/bin/metacity
        chroot /mnt update-alternatives --set x-session-manager \
          /usr/bin/gnome-session
        # gdm does not like AUFS/UnionFS on its var directory
        rm -rf /mnt/var/lib/gdm
        mkdir -m 1770 /mnt/var/lib/gdm
        chown root:gdm /mnt/var/lib/gdm
        sed '/^\\[daemon\\]/ a\\BaseXsession=/etc/gdm/Xsession' \
          -i /mnt$configFile
    End-of-Here

    return $script;
}

sub KDMVersion
{
    my $self = shift;
    my $vendorOSName = $self->{'engine'}->{'vendor-os-name'};

    my $kdmVer;
    if ( $vendorOSName =~ /ubuntu-8.04.*/ ) {
        $kdmVer = "3";
    }
    else {
        $kdmVer = "4";
    }

    return $kdmVer;

}

sub KDMPathInfo
{
    my $self = shift;

    my $pathInfo = $self->SUPER::KDMPathInfo();
    my $kdmVer = $self->KDMVersion();

    $pathInfo = {
        config => "/etc/kde$kdmVer/kdm/kdmrc",
        paths => [
            '/var/lib/kdm',
            '/var/run/kdm',
        ],
    };

    return $pathInfo;
}

sub GDMConfigHashForWorkstation
{
    my $self = shift;

    my $configHash = $self->SUPER::GDMConfigHashForWorkstation();
    $configHash->{'daemon'}->{SessionDesktopDir} = 
        '/etc/X11/sessions/:/usr/share/xsessions/:/usr/share/gdm/BuiltInSessions/';

    return $configHash;
}

sub KDMConfigHashForWorkstation
{
    my $self = shift;
    
    my $kdmVer = $self->KDMVersion();
    my $configHash = $self->SUPER::KDMConfigHashForWorkstation();
    $configHash->{'General'}->{PidFile} = "/var/run/kdm.pid";
    $configHash->{'X-:0-Core'}->{Setup} = "/etc/kde$kdmVer/kdm/Xsetup";
    $configHash->{'X-:0-Core'}->{Startup} = "/etc/kde$kdmVer/kdm/Xstartup";
    $configHash->{'X-:0-Core'}->{Session} = "/etc/kde$kdmVer/kdm/Xsession";
    $configHash->{'X-:0-Core'}->{Reset} = "/etc/kde$kdmVer/kdm/Xreset";
    $configHash->{'X-:0-Core'}->{SessionsDirs} = 
        '/etc/X11/sessions,/usr/share/xsessions,/usr/share/apps/kdm/sessions';

    return $configHash;
}

sub setupKDMScript
{
    my $self     = shift;
    my $repoPath = shift;

    my $kdmVer = $self->KDMVersion();
    my $script = $self->SUPER::setupKDMScript($repoPath);

     # change default theme to openslx-legacy if kdm3
    if ( $kdmVer == "3" ) {
        print "  * Please change to openslx-legacy theme when using kdm3\n";
    }

    $script .= "kdmver=$kdmVer\n";
    $script .= unshiftHereDoc(<<'    End-of-Here');

        # cleanup after users Xorg session
        sed 's,^#!.*,,' /mnt/etc/kde$kdmver/kdm/Xreset \
          >/mnt/etc/kde$kdmver/kdm/Xreset.system
        echo -e '#! /bin/sh\n#\n# modified by desktop plugin in Stage3\n#\n
        # remove safely any remaining files of the leaving user in /tmp
        ( su -c "rm -rf /tmp/*" - $USER
          echo "$USER files removed by $0" >/tmp/files.removed 2>/dev/null ) &
        . /etc/kde$kdmver/kdm/Xreset.system' >/mnt/etc/kde$kdmver/kdm/Xreset
        chmod a+x /mnt/etc/kde$kdmver/kdm/Xreset*

        rllinker kdm 1 10
        echo '/usr/bin/kdm' > /mnt/etc/X11/default-display-manager
        chroot /mnt update-alternatives --set x-window-manager /usr/bin/kwin
        chroot /mnt update-alternatives --set x-session-manager \
          /usr/bin/startkde
    End-of-Here

    return $script;
}

1;
