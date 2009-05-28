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
        echo -e '# changed by $0 during stage3 setup\nDISPLAYMANAGER="gdm"' \
          >/mnt/etc/sysconfig/displaymanager
        sed -i "s/DEFAULT_WM=.*/DEFAULT_WM=\"$desktop_kind\"/" \
            /mnt/etc/sysconfig/windowmanager
        #sed "s|XSESSION|/etc/xdm/Xsession|" -i /mnt$configFile
        testmkd /mnt/var/lib/gdm gdm:gdm 1775
        # no use for this configuration info file
        rm /mnt/etc/gdm/gdm_sysconfig.* 2>/dev/null
    End-of-Here

    return $script;
}

sub GDMConfigHashForWorkstation
{
    my $self = shift;

    my $configHash = $self->SUPER::GDMConfigHashForWorkstation();
    $configHash->{'daemon'}->{SessionDesktopDir} =
        '/etc/X11/sessions/:/usr/share/xsessions/';
    $configHash->{'daemon'}->{DefaultSession} = 'default.desktop';
    $configHash->{'daemon'}->{Greeter} =
        '/usr/lib/gdm/gdmgreeter';

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
        sed -i 's/DISPLAYMANAGER=.*/DISPLAYMANAGER="kdm"/' \
            /mnt/etc/sysconfig/displaymanager
        [ $(grep -q DISPLAYMANAGER /mnt/etc/sysconfig/displaymanager) ] && \
            echo "DISPLAYMANAGER=\"kdm\"" >> /mnt/etc/sysconfig/displaymanager
        sed -i "s/DEFAULT_WM=.*/DEFAULT_WM=\"$desktop_kind\"/" \
            /mnt/etc/sysconfig/windowmanager
    End-of-Here

    return $script;
}

sub _setupCommonDmScript
{
    my $script = shift;

    $script .= unshiftHereDoc(<<'    End-of-Here');
        rllinker xdm 1 10
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
