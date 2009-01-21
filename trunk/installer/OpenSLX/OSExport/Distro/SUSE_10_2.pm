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

	$self->SUPER::initDistroInfo();

	$self->{'export-filter'} = "
		- *.YaST2save
		- *.o
		- *.rpmnew
		- *.rpmsave
		- /boot/grub
		- /boot/initrd*
		- /etc/X11/xdm/SuSEconfig.xdm
		- /etc/cron.*/*
		- /etc/dhcpd.conf*
		+ /lib/modules/*/misc/vmmon.o
		+ /lib/modules/*/misc/vmnet.o
		+ /media
		- /media/*
		- /opt/kde3/share/autostart/SUSEgreeter.desktop
		- /opt/kde3/share/autostart/beagled.desktop
		- /opt/kde3/share/autostart/kerry.autostart.desktop
		- /opt/kde3/share/autostart/knetworkmanager-autostart.desktop
		- /opt/kde3/share/autostart/opensuseupdater.desktop
		- /opt/kde3/share/autostart/profile_chooser-autostart.desktop
		- /opt/kde3/share/autostart/runupdater.desktop
		- /opt/kde3/share/autostart/suseplugger.desktop
		- /usr/X11R6/bin/BackGround
		- /usr/bin/nw-manager
		- /usr/bin/zen-*
		+ /usr/lib/*.o
		+ /usr/lib/gcc/*/*/*.o
		+ /usr/lib/perl5/*/*/*/*.o
		+ /usr/lib/python*/*/*.o
		- /usr/lib/zen-updater
		- /usr/share/vmware/*
		- /var/adm/SuSEconfig
		- /var/adm/backup/rpmdb/*
		- /var/cache/man/*
		- /var/lib/YaST2/you/mnt/*
		- /var/lib/dhcp*
		- /var/lib/gdm/*
		- /var/lib/hardware/*
		- /var/lib/sax
		- /var/lib/suspend*
		- /var/lib/vm/*
		- /var/lib/xdm
		- /var/lib/zmd
		- /var/lib/zypp/*
		- /var/lib/zypp/cache/*
		- /var/lock/*
		- /var/log/*
		- /var/mail
		- /var/run/*
		- /var/spool/*
		- /var/tmp/*
	";
}

1;