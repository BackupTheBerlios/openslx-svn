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
# apt.pm
#	- provides apt-get-specific overrides of the OpenSLX::OSSetup::MetaPackager API.
# -----------------------------------------------------------------------------
package OpenSLX::OSSetup::MetaPackager::apt;

use strict;
use warnings;

use base qw(OpenSLX::OSSetup::MetaPackager::Base);

use OpenSLX::Basics;
use OpenSLX::Utils;

################################################################################
### implementation
################################################################################
sub new
{
	my $class = shift;
	my $self = {
		'name' => 'apt',
	};
	return bless $self, $class;
}

sub initPackageSources
{
	my $self = shift;

	$ENV{LC_ALL} = 'POSIX';

	# remove any existing sources
	slxsystem('rm -f /etc/apt/sources.list');
	
	# create default timezone if there isn't any
	if (!-e '/etc/timezone') {
		spitFile('/etc/timezone', "$openslxConfig{'default-timezone'}\n");
	}
	
	# create kernel config if there isn't any
	if (!-e '/etc/kernel-img.conf') {
		my $kernelConfig = unshiftHereDoc(<<"		END-OF-HERE");
			# Kernel image management overrides
			# See kernel-img.conf(5) for details
			do_symlinks = yes
			relative_links = yes
			do_bootloader = no
			do_bootfloppy = no
			do_initrd = yes
			link_in_boot = yes
		END-OF-HERE
		spitFile('/etc/kernel-img.conf', $kernelConfig);
	}
	return;
}

sub setupPackageSource
{
	my $self        = shift;
	my $repoName    = shift;
	my $repoInfo    = shift;
	my $excludeList = shift;
	my $repoURLs    = shift;

	my $baseURL      = shift @$repoURLs;
	my $distribution = $repoInfo->{'distribution'};
	my $components   = $repoInfo->{'components'};

	my $sourcesList = "deb $baseURL $distribution $components\n";

	my $avoidMirrors = $repoInfo->{'avoid-mirrors'} || 0;
	if (!$avoidMirrors) {
		foreach my $mirrorURL (@$repoURLs) {
			$sourcesList .= "deb $mirrorURL $distribution $components\n";
		}
	}

	appendFile('/etc/apt/sources.list', $sourcesList);

	return;
}

sub installSelection
{
	my $self = shift;
	my $pkgSelection = shift;

	if (slxsystem("apt-get update")) {
		die _tr("unable to update repository info (%s)\n", $!);
	}
	if (slxsystem("apt-get -y install $pkgSelection")) {
		die _tr("unable to install selection (%s)\n", $!);
	}
	return;
}

sub updateBasicVendorOS
{
	my $self = shift;

	if (slxsystem("apt-get -y update")) {
		die _tr("unable to update repository info (%s)\n", $!);
	}
	if (slxsystem("apt-get -y upgrade")) {
		die _tr("unable to update this vendor-os (%s)\n", $!);
	}
	return;
}

1;