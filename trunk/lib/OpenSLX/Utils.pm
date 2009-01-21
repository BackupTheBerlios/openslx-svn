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
use warnings;

use vars qw(@ISA @EXPORT $VERSION);

use Exporter;
$VERSION = 1.01;
@ISA     = qw(Exporter);

@EXPORT = qw(
  copyFile fakeFile linkFile 
  copyBinaryWithRequiredLibs
  slurpFile spitFile 
  followLink 
  unshiftHereDoc
  string2Array
  chrootInto
);

################################################################################
### Module implementation
################################################################################
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

	checkParams($flags, { 'failIfMissing' => '?' });
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

sub copyBinaryWithRequiredLibs {
	my $params = shift;
	
	checkParams($params, {
		'binary'       	  => '!',	# file to copy
		'targetFolder'    => '!',	# where file shall be copied to
		'libTargetFolder' => '!',	# base target folder for libs
		'targetName'      => '?',	# name of binary in target folder
	});
	copyFile($params->{binary}, $params->{targetFolder}, $params->{targetName});

	# determine all required libraries and copy those, too:
	vlog(1, _tr("calling slxldd for $params->{binary}"));
	my $slxlddCmd = "slxldd $params->{binary}";
	vlog(2, "executing: $slxlddCmd");
	my $requiredLibsStr = qx{$slxlddCmd};
	if ($?) {
		die _tr(
			"slxldd couldn't determine the libs required by '%s'! (%s)", 
			$params->{binary}, $?
		);
	}
	chomp $requiredLibsStr;
	vlog(2, "slxldd results:\n$requiredLibsStr");
	
	foreach my $lib (split "\n", $requiredLibsStr) {
		my $libDir = dirname($lib);
		my $targetLib = "$params->{libTargetFolder}$libDir";
#		next if -e $targetLib;
		vlog(3, "copying lib '$lib'");
		copyFile($lib, $targetLib);
	}
	return $requiredLibsStr;
}

sub unshiftHereDoc
{
	my $content = shift;
	return $content unless $content =~ m{^(\s+)};
	my $shift = length($1);
	return 
		join "\n", 
		map { substr($_, $shift); } 
		split m{\n}, $content;
}

sub string2Array
{
	my $string = shift || '';

	my @lines = split m[\n], $string;
	for my $line (@lines) {
		# remove leading and trailing whitespace:
		$line =~ s{^\s*(.*?)\s*$}{$1};
	}

	# drop empty lines and comments:
	return grep { length($_) > 0 && $_ !~ m[^\s*#]; } @lines;
}

sub chrootInto
{
	my $osDir = shift;

	vlog(2, "chrooting into $osDir...");
	chdir $osDir
		or die _tr("unable to chdir into '%s' (%s)\n", $osDir, $!);

	# ...do chroot
	chroot "."
		or die _tr("unable to chroot into '%s' (%s)\n", $osDir, $!);
	return;
}

1;
