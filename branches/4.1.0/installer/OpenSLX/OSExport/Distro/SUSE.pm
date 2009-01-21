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
# SUSE.pm
#	- provides SUSE-specific overrides of the OpenSLX OSExport API.
# -----------------------------------------------------------------------------
package OpenSLX::OSExport::Distro::SUSE;

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
		- /var/lib/YaST2/you/mnt/*
		- /var/cache/yum
		- /var/cache/man/*
		- /var/adm/backup/rpmdb/*
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
		- /media/*
		+ /media
		+ /lib/modules/*/misc/vmblock.o
		+ /lib/modules/*/misc/vmnet.o
		+ /lib/modules/*/misc/vmmon.o
		- /etc/dhcpd.conf*
		- /etc/cron.*/*
		- /etc/X11/xdm/SuSEconfig.xdm
		- /boot/initrd*
		- /boot/grub
		- *.rpmsave
		- *.rpmnew
		- *.YaST2save
	";
}

1;
