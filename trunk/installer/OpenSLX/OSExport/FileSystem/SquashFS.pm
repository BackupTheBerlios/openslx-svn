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
# SquashFS.pm
#	- provides SquashFS-specific overrides of the OpenSLX::OSExport::ExportType 
#	  API.
# -----------------------------------------------------------------------------
package OpenSLX::OSExport::FileSystem::SquashFS;

use vars qw($VERSION);
use base qw(OpenSLX::OSExport::FileSystem::Base);
$VERSION = 1.01;		# API-version . implementation-version

use strict;
use Carp;
use File::Basename;
use OpenSLX::Basics;
use OpenSLX::ConfigDB qw(:support);
use OpenSLX::OSExport::FileSystem::Base 1;
use OpenSLX::Utils;

################################################################################
### interface methods
################################################################################
sub new
{
	my $class = shift;
	my $self = {
		'name' => 'sqfs',
	};
	return bless $self, $class;
}

sub initialize
{
	my $self = shift;
	my $engine = shift;
	my $blockDevice = shift || confess('need to pass in block-device!');

	$self->{'engine'} = $engine;
	$self->{'block-device'} = $blockDevice;
	my $exportBasePath = "$openslxConfig{'public-path'}/export";
	$self->{'export-path'} 
		= "$exportBasePath/sqfs/$engine->{'vendor-os-name'}";
}

sub exportVendorOS
{
	my $self = shift;
	my $source = shift;

	my $includeExcludeList = $self->_determineIncludeExcludeList();
	# in order to do the filtering as part of mksquashfs, we need to map
	# our internal (rsync-)filter format to regexes:
	$includeExcludeList
		= $self->_mapRsyncFilter2Regex($source, $includeExcludeList);
	vlog(1, _tr("using include-exclude-filter:\n%s\n", $includeExcludeList));
	my $target = $self->{'export-path'};
#	$self->_createSquashFS($source, $target, $includeExcludeList);
	$self->_addBlockDeviceTagToExport($target);
}

sub purgeExport
{
	my $self = shift;

	my $target = $self->{'export-path'};
	if ($self->_removeBlockDeviceTagFromExport($target)) {
		# no more tags, we can remove the image:
		if (slxsystem("rm $target")) {
			vlog(0, _tr("unable to remove export '%s'!", $target));
			return 0;
		}
	}
	return 1;
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
	my @blockMods;
	my @blockModNames = $self->{'block-device'}->requiredBlockDeviceModules();
	foreach my $blockModName (@blockModNames) {
		my $blockMod = $self->_locateKernelModule(
			$vendorOSPath,
			"$blockModName.ko",
			["$vendorOSPath/lib/modules/$kernelVer/kernel/drivers/block"]
		);
		if (!defined $blockMod) {
			warn _tr("unable to find blockdevice-module '%s' for kernel version '%s'.",
					 $blockModName, $kernelVer);
			return undef;
		}
		push @blockMods, $blockMod;
	}
	my $squashfsMod = $self->_locateKernelModule(
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
	push @blockMods, $squashfsMod;
	if (defined $info) {
		$info->{'kernel-mods'} = \@blockMods;
	};
	return 1;
}

sub addExportToConfigDB
{
	my $self = shift;
	my $export = shift;
	my $openslxDB = shift;

	$export->{port} = $self->{'block-device'}->getExportPort($openslxDB);

	my $res = $openslxDB->addExport($export);
	return $res;
}

sub generateExportURI
{
	my $self = shift;
	my $export = shift;
	my $vendorOS = shift;

	my $URI = $self->{'block-device'}->generateExportURI($export);
	$URI .= '/squashfs';
	return $URI;
}

sub requiredFSMods
{
	my $self = shift;

	my @mods = $self->{'block-device'}->requiredBlockDeviceModules();
	push @mods, 'squashfs ';
	return join ' ', @mods;
}

sub showExportConfigInfo
{
	my $self = shift;
	my $export = shift;

	$self->{'block-device'}->showExportConfigInfo($export);
}

################################################################################
### implementation methods
################################################################################

sub _createSquashFS
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
	vlog(0, _tr("invoking mksquashfs..."));
	my $mksquashfsBinary
		= "$openslxConfig{'base-path'}/share/squashfs/mksquashfs";
	my $res = system("$mksquashfsBinary $source $target -ff $filterFile");
	unlink($filterFile);
		# ... remove filter file if done
	if ($res) {
		die _tr("unable to create squashfs for source '%s' as target '%s', giving up! (%s)",
				$source, $target, $!);
	}
}

sub _determineIncludeExcludeList
{
	my $self = shift;

	# Rsync uses a first match strategy, so we mix the local specifications
	# in front of the filterset given by the package (as the local filters
	# should always overrule the vendor filters):
	my $distroName = $self->{engine}->{'distro-name'};
	my $localFilterFile 
		= "$openslxConfig{'config-path'}/distro-info/$distroName/export-filter";
	my $includeExcludeList = slurpFile($localFilterFile, 1);
	$includeExcludeList .= $self->{engine}->{distro}->{'export-filter'};
	$includeExcludeList =~ s[^\s+][]igms;
		# remove any leading whitespace, as rsync doesn't like it
	return $includeExcludeList;
}

sub _mapRsyncFilter2Regex
{
	my $self = shift;
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

sub _locateKernelModule
{
	my $self = shift;
	my $vendorOSPath = shift;
	my $moduleName = shift;
	my $defaultPaths = shift;

	vlog(1, _tr("locating kernel-module '%s'", $moduleName));
	# check default paths first:
	foreach my $defPath (@$defaultPaths) {
		vlog(2, "trying $defPath/$moduleName");
		my $target = followLink("$defPath/$moduleName", $vendorOSPath);
		return $target		unless !-e $target;
	}
	# use brute force to search for the newest incarnation of the module:
	use File::Find;
	my $location;
	my $locationAge = 9999999;
	vlog(2, "searching in $vendorOSPath/lib/modules");
	find sub {
		return unless $_ eq $moduleName;
		if (-M _ < $locationAge) {
			$locationAge = -M _;
			$location = $File::Find::name;
			vlog(2, "located at $location (age=$locationAge days)");
		}
	}, "$vendorOSPath/lib/modules";
	if (defined $location) {
		return followLink($location, $vendorOSPath);
	}
	return undef;
}

sub _addBlockDeviceTagToExport
{
	my $self = shift;
	my $target = shift;
	
	my $tagName = "$target".'@'.lc($self->{'block-device'}->{name});
	linkFile(basename($target), $tagName);
}

sub _removeBlockDeviceTagFromExport
{
	my $self = shift;
	my $target = shift;
	
	my $tagName = "$target".'@'.lc($self->{'block-device'}->{name});
	slxsystem("rm $tagName");
	# now find out whether or not there are any other tags left:
	my $vendorOSName = basename($target);
	opendir(DIR, dirname($target));
	my @tags = grep { /^vendorOSName\@/ } readdir(DIR);
	return @tags ? 0 : 1;
		# return 1 if no more tags (i.e. it is safe to remove the image)
}

1;
