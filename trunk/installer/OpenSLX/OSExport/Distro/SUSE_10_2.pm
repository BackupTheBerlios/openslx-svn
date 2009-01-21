# SUSE_10_2.pm
#	- provides SUSE-10.2-specific overrides of the OpenSLX OSExport API.
#
# (c) 2006 - OpenSLX.com
#
# Oliver Tappe <ot@openslx.com>
#
package OpenSLX::OSExport::Distro::SUSE_10_2;

use vars qw(@ISA $VERSION);
@ISA = ('OpenSLX::OSExport::Distro::Base');
$VERSION = 1.01;		# API-version . implementation-version

use strict;
use Carp;
use OpenSLX::Basics;
use OpenSLX::OSExport::Distro::Base 1.01;

################################################################################
### implementation
################################################################################
sub new
{
	my $class = shift;
	my $self = {
		'base-name' => 'suse-10.2',
	};
	return bless $self, $class;
}

sub initialize
{
	my $self = shift;
	my $engine = shift;

	$self->SUPER::initialize($engine);
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
		- /var/lib/zypp/cache/*
		- /var/lib/zypp/*
		- /var/lib/zmd
		- /var/lib/xdm
		- /var/lib/vm/*
		- /var/lib/suspend*
		- /var/lib/sax
		- /var/lib/hardware/*
		- /var/lib/gdm/*
		- /var/lib/dhcp*
		- /var/lib/YaST2/you/mnt/*
		- /var/cache/man/*
		- /var/adm/backup/rpmdb/*
		- /var/adm/SuSEconfig
		- /usr/share/vmware/*
		- /usr/lib/zen-updater
		+ /usr/lib/python*/*/*.o
		+ /usr/lib/perl5/*/*/*/*.o
		+ /usr/lib/gcc/*/*/*.o
		+ /usr/lib/*.o
		- /usr/bin/zen-*
		- /usr/bin/nw-manager
		- /usr/X11R6/bin/BackGround
		- /opt/kde3/share/autostart/suseplugger.desktop
		- /opt/kde3/share/autostart/runupdater.desktop
		- /opt/kde3/share/autostart/profile_chooser-autostart.desktop
		- /opt/kde3/share/autostart/opensuseupdater.desktop
		- /opt/kde3/share/autostart/knetworkmanager-autostart.desktop
		- /opt/kde3/share/autostart/kerry.autostart.desktop
		- /opt/kde3/share/autostart/beagled.desktop
		- /opt/kde3/share/autostart/SUSEgreeter.desktop
		- /media/*
		+ /media
		+ /lib/modules/*/misc/vmnet.o
		+ /lib/modules/*/misc/vmmon.o
		- /etc/dhcpd.conf*
		- /etc/cron.*/*
		- /etc/X11/xdm/SuSEconfig.xdm
		- /boot/initrd*
		- /boot/grub
		- *.rpmsave
		- *.rpmnew
		- *.o
		- *.YaST2save
	";
}

1;