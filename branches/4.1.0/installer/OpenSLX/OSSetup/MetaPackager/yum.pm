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
# yum.pm
#	- provides yum-specific overrides of the OpenSLX::OSSetup::MetaPackager API.
# -----------------------------------------------------------------------------
package OpenSLX::OSSetup::MetaPackager::yum;

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
		'name' => 'yum',
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

	slxsystem("rm -f /etc/yum.repos.d/*");
	slxsystem("mkdir -p /etc/yum.repos.d");
}

sub setupPackageSource
{
	my $self = shift;
	my $repoName = shift;
	my $repoInfo = shift;
	my $excludeList = shift;

	my $repoSubdir;
	if (length($repoInfo->{'repo-subdir'})) {
		$repoSubdir = "/$repoInfo->{'repo-subdir'}";
	}
	my $repoURLs = $self->{engine}->sortRepositoryURLs($repoInfo);
	my $baseURL = shift @$repoURLs;

	my $repoDescr 
		= "[$repoName]\nname=$repoInfo->{name}\nbaseurl=$baseURL$repoSubdir\n";
	unless ($ENV{SLX_NO_MIRRORS}) {
		foreach my $mirrorURL (@$repoURLs) {
			$repoDescr .= "        $mirrorURL$repoSubdir\n";
		}
	}
	my $repoFile = "/etc/yum.repos.d/$repoName.repo";
	open(REPO, "> $repoFile")
		or die _tr("unable to create repo-file <%s> (%s)\n", $repoFile, $1);
	print REPO $repoDescr;
	print REPO "\nexclude=$excludeList\n";
	close(REPO);
}

sub installSelection
{
	my $self = shift;
	my $pkgSelection = shift;

	if (slxsystem("yum -y install $pkgSelection")) {
		die _tr("unable to install selection (%s)\n", $!);
	}
}

sub updateBasicVendorOS
{
	my $self = shift;

	if (slxsystem("yum -y update")) {
		if ($! == 2) {
			# file not found => yum isn't installed
			die _tr("unable to update this vendor-os, as it seems to lack an installation of yum!\n");
		}
		die _tr("unable to update this vendor-os (%s)\n", $!);
	}
}

1;