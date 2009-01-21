# Any.pm
#	- provides generic overrides of the OpenSLX OSExport API.
#
# (c) 2006 - OpenSLX.com
#
# Oliver Tappe <ot@openslx.com>
#
package OpenSLX::OSExport::Distro::Any;

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
		'base-name' => 'any',
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
		- /var/lock/*
		- /var/log/*
		- /var/lib/xdm
		- /var/cache/man/*
		- /usr/share/vmware/*
		- /lib/klibc/events/*
		- /boot/initrd*
		- /boot/grub
                + /lib/modules/*/misc/vmblock.o
                + /lib/modules/*/misc/vmnet.o
                + /lib/modules/*/misc/vmmon.o
	";
}

1;