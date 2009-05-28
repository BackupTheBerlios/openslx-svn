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
# desktop/OpenSLX/Distro/Scilin.pm
#    - provides Scilin-specific overrides of the Distro API for the desktop
#      plugin.
# -----------------------------------------------------------------------------
package desktop::OpenSLX::Distro::Scilin;

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
    $pathInfo->{config} = '/etc/gdm/custom.conf';

    return $pathInfo;
}

sub setupGDMScript
{
    my $self     = shift;
    my $repoPath = shift;

    my $script = $self->SUPER::setupGDMScript($repoPath);

    my $configFile = $self->GDMPathInfo->{config};

    # include common stuff (independent of display manager used)
    $script = _setupCommonDmScript($script);

    $script .= unshiftHereDoc(<<'    End-of-Here');
        echo "DISPLAYMANAGER=GNOME" \
            >/mnt/etc/sysconfig/desktop
        testmkd /mnt/var/gdm root:gdm 1770
    End-of-Here

    return $script;
}

sub GDMConfigHashForWorkstation
{
    my $self = shift;

    my $configHash = $self->SUPER::GDMConfigHashForWorkstation();
    $configHash->{'daemon'}->{SessionDesktopDir} =
        '/etc/X11/sessions/:/usr/share/xsessions/:/usr/share/gdm/BuiltInSessions';
    $configHash->{'daemon'}->{Greeter} =
        '/usr/libexec/gdmgreeter';

    return $configHash;
}

sub setupKDMScript
{
    my $self     = shift;
    my $repoPath = shift;

    # SUSE reads /var/adm/kdm/kdmrc.sysconfig, so we link that to
    # our config file
    my $pathInfo   = $self->KDMPathInfo();
    my $configFile = $pathInfo->{config};
    mkpath("/etc/opt/kdm");
    mkpath("/var/adm/kdm");
    # maybe backup kdmrc.sysconfig sometimes
    unlink("/var/adm/kdm/kdmrc.sysconfig");
    # the config file gets overwritten if this script is present
    unlink("/opt/kde3/share/apps/kdm/read_sysconfig.sh");
    symlink("/etc/opt/kdm/kdmrc", "/var/adm/kdm/kdmrc.sysconfig");

    my $script = $self->SUPER::setupKDMScript($repoPath);

    # include common stuff (independent of display manager used)
    $script = _setupCommonDmScript($script);

    $script .= unshiftHereDoc(<<'    End-of-Here');
        echo "DISPLAYMANAGER=KDE" \
            >/mnt/etc/sysconfig/desktop
    End-of-Here

    return $script;
}

sub _setupCommonDmScript
{
    my $script = shift;

    $script .= unshiftHereDoc(<<'    End-of-Here');
        # cleanup after users Xorg session
        sed 's,^#!.*,,' /mnt/etc/X11/xdm/Xreset \
          > /mnt/etc/X11/xdm/Xreset.system
        echo -e '#!/bin/sh\n#\n# modified by desktop plugin in Stage3\n#\n
        # remove safely any remaining files of the leaving user in /tmp
        ( su -c "rm -rf /tmp/*" - $USER
          echo "$USER files removed by $0" >/tmp/files.removed 2>/dev/null ) &
        . /etc/X11/xdm/Xreset.system' >/mnt/etc/X11/xdm/Xreset
        chmod a+x /mnt/etc/X11/xdm/Xreset*

    End-of-Here

    return $script;
}

1;
