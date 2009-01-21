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
@ISA     = qw(Exporter);

@EXPORT = qw(
  copyFile fakeFile linkFile slurpFile spitFile followLink unshiftHereDoc
);

################################################################################
### Module implementation
################################################################################
use Carp;
use File::Basename;

use OpenSLX::Basics;

sub copyFile
{
	my $fileName       = shift || croak 'need to pass in a fileName!';
	my $targetDir      = shift || croak 'need to pass in target dir!';
	my $targetFileName = shift || '';

	system("mkdir -p $targetDir") unless -d $targetDir;
	my $target = "$targetDir/$targetFileName";
	vlog(2, _tr("copying '%s' to '%s'", $fileName, $target));
	if (system("cp -p $fileName $target")) {
		croak(
			_tr(
				"unable to copy file '%s' to dir '%s' (%s)",
				$fileName, $target, $!
			)
		);
	}
	return;
}

sub fakeFile
{
	my $fullPath = shift || croak 'need to pass in full path!';

	my $targetDir = dirname($fullPath);
	system("mkdir", "-p", $targetDir) unless -d $targetDir;
	if (system("touch", $fullPath)) {
		croak(_tr("unable to create file '%s' (%s)", $fullPath, $!));
	}
	return;
}

sub linkFile
{
	my $linkTarget = shift || croak 'need to pass in link target!';
	my $linkName   = shift || croak 'need to pass in link name!';

	my $targetDir = dirname($linkName);
	system("mkdir -p $targetDir") unless -d $targetDir;
	if (system("ln -sfn $linkTarget $linkName")) {
		croak(
			_tr(
				"unable to create link '%s' to '%s' (%s)",
				$linkName, $linkTarget, $!
			)
		);
	}
	return;
}

sub slurpFile
{
	my $fileName = shift || confess 'need to pass in fileName!';
	my $flags    = shift || {};

	checkFlags($flags, ['failIfMissing']);
	my $failIfMissing 
		= exists $flags->{failIfMissing} ? $flags->{failIfMissing} : 1;

	local $/;
	my $fh;
	if (!open($fh, '<', $fileName)) {
		return '' unless $failIfMissing;
		croak _tr("could not open file '%s' for reading! (%s)", $fileName, $!);
	}
	my $content = <$fh>;
	close($fh)
	  or croak _tr("unable to close file '%s' (%s)\n", $fileName, $!);
	return $content;
}

sub spitFile
{
	my $fileName = shift || croak 'need to pass in a fileName!';
	my $content  = shift;

	my $fh;
	open($fh, '>', $fileName)
	  or croak _tr("unable to create file '%s' (%s)\n", $fileName, $!);
	print $fh $content
	  or croak _tr("unable to print to file '%s' (%s)\n", $fileName, $!);
	close($fh)
	  or croak _tr("unable to close file '%s' (%s)\n", $fileName, $!);
	return;
}

sub followLink
{
	my $path         = shift || croak 'need to pass in a path!';
	my $prefixedPath = shift || '';

	my $target;
	while (-l "$path") {
		$target = readlink "$path";
		if (substr($target, 1, 1) eq '/') {
			$path = "$prefixedPath/$target";
		}
		else {
			$path = $prefixedPath . dirname($path) . '/' . $target;
		}
	}
	return $path;
}

