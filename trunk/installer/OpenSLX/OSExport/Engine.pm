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
	'nbd'
		=> { module => 'NBD' },
	'nbd-squashfs'
		=> { module => 'NBD_Squash' },
);

%supportedDistros = (
	'debian-3.1'
		=> { module => 'Debian_3_1' },
	'debian-4.0'
		=> { module => 'Debian_4_0' },
	'fedora-6'
		=> { module => 'Fedora_6' },
	'fedora-6-x86_64'
		=> { module => 'Fedora_6_x86_64' },
	'gentoo-2005.1'
		=> { module => 'Gentoo_2005_1' },
	'gentoo-2006.1'
		=> { module => 'Gentoo_2006_1' },
	'mandriva-2007.0'
		=> { module => 'Mandriva_2007_0' },
	'suse-9.3'
		=> { module => 'SUSE_9_3' },
	'suse-10.0'
		=> { module => 'SUSE_10_0' },
	'suse-10.0-x86_64'
		=> { module => 'SUSE_10_0_x86_64' },
	'suse-10.1'
		=> { module => 'SUSE_10_1' },
	'suse-10.1-x86_64'
		=> { module => 'SUSE_10_1_x86_64' },
	'suse-10.2'
		=> { module => 'SUSE_10_2' },
	'suse-10.2-x86_64'
		=> { module => 'SUSE_10_2_x86_64' },
	'ubuntu-6.06'
		=> { module => 'Ubuntu_6_06' },
	'ubuntu-6.10'
		=> { module => 'Ubuntu_6_10' },
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

	# load module for the requested distro:
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
	$distroModule->import;
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
