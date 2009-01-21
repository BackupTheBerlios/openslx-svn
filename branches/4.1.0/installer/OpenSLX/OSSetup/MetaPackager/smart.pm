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
# smart.pm
#	- provides smart-specific overrides of the OpenSLX::OSSetup::MetaPackager API.
# -----------------------------------------------------------------------------
package OpenSLX::OSSetup::MetaPackager::smart;

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
		'name' => 'smart',
	};
	return bless $self, $class;
}

sub initialize
{
	my $self = shift;
	my $engine = shift;

	$self->SUPER::initialize($engine);
	$ENV{LC_ALL} = 'POSIX';
	return;
}

sub initPackageSources
{
	my $self = shift;

	slxsystem("rm -f /etc/smart/channels/*");
	# remove channel if it already exists
	if (slxsystem("smart channel -y --remove-all")) {
		die _tr("unable to remove existing channels (%s)\n", $!);
	}
	return;
}

sub setupPackageSource
{
	my $self = shift;
	my $repoName = shift;
	my $repoInfo = shift;
	my $excludeList = shift;

	my $repoSubdir = '';
	if (length($repoInfo->{'repo-subdir'})) {
		$repoSubdir = "/$repoInfo->{'repo-subdir'}";
	}
	my $repoURLs = $self->{engine}->sortRepositoryURLs($repoInfo);
	my $baseURL = shift @$repoURLs;
	my $repoDescr
		= qq[$repoName name="$repoInfo->{name}" baseurl=$baseURL$repoSubdir];
	$repoDescr .= " type=rpm-md";
	if (slxsystem("smart channel -y --add $repoDescr")) {
		die _tr("unable to add channel '%s' (%s)\n", $repoName, $!);
	}
	my $avoidMirrors = $repoInfo->{'avoid-mirrors'} || 0;
	unless ($ENV{SLX_NO_MIRRORS} || $avoidMirrors) {
		my $mirrorDescr;
		foreach my $mirrorURL (@$repoURLs) {
			$mirrorDescr .= " --add $baseURL$repoSubdir $mirrorURL$repoSubdir";
		}
		if (defined $mirrorDescr) {
			if (slxsystem("smart mirror $mirrorDescr")) {
				die _tr(
					"unable to add mirrors for channel '%s' (%s)\n", 
					$repoName, $!
				);
			}
		}
	}
	return;
}

sub installSelection
{
	my $self = shift;
	my $pkgSelection = shift;

	if (slxsystem("smart update")) {
		die _tr("unable to update channel info (%s)\n", $!);
	}
	if (slxsystem("smart install -y $pkgSelection")) {
		die _tr("unable to install selection (%s)\n", $!);
	}
	return;
}

sub updateBasicVendorOS
{
	my $self = shift;

	if (slxsystem("smart upgrade -y --update")) {
		if ($! == 2) {
			# file not found => smart isn't installed
			die _tr("unable to update this vendor-os, as it seems to lack an installation of smart!\n");
		}
		die _tr("unable to update this vendor-os (%s)\n", $!);
	}
	return;
}

1;
