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
# OSExport/Distro/Ubuntu.pm
#    - provides Ubuntu-specific overrides of the OSExport Distro API.
# -----------------------------------------------------------------------------
package OpenSLX::OSExport::Distro::Ubuntu;

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
        'base-name' => 'ubuntu',
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
        - /var/log/*
        - /var/lib/xdm
        - /var/cache/apt/archives/*
        - /var/cache/man/*
        - /var/cache/nscd/*
        - /usr/share/vmware/*
        - /usr/share/autostart/trackerd.desktop
        - /usr/share/autostart/knetworkmanager.desktop
        - /tmp/*
        - /sys/*
        - /proc/*
        - /mnt/*
        - /media/*
        - /lib/udev/devices
        - /initrd*
        - /etc/cron.*/*
        - /boot/initrd*
        - /boot/grub
        - /etc/xdg/compiz
        - /etc/xdg/autostart/adept_notifier_auto.desktop
        - /etc/xdg/autostart/evolution*alarm*notify*
        - /etc/xdg/autostart/knetworkmanager*
        - /etc/xdg/autostart/nm-applet.desktop
        - /etc/xdg/autostart/system-config-printer-applet-kde.desktop
        - /etc/xdg/autostart/tracker*
        - /etc/xdg/autostart/jockey-*
        - /etc/xdg/autostart/ica*
        - /etc/xdg/autostart/hplip*
        - /etc/xdg/autostart/redhat*
        - /etc/xdg/autostart/gnome-power-manager*
        - /etc/xdg/autostart/update*
        - /etc/xdg/update-notifier.desktop
        - /etc/xdg/user-dirs-update-gtk.desktop
    ";
    return;
}

1;
