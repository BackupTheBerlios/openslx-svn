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

use vars qw($VERSION);
use base qw(OpenSLX::OSSetup::MetaPackager::Base);
$VERSION = 1.01;		# API-version . implementation-version

use strict;
use Carp;
use OpenSLX::Basics;
use OpenSLX::OSSetup::MetaPackager::Base 1;

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
}

sub initPackageSources
{
	my $self = shift;

	slxsystem("rm -f /etc/smart/channels/*");
}

sub setupPackageSource
{
	my $self = shift;
	my $repoName = shift;
	my $repoInfo = shift;

	my $repoURL = $self->{engine}->selectBaseURL($repoInfo);
	if (length($repoInfo->{'repo-subdir'})) {
		$repoURL .= "/$repoInfo->{'repo-subdir'}";
	}
	my $repoDescrCmdline
		= qq[$repoName name="$repoInfo->{name}" baseurl=$repoURL];
	$repoDescrCmdline .= " type=rpm-md";
	if (slxsystem("smart channel -y --add $repoDescrCmdline")) {
		die _tr("unable to add channel '%s' (%s)\n", $repoName, $!);
	}
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
}

1;
