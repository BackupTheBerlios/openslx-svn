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
package OpenSLX::OSSetup::Packager::dpkg;

use strict;
use warnings;

use base qw(OpenSLX::OSSetup::Packager::Base);

use OpenSLX::Basics;
use OpenSLX::Utils;

################################################################################
### implementation
################################################################################
sub new
{
	my $class = shift;
	my $self = {
		'name' => 'dpkg',
	};
	return bless $self, $class;
}

sub prepareBootstrap
{
	my $self       = shift;
	my $stage1aDir = shift;
	
	copyBinaryWithRequiredLibs({
		'binary'          => '/usr/bin/perl',
		'targetFolder'    => "$stage1aDir/usr/bin",
		'libTargetFolder' => $stage1aDir,
	});

}

sub bootstrap
{
	my $self = shift;
	my $pkgs = shift;

	my $debootstrapPkg = $pkgs->[0];
	chdir '..';
	vlog(2, "unpacking debootstrap ...");
	if (slxsystem("ash", "-c", "ar x slxbootstrap/$debootstrapPkg")) {
		die _tr("unable to unarchive package '%s' (%s)", $debootstrapPkg, $!);
	}
	if (slxsystem("ash", "-c", "tar xzf data.tar.gz")) {
		die _tr("unable to untar 'data.tar.gz (%s)", $!);
	}
	if (slxsystem("ash", "-c", "rm -f debian-binary *.tar.gz")) {
		die _tr("unable to cleanup package '%s' (%s)", $debootstrapPkg, $!);
	}
	my $arch = $self->{engine}->{distro}->{arch};
	my $releaseName = $self->{engine}->{distro}->{'release-name'};
	my $baseURL = $self->{engine}->{baseURLs}->[0];
	my $debootstrapCmd = unshiftHereDoc(<<"	END-OF-HERE");
		/usr/sbin/debootstrap --arch $arch $releaseName \\
		                      /slxbootstrap/slxfinal $baseURL
	END-OF-HERE
	if (slxsystem("ash", "-c", "/bin/ash $debootstrapCmd")) {
		die _tr("unable to run debootstrap (%s)", $!);
	}
	return;
}

sub installPackages
{
	my $self = shift;
	my $pkgs = shift;
	my $finalPath = shift;

	return unless defined $pkgs && @$pkgs;

	if (slxsystem("dpkg", "--root=$finalPath", "--install", @$pkgs)) {
		die _tr("error during package-installation (%s)\n", $!);
	}
	return;
}

sub getInstalledPackages
{
	my $self = shift;

	my $rpmCmd = 'dpkg-query --showformat "\${package}\n" --show';
	my $pkgList = qx{$rpmCmd};
	return split "\n", $pkgList;
}

1;
