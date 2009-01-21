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
#	- provides empty base of the OpenSLX OSExport::FileSystem API.
# -----------------------------------------------------------------------------
package OpenSLX::OSExport::FileSystem::Base;

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
	confess "Creating OpenSLX::OSExport::FileSystem::Base-objects directly makes no sense!";
}

sub initialize
{
}

sub exportVendorOS
{
}

sub purgeExport
{
}

sub checkRequirements
{
	return 1;
}

sub addExportToConfigDB
{
	my $self = shift;
	my $export = shift;
	my $openslxDB = shift;

	return $openslxDB->addExport($export);
}

sub generateExportURI
{
}

sub requiredFSMods
{
}

sub showExportConfigInfo
{
}

################################################################################
### implementation methods
################################################################################
sub _pickKernelVersion
{
	my $self         = shift;
	my $vendorOSPath = shift;
	
	my $kernel = followLink("$vendorOSPath/boot/vmlinuz");
	if (!-e $kernel) {
		# 'vmlinuz'-link doesn't exist, so we have to pick the kernel manually
		my $osSetupEngine = instantiateClass("OpenSLX::OSSetup::Engine");
		$osSetupEngine->initialize($self->{engine}->{'vendor-os-name'}, 'none');
		$kernel = $osSetupEngine->pickKernelFile("$vendorOSPath/boot");
	}
	my $kernelName = basename($kernel);
	if ($kernelName !~ m[-(.+)$]) {
		die _tr("unable to determine version of kernel '%s'!", $kernelName);
	}
	return $1;
}

sub _locateKernelModule
{
	my $self         = shift;
	my $vendorOSPath = shift;
	my $moduleName   = shift;
	my $defaultPaths = shift;

	vlog(1, _tr("locating kernel-module '%s'", $moduleName));
	# check default paths first:
	foreach my $defPath (@$defaultPaths) {
		vlog(2, "trying $defPath/$moduleName");
		my $target = followLink("$defPath/$moduleName", $vendorOSPath);
		return $target unless !-e $target;
	}
	# use brute force to search for the newest incarnation of the module:
	use File::Find;
	my $location;
	my $locationAge = 9999999;
	vlog(2, "searching in $vendorOSPath/lib/modules");
	find sub {
		return unless $_ eq $moduleName;
		if (-M _ < $locationAge) {
			$locationAge = -M _;
			$location    = $File::Find::name;
			vlog(2, "located at $location (age=$locationAge days)");
		}
	}, "$vendorOSPath/lib/modules";
	if (defined $location) {
		return followLink($location, $vendorOSPath);
	}
	return;
}

1;

################################################################################

=pod

=head1 NAME

OpenSLX::OSExport::FileSystem::Base - the base class for all OSExport::FileSystems

=cut
