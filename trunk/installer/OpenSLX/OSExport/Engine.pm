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
# Engine.pm
#	- provides driver engine for the OSExport API.
# -----------------------------------------------------------------------------
package OpenSLX::OSExport::Engine;

use vars qw(@ISA @EXPORT $VERSION);
$VERSION = 1.01;		# API-version . implementation-version

use Exporter;
@ISA = qw(Exporter);

@EXPORT = qw(
	%supportedExportTypes %supportedDistros
);

use strict;
use Carp;
use File::Basename;
use OpenSLX::Basics;

use vars qw(%supportedExportTypes %supportedDistros);

%supportedExportTypes = (
	'nfs'
		=> { module => 'NFS' },
	'nbd-squash'
		=> { module => 'NBD_Squash' },
);

%supportedDistros = (
	'<any>'
		=> { module => 'Any' },
	'debian'
		=> { module => 'Debian' },
	'fedora'
		=> { module => 'Fedora' },
	'gentoo'
		=> { module => 'Gentoo' },
	'suse'
		=> { module => 'SUSE' },
	'ubuntu'
		=> { module => 'Ubuntu' },
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
	my $exportType = lc(shift);

	if (!exists $supportedExportTypes{lc($exportType)}) {
		print _tr("Sorry, export type '%s' is unsupported.\n", $exportType);
		print _tr("List of supported export types:\n\t");
		print join("\n\t", sort keys %supportedExportTypes)."\n";
		exit 1;
	}

	$self->{'vendor-os-name'} = $vendorOSName;
	$self->{'export-type'} = $exportType;
	$self->{'export-name'} = "$vendorOSName-$exportType";
	$vendorOSName =~ m[^(.+?\-[^-]+)];
	my $distroName = $1;
	$self->{'distro-name'} = $distroName;

	# load module for the requested distro:
	if (!exists $supportedDistros{lc($distroName)}) {
		# try without _x86_64:
		$distroName =~ s[_x86_64$][];
		if (!exists $supportedDistros{lc($distroName)}) {
			# try basic distro-type (e.g. debian or suse):
			$distroName =~ s[-.+$][];
			if (!exists $supportedDistros{lc($distroName)}) {
				# fallback to generic implementation:
				$distroName = '<any>';
			}
		}
	}
	my $distroModule
		= "OpenSLX::OSExport::Distro::"
			.$supportedDistros{lc($distroName)}->{module};
	unless (eval "require $distroModule") {
		if ($! == 2) {
			die _tr("Distro-module <%s> not found!\n", $distroModule);
		} else {
			die _tr("Unable to load distro-module <%s> (%s)\n", $distroModule, $@);
		}
	}
	my $modVersion = $distroModule->VERSION;
	if ($modVersion < 1.01) {
		die _tr('Could not load module <%s> (Version <%s> required, but <%s> found)',
				$distroModule, 1.01, $modVersion);
	}
	my $distro = $distroModule->new;
	$distro->initialize($self);
	$self->{distro} = $distro;

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
		my $openslxDB = $configDBModule->new();
		$openslxDB->connect();

		# insert new export if it doesn't already exist in DB:
		my $exportName = $self->{'export-name'};
		my $export
			= $openslxDB->fetchExportByFilter({'name' => $exportName});
		if (defined $export) {
			vlog 0, _tr("No need to change export '%s' in OpenSLX-database.\n",
						$exportName);
		} else {
			my $vendorOSName = $self->{'vendor-os-name'};
			my $vendorOS
				= $openslxDB->fetchVendorOSByFilter({'name' => $vendorOSName});
			if (!defined $vendorOS) {
				die _tr("vendor-OS '%s' could not be found in OpenSLX-database, giving up!\n",
						$vendorOSName);
			}
			my $id = $openslxDB->addExport(
				{
					'vendor_os_id' => $vendorOS->{id},
					'name' => $exportName,
					'type' => $self->{'export-type'},
				}
			);
			vlog 0, _tr("Export <%s> has been added to DB (ID=%s).\n",
						$exportName, $id);
		}

		$openslxDB->disconnect();
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
