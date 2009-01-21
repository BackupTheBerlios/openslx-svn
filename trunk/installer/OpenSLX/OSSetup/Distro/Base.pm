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
# Base.pm
#	- provides empty base of the OpenSLX OSSetup API.
# -----------------------------------------------------------------------------
package OpenSLX::OSSetup::Distro::Base;

use strict;
use warnings;

our $VERSION = 1.01;		# API-version . implementation-version

use File::Basename;
use OpenSLX::Basics;
use OpenSLX::Utils;

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
		"$openslxConfig{'base-path'}/share/busybox/busybox" => 'bin',
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
	return;
}

sub fixPrerequiredFiles
{
}

sub initDistroInfo
{
}

sub startSession
{
	my $self  = shift;
	my $osDir = shift;
	
	# ensure that the session will be finished even if the script crashes:
	addCleanupFunction(
		"slxos-setup::distro::chroot", sub { $self->finishSession(); }
	);

	# make sure there's a /dev/zero and /dev/null
	if (!-e "$osDir/dev" && !mkdir("$osDir/dev")) {
		die _tr("unable to create folder '%s' (%s)\n", "$osDir/dev", $!);
	}
	if (!-e "$osDir/dev/zero" && slxsystem("mknod $osDir/dev/zero c 1 5")) {
		die _tr("unable to create node '%s' (%s)\n", "$osDir/dev/zero", $!);
	}
	if (!-e "$osDir/dev/null" && slxsystem("mknod $osDir/dev/null c 1 3")) {
		die _tr("unable to create node '%s' (%s)\n", "$osDir/dev/null", $!);
	}

	# fake proc, depending on what is needed ...
	if (!-e "$osDir/proc" && !mkdir("$osDir/proc")) {
		die _tr("unable to create folder '%s' (%s)\n", "$osDir/proc", $!);
	}
	if (!-e "$osDir/proc/cpuinfo" && slxsystem("cp /proc/cpuinfo $osDir/proc/")) {
		die _tr("unable to copy file '%s' (%s)\n", "/proc/cpuinfo", $!);
	}
	# TODO: alternatively, we could mount proc, but that causes problems
	#       when we are not able to umount it properly (which may happen
	#       if 'umount' is not available in the chroot!)
	#
	# mount /proc
#	if (!-e "$osDir/proc") {
#		slxsystem("mkdir -p $osDir/proc");
#	}
#	if (slxsystem("mount -t proc proc $osDir/proc 2>/dev/null")) {
#		die _tr("unable to mount '%s' (%s)\n", "$osDir/proc", $!);
#	}

	# enter chroot jail
	chrootInto($osDir);
	$ENV{PATH} = "/bin:/sbin:/usr/bin:/usr/sbin";

	return;
}

sub finishSession
{
	my $self = shift;
	
	removeCleanupFunction('slxos-setup::distro::chroot');

	# unmount /proc
#	if (slxsystem('ash', '-c', 'umount /proc 2>/dev/null')) {
#		die _tr("unable to unmount '%s' (%s)\n", "/proc", $!);
#	}

	return;
}

sub updateDistroConfig
{
	if (slxsystem("ldconfig")) {
		die _tr("unable to run ldconfig (%s)", $!);
	}
}

sub pickKernelFile
{
	my $self       = shift;
	my $kernelPath = shift;

	my $newestKernelFile;
	my $newestKernelFileSortKey = '';
	foreach my $kernelFile (glob("$kernelPath/vmlinuz-*")) {
		next unless $kernelFile =~ m{
			vmlinuz-(\d+)\.(\d+)\.(\d+)(?:\.(\d+))?-(\d+(?:\.\d+)?)
		}x;
		my $sortKey 
			= sprintf("%02d.%02d.%02d.%02d-%2.1f", $1, $2, $3, $4||0, $5);
		if ($newestKernelFileSortKey lt $sortKey) {
			$newestKernelFile        = $kernelFile;
			$newestKernelFileSortKey = $sortKey;
		}
	}

	if (!defined $newestKernelFile) {
		die _tr("unable to pick a kernel-file from path '%s'!", $kernelPath);
	}
	return $newestKernelFile;
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
