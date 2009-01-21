# Fedora.pm
#	- provides Fedora-specific overrides of the OpenSLX OSExport API.
#
# (c) 2006 - OpenSLX.com
#
# Oliver Tappe <ot@openslx.com>
#
package OpenSLX::OSExport::Distro::Fedora;

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
		'base-name' => 'fedora',
	};
	return bless $self, $class;
}

sub initDistroInfo
{
	my $self = shift;

	# TODO: check and refine this!
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
		- *.rpmsave
		- *.rpmnew
	";
}

1;