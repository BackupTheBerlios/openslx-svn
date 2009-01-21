# Engine.pm - provides driver engine for the OSExport API.
#
# (c) 2006 - OpenSLX.com
#
# Oliver Tappe <ot@openslx.com>
#
package OpenSLX::OSExport::Engine;

use vars qw(@ISA @EXPORT $VERSION);
$VERSION = 1.01;		# API-version . implementation-version

use Exporter;
@ISA = qw(Exporter);

@EXPORT = qw(
	%supportedExportTypes
);

use strict;
use Carp;
use File::Basename;
use OpenSLX::Basics;

use vars qw(%supportedExportTypes);

%supportedExportTypes = (
	'nfs'
		=> { module => 'NFS' },
	'nbd'
		=> { module => 'NBD' },
	'nbd-squashfs'
		=> { module => 'NBD_Squash' },
);

################################################################################
### interface methods
################################################################################
sub new
{
	my $class = shift;

	my $self = {
	};

	return bless $self, $class;
}

sub initialize
{
	my $self = shift;
	my $vendorOSName = shift;
	my $exportType = shift;

	if (!exists $supportedExportTypes{lc($exportType)}) {
		print _tr("Sorry, export type '%s' is unsupported.\n", $exportType);
		print _tr("List of supported export types:\n\t");
		print join("\n\t", sort keys %supportedExportTypes)."\n";
		exit 1;
	}

	$self->{'vendor-os-name'} = $vendorOSName;
	$vendorOSName =~ m[^(.+?\-[^-]+)];
	my $distroName = $1;
	$self->{'distro-name'} = $distroName;

	# load module for the requested export type:
	my $exportTypeModule
		= "OpenSLX::OSExport::ExportType::"
			.$supportedExportTypes{lc($exportType)}->{module};
	unless (eval "require $exportTypeModule") {
		if ($! == 2) {
			die _tr("Export-type-module <%s> not found!\n", $exportTypeModule);
		} else {
			die _tr("Unable to load export-type-module <%s> (%s)\n", $exportTypeModule, $@);
		}
	}
	my $modVersion = $exportTypeModule->VERSION;
	if ($modVersion < 1.01) {
		die _tr('Could not load module <%s> (Version <%s> required, but <%s> found)',
				$exportTypeModule, 1.01, $modVersion);
	}
	$exportTypeModule->import;
	my $exporter = $exportTypeModule->new;
	$exporter->initialize($self);
	$self->{'exporter'} = $exporter;

	# setup source and target paths:
	$self->{'vendor-os-path'}
		= "$openslxConfig{'stage1-path'}/$vendorOSName";
	$self->{'export-path'}
		= "$openslxConfig{'export-path'}/$exportType/$vendorOSName";
	vlog 1, _tr("vendor-OS from '%s' will be exported to '%s'",
				$self->{'vendor-os-path'}, $self->{'export-path'});
}

sub exportVendorOS
{
	my $self = shift;

	$self->{'exporter'}->exportVendorOS(
		$self->{'vendor-os-path'},
		$self->{'export-path'}
	);
	$self->addExportToConfigDB();
}

################################################################################
### implementation methods
################################################################################
sub addExportToConfigDB
{
	my $self = shift;

	my $configDBModule = "OpenSLX::ConfigDB";
	unless (eval "require $configDBModule") {
		if ($! == 2) {
			vlog 1, _tr("ConfigDB-module not found, unable to access OpenSLX-database.\n");
		} else {
			die _tr("Unable to load ConfigDB-module <%s> (%s)\n", $configDBModule, $@);
		}
	} else {
		my $modVersion = $configDBModule->VERSION;
		if ($modVersion < 1.01) {
			die _tr('Could not load module <%s> (Version <%s> required, but <%s> found)',
					$configDBModule, 1.01, $modVersion);
		}
		$configDBModule->import(qw(:access :manipulation));
		my $openslxDB = connectConfigDB();
		# insert new export if it doesn't already exist in DB:
		my $exportName = $self->{'vendor-os-name'};
		my $export = fetchExportsByFilter(
			$openslxDB, { 'name' => $exportName }, 'id'
		);
		if (defined $export) {
			changeExport(
				$openslxDB,
				{
					'name' => $exportName,
					'path' => $self->{'vendor-os-name'},
				}
			);
			vlog 0, _tr("Export <%s> has been updated in DB.\n", $exportName);
		} else {
			my $id = addExport(
				$openslxDB,
				{
					'name' => $exportName,
					'path' => $self->{'vendor-os-name'},
				}
			);
			vlog 0, _tr("Export <%s> has been added to DB (ID=%s).\n",
						$exportName, $id);
		}

		disconnectConfigDB($openslxDB);
	}
}

1;
################################################################################

=pod

=head1 NAME

OpenSLX::OSExport::Engine -

=head1 SYNOPSIS

=head1 DESCRIPTION

...

=cut
