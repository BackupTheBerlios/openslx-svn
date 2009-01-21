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
# NFS.pm
#	- provides NFS-specific overrides of the OpenSLX::OSExport::ExportType API.
# -----------------------------------------------------------------------------
package OpenSLX::OSExport::ExportType::NFS;

use vars qw($VERSION);
use base qw(OpenSLX::OSExport::ExportType::Base);
$VERSION = 1.01;		# API-version . implementation-version

use strict;
use Carp;
use File::Basename;
use OpenSLX::Basics;
use OpenSLX::ConfigDB qw(:support);
use OpenSLX::Utils;
use OpenSLX::OSExport::ExportType::Base 1;

################################################################################
### interface methods
################################################################################
sub new
{
	my $class = shift;
	my $self = {
		'name' => 'NFS',
	};
	return bless $self, $class;
}

sub exportVendorOS
{
	my $self = shift;
	my $source = shift;
	my $target = shift;

	$self->copyViaRsync($source, $target);
}

sub purgeExport
{
	my $self = shift;
	my $target = shift;

	if (system("rm -r $target")) {
		vlog 0, _tr("unable to remove export '%s'!", $target);
		return 0;
	}
	1;
}

sub generateExportURI
{
	my $self = shift;
	my $export = shift;
	my $vendorOS = shift;

	my $server
		= length($export->{server_ip})
			? $export->{server_ip}
			: generatePlaceholderFor('serverip');
	$server .= ":$export->{port}"		if length($export->{port});

	my $exportPath = "$openslxConfig{'public-path'}/export";
	return "nfs://$server/$exportPath/nfs/$vendorOS->{name}";
}

sub requiredFSMods
{
	my $self = shift;

	return 'nfs';
}

sub showExportConfigInfo
{
	my $self = shift;
	my $export = shift;

	print (('#' x 80)."\n");
	print _tr("Please make sure the following line is contained in /etc/exports\nin order to activate the NFS-export of this vendor-OS:\n\t%s\n",
			  "$self->{engine}->{'export-path'}\t*(ro,no_root_squash,async,no_subtree_check)");
	print (('#' x 80)."\n");

# TODO : add something a bit more clever here...
#	my $exports = slurpFile("/etc/exports");
}

################################################################################
### implementation methods
################################################################################
sub copyViaRsync
{
	my $self = shift;
	my $source = shift;
	my $target = shift;

	if (system("mkdir -p $target")) {
		die _tr("unable to create directory '%s', giving up! (%s)\n",
				$target, $!);
	}
	my $includeExcludeList = $self->determineIncludeExcludeList();
	vlog 1, _tr("using include-exclude-filter:\n%s\n", $includeExcludeList);
	open(RSYNC, "| rsync -av --delete --exclude-from=- $source/ $target")
		or die _tr("unable to start rsync for source '%s', giving up! (%s)",
				   $source, $!);
	print RSYNC $includeExcludeList;
	if (!close(RSYNC)) {
		die _tr("unable to export to target '%s', giving up! (%s)",
				$target, $!);
	}
}

1;
