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
# rpm.pm
#	- provides rpm-specific overrides of the OpenSLX::OSSetup::Packager API.
# -----------------------------------------------------------------------------
package OpenSLX::OSSetup::Packager::rpm;

use strict;
use warnings;

use base qw(OpenSLX::OSSetup::Packager::Base);

use OpenSLX::Basics;

################################################################################
### implementation
################################################################################
sub new
{
	my $class = shift;
	my $self = {
		'name' => 'rpm',
	};
	return bless $self, $class;
}

sub unpackPackages
{
	my $self = shift;
	my $pkgs = shift;

	foreach my $pkg (@$pkgs) {
		vlog(2, "unpacking package $pkg...");
		if (slxsystem("ash", "-c", "rpm2cpio $pkg | cpio -i -d -u")) {
			warn _tr("unable to unpack package <%s> (%s)", $pkg, $!);
				# TODO: change this back to die() if cpio-ing fedora6-glibc
				#       doesn't crash anymore... (needs busybox update, I suppose)
		}
	}
	return;
}

sub importTrustedPackageKeys
{
	my $self = shift;
	my $keyFiles = shift;
	my $finalPath = shift;

	return unless defined $keyFiles;

	foreach my $keyFile (@$keyFiles) {
		vlog(2, "importing package key $keyFile...");
		if (slxsystem("rpm", "--root=$finalPath", "--import", "$keyFile")) {
			die _tr("unable to import package key <%s> (%s)\n", $keyFile, $!);
		}
	}
	return;
}

sub installPrerequiredPackages
{
	my $self = shift;
	my $pkgs = shift;
	my $finalPath = shift;

	return unless defined $pkgs && scalar(@$pkgs);

	if (slxsystem("rpm", "--root=$finalPath", "-ivh", "--nodeps", "--noscripts",
			   "--force", @$pkgs)) {
		die _tr("error during prerequired-package-installation (%s)\n", $!);
	}
	slxsystem("rm", "-rf", "$finalPath/var/lib/rpm");
	return;
}

sub installPackages
{
	my $self = shift;
	my $pkgs = shift;
	my $finalPath = shift;

	return unless defined $pkgs && scalar(@$pkgs);

	if (slxsystem("rpm", "--root=$finalPath", "-ivh", @$pkgs)) {
		die _tr("error during package-installation (%s)\n", $!);
	}
	return;
}

sub getInstalledPackages
{
	my $self = shift;

	my $rpmCmd = 'rpm -qa --queryformat="%{NAME}\n"';
	my $pkgList = `$rpmCmd`;
	return split "\n", $pkgList;
}

1;
