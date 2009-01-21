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

use vars qw($VERSION);
use base qw(OpenSLX::OSExport::ExportType::Base);
$VERSION = 1.01;		# API-version . implementation-version

use strict;
use Carp;
use File::Basename;
use OpenSLX::Basics;
use OpenSLX::ConfigDB qw(:support);
use OpenSLX::OSExport::ExportType::Base 1;
use OpenSLX::Utils;

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

sub checkRequirements
{
	my $self = shift;
	my $vendorOSPath = shift;
	my $kernel = shift || 'vmlinuz';
	my $info = shift;

	$kernel = basename(followLink("$vendorOSPath/boot/$kernel"));
	if ($kernel !~ m[-(.+)$]) {
		die _tr("unable to determine version of kernel '%s'!", $kernel);
	}
	my $kernelVer = $1;
	my $nbdMod = locateKernelModule(
		$vendorOSPath,
		'nbd.ko',
		["$vendorOSPath/lib/modules/$kernelVer/kernel/drivers/block"]
	);
	if (!defined $nbdMod) {
		warn _tr("unable to find nbd-module for kernel version '%s'.",
				 $kernelVer);
		return undef;
	}
	my $squashfsMod = locateKernelModule(
		$vendorOSPath,
		'squashfs.ko',
		["$vendorOSPath/lib/modules/$kernelVer/kernel/fs/squashfs",
		 "$vendorOSPath/lib/modules/$kernelVer/kernel/fs"]
	);
	if (!defined $squashfsMod) {
		warn _tr("unable to find squashfs-module for kernel version '%s'.",
				 $kernelVer);
		return undef;
	}
	if (defined $info) {
		$info->{'kernel-mods'} = [ $nbdMod, $squashfsMod ];
	};
	return 1;
}

sub addExportToConfigDB
{
	my $self = shift;
	my $export = shift;
	my $openslxDB = shift;

	$export->{port}
		= $openslxDB->incrementGlobalCounter('next-nbd-server-port');

	my $res = $openslxDB->addExport($export);
	$self->showNbdParams($export)		if $res;
	return $res;
}

sub generateExportURI
{
	my $self = shift;
	my $export = shift;

	my $server
		= length($export->{server_ip})
			? $export->{server_ip}
			: generatePlaceholderFor('serverip');
	$server .= ":$export->{port}"		if length($export->{port});

	return "nbd://$server/squashfs";
}

sub requiredFSMods
{
	my $self = shift;

	return 'nbd squashfs';
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
	my $export = shift;

	print (('#' x 80)."\n");
	print _tr("Please make sure you start a corresponding nbd-server:\n\t%s\n",
			  "nbd-server $export->{port} $self->{engine}->{'export-path'} -r");
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

sub locateKernelModule
{
	my $vendorOSPath = shift;
	my $moduleName = shift;
	my $defaultPaths = shift;

	vlog 1, _tr("locating kernel-module '%s'", $moduleName);
	# check default paths first:
	foreach my $defPath (@$defaultPaths) {
		vlog 2, "trying $defPath/$moduleName";
		my $target = followLink("$defPath/$moduleName", $vendorOSPath);
		return $target		unless !-e $target;
	}
	# use brute force to search for the newest incarnation of the module:
	use File::Find;
	my $location;
	my $locationAge = 9999999;
	vlog 2, "searching in $vendorOSPath/lib/modules";
	find sub {
		return unless $_ eq $moduleName;
		if (-M _ < $locationAge) {
			$locationAge = -M _;
			$location = $File::Find::name;
			vlog 2, "located at $location (age=$locationAge days)";
		}
	}, "$vendorOSPath/lib/modules";
	if (defined $location) {
		return followLink($location, $vendorOSPath);
	}
	return undef;
}

1;
