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
	return;
}

sub installSelection
{
	my $self = shift;
	my $pkgSelection = shift;

	return;
}

sub updateBasicVendorOS
{
	my $self = shift;

	return;
}

1;