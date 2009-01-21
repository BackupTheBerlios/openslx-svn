# Base.pm - provides empty base of the distro-specific part of the
# OpenSLX OSExport API.
#
# (c) 2006 - OpenSLX.com
#
# Oliver Tappe <ot@openslx.com>
#
package OpenSLX::OSExport::Distro::Base;

use vars qw($VERSION);
$VERSION = 1.01;		# API-version . implementation-version

use strict;
use Carp;
use File::Basename;
use OpenSLX::Basics;

################################################################################
### interface methods
################################################################################
sub new
{
	confess "Creating OpenSLX::OSExport::Distro::Base-objects directly makes no sense!";
}

sub initialize
{
	my $self = shift;
	my $engine = shift;

	$self->{'engine'} = $engine;

	$self->initDistroInfo();
}

sub initDistroInfo
{
	my $self = shift;

	$self->{'clone-filter'} = "
		- *.bak
		- *.old
		- *lost+found*
		- *~
		- .*.cmd
		- .svn
		- /*
		+ /bin
		+ /boot
		+ /dev
		- /dev/*
		+ /etc
		- /etc/dxs
		- /etc/exports*
		- /etc/opt/openslx
		- /etc/resolv.conf.*
		- /etc/samba/secrets.tdb
		- /etc/shadow*
		- /etc/vmware/installer.sh
		+ /home
		- /home/*
		+ /lib
		+ /lib64
		+ /mnt
		- /mnt/*
		+ /opt
		- /opt/openslx
		+ /proc
		- /proc/*
		+ /root
		- /root/*
		+ /sbin
		+ /sys
		- /sys/*
		+ /tmp
		- /tmp/*
		+ /usr
		- /usr/lib/vmware/modules/*
		+ /var
		- /var/lib/vmware
		- /var/opt/openslx
		- /var/tmp/*
	";
}

1;
################################################################################

=pod

=head1 NAME

OpenSLX::OSExport::Distro::Base

=head1 SYNOPSIS

...

=cut
