# Utils.pm - provides utility functions for OpenSLX
#
# (c) 2006 - OpenSLX.com
#
# Oliver Tappe <ot@openslx.com>
#
package OpenSLX::Utils;

use strict;
use vars qw(@ISA @EXPORT $VERSION);

use Exporter;
$VERSION = 1.01;
@ISA = qw(Exporter);

@EXPORT = qw(
	&copyFile &fakeFile &linkFile &slurpFile
);

################################################################################
### Module implementation
################################################################################
use Carp;
use OpenSLX::Basics;
use File::Basename;

sub copyFile
{
	my $fileName = shift;
	my $dirName = shift;

	my $baseName = basename($fileName);
	my $targetName = "$dirName/$baseName";
	if (!-e $targetName) {
		my $targetDir = dirname($targetName);
		system("mkdir -p $targetDir") 	unless -d $targetDir;
		if (system("cp -p $fileName $targetDir/")) {
			die _tr("unable to copy file '%s' to dir '%s' (%s)",
					$fileName, $targetDir, $!);
		}
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
1;