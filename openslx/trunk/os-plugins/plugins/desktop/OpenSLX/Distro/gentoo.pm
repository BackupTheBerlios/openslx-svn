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
#	- provides SUSE-specific overrides of the OpenSLX OSSetup API.
# -----------------------------------------------------------------------------
package OpenSLX::OSSetup::Distro::Gentoo;

use strict;
use warnings;

use base qw(OpenSLX::OSSetup::Distro::Base);

use OpenSLX::Basics;

################################################################################
### interface methods
################################################################################
sub new
{
	my $class = shift;
	my $self = {};
	return bless $self, $class;
}

sub pickKernelFile
{
	my $self       = shift;
	my $kernelPath = shift;

	my $newestKernelFile;
	my $newestKernelFileSortKey = '';
	foreach my $kernelFile (glob("$kernelPath/kernel-genkernel-x86-*")) {
		next unless $kernelFile =~ m{
			x86-(\d+)\.(\d+)\.(\d+)(?:\.(\d+))?-(\d+(?:\.\d+)?)
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
