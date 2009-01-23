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
# OSExport/Distro/Suse.pm
#    - provides SUSE-specific overrides of the OSExport Distro API.
# -----------------------------------------------------------------------------
package OpenSLX::OSExport::Distro::Suse;

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
        'base-name' => 'suse',
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
        - /var/lib/zypp/*
        - /var/lib/zmd
        - /var/lib/xdm
        - /var/lib/vm*
        - /var/lib/suspend*
        - /var/lib/smart
        - /var/lib/sax
        - /var/lib/hardware/*
        - /var/lib/gdm/*
        - /var/lib/dhcp*
        - /var/lib/bluetooth/
        - /var/lib/YaST2/you/mnt/*
        - /var/lib/YaST2/backup_boot_sectors
        - /var/cache/sax
        - /var/cache/libx11/compose/*
        - /var/cache/beagle
        - /var/cache/yum
        - /var/cache/man/*
        - /var/cache/zypp/*
        - /var/adm/backup/rpmdb/*
        - /var/adm/mount/AP*
        - /var/adm/SuSEconfig
        - /usr/share/vmware/*
        - /usr/lib/zen-updater
        + /usr/lib/python*/*/*.o
        + /usr/lib/perl5/*/*/*/*.o
        + /usr/lib/gcc/*/*/*.o
        + /usr/lib/*.o
        + /usr/X11R6/lib/modules/drivers/*.o
        + /usr/X11R6/lib/modules/drivers/linux/*.o
        - /usr/bin/zen-*
        - /usr/bin/nw-manager
        - /usr/X11R6/bin/BackGround
        - /usr/bin/BackGround
        - /usr/share/autostart/SUSEgreeter.desktop
        - /tmp/*
        - /sys/*
        - /proc/*
        - /opt/kde3/share/apps/kdm/read_sysconfig.sh
        - /opt/kde3/share/autostart/suseplugger.desktop
        - /opt/kde3/share/autostart/susewatcher.desktop
        - /opt/kde3/share/autostart/runupdater.desktop
        - /opt/kde3/share/autostart/profile_chooser-autostart.desktop
        - /opt/kde3/share/autostart/opensuseupdater.desktop
        - /opt/kde3/share/autostart/knetworkmanager-autostart.desktop
        - /opt/kde3/share/autostart/kerry.autostart.desktop
        - /opt/kde3/share/autostart/kinternet.desktop
        - /opt/kde3/share/autostart/beagled.desktop
        - /opt/kde3/share/autostart/SUSEgreeter.desktop
        - /opt/kde3/share/autostart/zen-updater-auto.desktop
        - /opt/gnome/share/autostart/beagle*.desktop
        - /opt/gnome/share/gnome/autostart/beagle*.desktop
        - /usr/share/gnome/autostart/gpk-update-icon*.desktop
        - /mnt/*
        - /media/*
        + /media
        + /lib/modules/*/misc/vmblock.o
        + /lib/modules/*/misc/vmnet.o
        + /lib/modules/*/misc/vmmon.o
        - /etc/*rpmnew
        - /etc/*rpmorig
        - /etc/*YaST2save
        - /etc/*pptp*
        - /etc/*ppp*
        - /etc/dhcp*
        - /etc/cron.*/*
        - /etc/sysconfig/network/ifcfg-*
        - /etc/X11/xdm/SuSEconfig.xdm
        - /boot/initrd*
        - /boot/grub
        - *.rpmsave
        - *.rpmnew
        - *.YaST2save
    ";
    return;
}

1;
