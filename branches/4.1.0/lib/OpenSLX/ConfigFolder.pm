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
# ConfigFolder.pm
#	- provides utility functions for generation of configuration folders
# -----------------------------------------------------------------------------
package OpenSLX::ConfigFolder;

use strict;
use vars qw(@ISA @EXPORT $VERSION);

use Exporter;
$VERSION = 1.01;
@ISA = qw(Exporter);

@EXPORT = qw(
	&createConfigFolderForDefaultSystem
	&createConfigFolderForSystem
);

################################################################################
### Module implementation
################################################################################
use Carp;
use OpenSLX::Basics;

sub createConfigFolderForDefaultSystem
{
	my $result = 0;
	my $defaultConfigPath = "$openslxConfig{'private-path'}/config/default";
	if (!-e "$defaultConfigPath/initramfs") {
		slxsystem("mkdir -p $defaultConfigPath/initramfs");
		$result = 1;
	}
	if (!-e "$defaultConfigPath/rootfs") {
		slxsystem("mkdir -p $defaultConfigPath/rootfs");
		$result = 1;
	}

	# create default pre-/postinit scripts for us in initramfs:
	my $preInitFile = "$defaultConfigPath/initramfs/preinit.local";
	if (!-e $preInitFile) {
		open(PREINIT, "> $preInitFile")
			or die _tr("Unable to create file '%s'!", $preInitFile);
		my $preInit = <<'			END'
			#!/bin/sh
			#
			# This script allows the local admin to extend the
			# capabilities at the beginning of the initramfs (stage3).
			# The toolset is rather limited and you have to keep in mind 
			# that stage4 rootfs has the prefix '/mnt'.
			END
			;
		$preInit =~ s[^\s+][]igms;
		print PREINIT $preInit;
		close(PREINIT);
		slxsystem("chmod u+x $preInitFile");
		$result = 1;
	}

	my $postInitFile = "$defaultConfigPath/initramfs/postinit.local";
	if (!-e $postInitFile) {
		open(POSTINIT, "> $postInitFile")
			or die _tr("Unable to create file '%s'!", $postInitFile);
		my $postInit = <<'			END'
			#!/bin/sh
			#
			# This script allows the local admin to extend the
			# capabilities at the end of the initramfs (stage3).
			# The toolset is rather limited and you have to keep in mind 
			# that stage4 rootfs has the prefix '/mnt'.
			# But you may use some special slx-functions available via
			# inclusion: '. /etc/functions' ...
			END
			;
		$postInit =~ s[^\s+][]igms;
		print POSTINIT $postInit;
		close(POSTINIT);
		slxsystem("chmod u+x $postInitFile");
		$result = 1;
	}
	return $result;
}

sub createConfigFolderForSystem
{
	my $systemName = shift || confess "need to pass in system-name!";

	my $result = 0;
	my $systemConfigPath 
		= "$openslxConfig{'private-path'}/config/$systemName/default";
	if (!-e "$systemConfigPath/initramfs") {
		slxsystem("mkdir -p $systemConfigPath/initramfs");
		$result = 1;
	}
	if (!-e "$systemConfigPath/rootfs") {
		slxsystem("mkdir -p $systemConfigPath/rootfs");
		$result = 1;
	}
	return $result;
}

1;
