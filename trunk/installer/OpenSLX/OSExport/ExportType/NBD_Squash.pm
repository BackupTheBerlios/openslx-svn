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
# NBD_Squash.pm
#	- provides NBD+Squashfs-specific overrides of the OpenSLX::OSExport::ExportType API.
# -----------------------------------------------------------------------------
package OpenSLX::OSExport::ExportType::NBD_Squash;

use vars qw(@ISA $VERSION);
@ISA = ('OpenSLX::OSExport::ExportType::Base');
$VERSION = 1.01;		# API-version . implementation-version

use strict;
use Carp;
use File::Basename;
use OpenSLX::Basics;
use OpenSLX::OSExport::ExportType::Base 1.01;

################################################################################
### interface methods
################################################################################
sub new
{
	my $class = shift;
	my $self = {
		'name' => 'NBD_Squash',
	};
	return bless $self, $class;
}

sub exportVendorOS
{
	my $self = shift;
	my $source = shift;
	my $target = shift;

	my $includeExcludeList = $self->determineIncludeExcludeList();
	# in order to do the filtering as part of mksquashfs, we need to map
	# our internal (rsync-)filter format to regexes:
	$includeExcludeList
		= mapRsyncFilter2Regex($source, $includeExcludeList);
	vlog 1, _tr("using include-exclude-filter:\n%s\n", $includeExcludeList);
	$self->createSquashFS($source, $target, $includeExcludeList);
	$self->showNbdParams($target);
}

sub purgeExport
{
	my $self = shift;
	my $target = shift;

	if (system("rm $target")) {
		vlog 0, _tr("unable to remove export '%s'!", $target);
		return 0;
	}
	1;
}

################################################################################
### implementation methods
################################################################################

sub createSquashFS
{
	my $self = shift;
	my $source = shift;
	my $target = shift;
	my $includeExcludeList = shift;

	system("rm -f $target");
		# mksquasfs isn't significantly faster if fs already exists, but it
		# causes the filesystem to grow somewhat, so we remove it in order to
		# get the smallest FS-file possible.

	my $baseDir = dirname($target);
	if (!-e $baseDir) {
		if (system("mkdir -p $baseDir")) {
			die _tr("unable to create directory '%s', giving up! (%s)\n",
					$baseDir, $!);
		}
	}

	# dump filter to a file ...
	my $filterFile = "/tmp/slx-nbdsquash-filter-$$";
	open(FILTERFILE,"> $filterFile")
		or die _tr("unable to create tmpfile '%s' (%s)", $filterFile, $!);
	print FILTERFILE $includeExcludeList;
	close(FILTERFILE);

	# ... invoke mksquashfs ...
	vlog 0, _tr("invoking mksquashfs...");
	my $mksquashfsBinary
		= "$openslxConfig{'share-path'}/squashfs/mksquashfs";
	my $res = system("$mksquashfsBinary $source $target -ff $filterFile");
	unlink($filterFile);
		# ... remove filter file if done
	if ($res) {
		die _tr("unable to create squashfs for source '%s' as target '%s', giving up! (%s)",
				$source, $target, $!);
	}
}

sub showNbdParams
{
	my $self = shift;
	my $target = shift;

	print (('#' x 80)."\n");
	print _tr("Please make sure you start a corresponding nbd-server:\n\t%s\n",
			  "nbd-server port $self->{engine}->{'export-path'} -r");
	print (('#' x 80)."\n");
}

sub mapRsyncFilter2Regex
{
	my $sourcePath = shift;

	return
		join "\n",
		map {
			if ($_ =~ m[^([-+]\s*)(.+?)\s*$]) {
				my $action = $1;
				my $regex = $2;
				$regex =~ s[\*\*][.+]g;
					# '**' matches everything
				$regex =~ s[\*][[^/]+]g;
					# '*' matches anything except slashes
				$regex =~ s[\?][[^/]?]g;
					# '*' matches any single char except slash
				$regex =~ s[\?][[^/]?]g;
					# '*' matches any single char except slash
				$regex =~ s[\.][\\.]g;
					# escape any dots
				if (substr($regex, 0, 1) eq '/') {
					# absolute path given, need to extend by source-path:
					"$action^$sourcePath$regex\$";
				} else {
					# filename pattern given, need to anchor to the end only:
					"$action$regex\$";
				}
			} else {
				$_;
			}
		}
		split "\n", shift;
}

1;
