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
# OSExport/Distro/SciLin.pm
#    - provides SciLin-specific overrides of the OSExport Distro API.
# -----------------------------------------------------------------------------
package OpenSLX::OSExport::Distro::SciLin;

use strict;
use warnings;

use base qw(OpenSLX::OSExport::Distro::Base);

use OpenSLX::Basics;

################################################################################
### implementation
################################################################################
sub new
{
    my $class = shift;
    my $self = {
        'base-name' => 'scilin',
    };
    return bless $self, $class;
}

sub initDistroInfo
{
    my $self = shift;

    $self->{'export-filter'} = "
        - /var/tmp/*
        - /var/spool/*
        - /var/run/*
        - /var/mail
        - /var/log/*
        - /var/lock/*
        - /var/lib/xdm
        - /var/lib/vm*
        - /var/lib/suspend*
        - /var/lib/smart
        - /var/lib/gdm/*
        - /var/lib/dhcp*
        - /var/lib/bluetooth/
        - /var/cache/yum
        - /var/cache/man/*
        - /var/cache/zypp/*
        + /usr/lib/python*/*/*.o
        + /usr/lib/perl5/*/*/*/*.o
        + /usr/lib/gcc/*/*/*.o
        + /usr/lib/*.o
        + /usr/X11R6/lib/modules/drivers/*.o
        + /usr/X11R6/lib/modules/drivers/linux/*.o
        - /usr/bin/BackGround
        - /tmp/*
        - /sys/*
        - /proc/*
        - /opt/kde3/share/apps/kdm/read_sysconfig.sh
        - /opt/kde3/share/autostart/runupdater.desktop
        - /opt/kde3/share/autostart/profile_chooser-autostart.desktop
        - /opt/kde3/share/autostart/kinternet.desktop
        - /usr/share/gnome/autostart/gpk-update-icon*.desktop
        - /mnt/*
        - /media/*
        + /media
        + /lib/modules/*/misc/vmblock.o
        + /lib/modules/*/misc/vmnet.o
        + /lib/modules/*/misc/vmmon.o
        - /etc/*rpmnew
        - /etc/*rpmorig
        - /etc/*pptp*
        - /etc/*ppp*
        - /etc/dhcp*
        - /etc/cron.*/*
		- /etc/netplug*
        - /etc/sysconfig/network*
        - /etc/X11/xkb
		- /boot/initrd*
        - /boot/grub
        - *.rpmsave
        - *.rpmnew
    ";
    return;
}

1;
