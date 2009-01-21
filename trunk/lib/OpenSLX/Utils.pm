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
# Utils.pm
#	- provides utility functions for OpenSLX
# -----------------------------------------------------------------------------
package OpenSLX::Utils;

use strict;
use vars qw(@ISA @EXPORT $VERSION);

use Exporter;
$VERSION = 1.01;
@ISA = qw(Exporter);

@EXPORT = qw(
	&copyFile &fakeFile &linkFile &slurpFile &followLink
);

################################################################################
### Module implementation
################################################################################
use Carp;
use File::Basename;

use OpenSLX::Basics;

sub copyFile
{
	my $fileName = shift;
	my $targetDir = shift;
	my $targetFileName = shift || '';

	system("mkdir -p $targetDir") 	unless -d $targetDir;
	my $target = "$targetDir/$targetFileName";
	vlog 2, _tr("copying '%s' to '%s'", $fileName, $target);
	if (system("cp -p $fileName $target")) {
		die _tr("unable to copy file '%s' to dir '%s' (%s)",
				$fileName, $target, $!);
	}
}

sub fakeFile
{
	my $fullPath = shift;

	my $targetDir = dirname($fullPath);
	system("mkdir", "-p", $targetDir) 	unless -d $targetDir;
	if (system("touch", $fullPath)) {
		die _tr("unable to create file '%s' (%s)",
				$fullPath, $!);
	}
}

sub linkFile
{
	my $linkTarget = shift;
	my $linkName = shift;

	my $targetDir = dirname($linkName);
	system("mkdir -p $targetDir") 	unless -d $targetDir;
	if (system("ln -sfn $linkTarget $linkName")) {
		die _tr("unable to create link '%s' to '%s' (%s)",
				$linkName, $linkTarget, $!);
	}
}

sub slurpFile
{
	my $file = shift;
	my $mayNotExist = shift;

	if (!open(F, "< $file") && !$mayNotExist) {
		die _tr("could not open file '%s' for reading! (%s)", $file, $!);
	}
	local $/ = undef;
	my $text = <F>;
	close(F);
	return $text;
}

sub followLink
{
	my $path = shift;
	my $prefixedPath = shift || '';
	
	my $target;
	while (-l "$path") {
		$target = readlink "$path";
		if (substr($target, 1, 1) eq '/') {
			$path = "$prefixedPath/$target";
		} else {
			$path = $prefixedPath.dirname($path).'/'.$target;
		}
	}
	return $path;
}

1;