# Base.pm - provides empty base of the OpenSLX OSSetup API.
#
# (c) 2006 - OpenSLX.com
#
# Oliver Tappe <ot@openslx.com>
#
package OpenSLX::OSSetup::Distro::Base;

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
	confess "Creating OpenSLX::OSSetup::System::Base-objects directly makes no sense!";
}

sub initialize
{
	my $self = shift;
	my $engine = shift;

	$self->{'engine'} = $engine;

	if ($self->{'base-name'} =~ m[x86_64]) {
		# be careful to only try installing 64-bit systems if actually
		# running on a 64-bit host, as otherwise we are going to fail later,
		# anyway:
		my $arch = `uname -m`;
		if ($?) {
			die _tr("unable to determine architecture of host system (%s)\n", $!);
		}
		if ($arch !~ m[x86_64]) {
			die _tr("you can't install a 64-bit system on a 32-bit host, sorry!\n");
		}
	}

	$self->{'stage1a-binaries'} = {
		"$openslxConfig{'share-path'}/busybox/busybox" => 'bin',
	};

	$self->{'stage1b-faked-files'} = [
		'/etc/mtab',
	];

	$self->{'stage1c-faked-files'} = [
	];

	$self->{'clone-filter'} = "
		- /var/tmp/*
		- /var/opt/openslx
		- /var/lib/vmware
		+ /var
		- /usr/lib/vmware/modules/*
		+ /usr
		- /tmp/*
		+ /tmp
		- /sys/*
		+ /sys
		+ /sbin
		- /root/*
		+ /root
		- /proc/*
		+ /proc
		- /opt/openslx
		+ /opt
		- /media/*
		+ /media
		- /mnt/*
		+ /mnt
		+ /lib64
		+ /lib
		- /home/*
		+ /home
		- /etc/vmware/installer.sh
		- /etc/shadow*
		- /etc/samba/secrets.tdb
		- /etc/resolv.conf.*
		- /etc/opt/openslx
		- /etc/exports*
		- /etc/dxs
		+ /etc
		- /dev/*
		+ /dev
		+ /boot
		+ /bin
		- /*
		- .svn
		- .*.cmd
		- *~
		- *lost+found*
		- *.old
		- *.bak
	";

	$self->initDistroInfo();
}

sub fixPrerequiredFiles
{
}

sub initDistroInfo
{
}

1;
################################################################################

=pod

=head1 NAME

OpenSLX::OSSetup::System::Base - the base class for all OSSetup backends

=head1 SYNOPSIS

  package OpenSLX::OSSetup::coolnewOS;

  use vars qw(@ISA $VERSION);
  @ISA = ('OpenSLX::OSSetup::Base');
  $VERSION = 1.01;

  use coolnewOS;

  sub new
  {
      my $class = shift;
      my $self = {};
      return bless $self, $class;
  }

  # override all methods of OpenSLX::OSSetup::Base in order to implement
  # a full OS-setup backend
  ...

I<The synopsis above outlines a class that implements a
OSSetup backend for the (imaginary) operating system B<coolnewOS>>

=head1 DESCRIPTION

This class defines the OSSetup interface for the OpenSLX.

Aim of the OSSetup abstraction is to make it possible to install a large set
of different operating systems transparently.

...

=cut
