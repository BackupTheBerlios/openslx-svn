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

use strict;
use warnings;

our (@ISA, @EXPORT, $VERSION);
$VERSION = 1.01;    # API-version . implementation-version

use Exporter;
@ISA = qw(Exporter);

@EXPORT = qw(
  %supportedExportFileSystems %supportedExportBlockDevices
  @supportedExportTypes %supportedDistros
);

use File::Basename;

use OpenSLX::Basics;
use OpenSLX::Utils;

our (
  %supportedExportFileSystems, %supportedExportBlockDevices,
  @supportedExportTypes, %supportedDistros
);

%supportedExportFileSystems = (
	'nfs'  => 'NFS',
	'sqfs' => 'SquashFS',
);

%supportedExportBlockDevices = ('nbd' => 'NBD', 'aoe' => 'AoE');

@supportedExportTypes = ('nfs', 'sqfs-aoe', 'sqfs-nbd');

%supportedDistros = (
	'<any>'  => {module => 'Any'},
	'debian' => {module => 'Debian'},
	'fedora' => {module => 'Fedora'},
	'gentoo' => {module => 'Gentoo'},
	'suse'   => {module => 'SUSE'},
	'ubuntu' => {module => 'Ubuntu'},
);

################################################################################
### interface methods
################################################################################
sub new
{
	my $class = shift;

	my $self = {};

	return bless $self, $class;
}

sub initializeFromExisting
{
	my $self       = shift;
	my $exportName = shift;

	my $openslxDB = instantiateClass("OpenSLX::ConfigDB");
	$openslxDB->connect();

	my $export = $openslxDB->fetchExportByFilter({'name' => $exportName});
	if (!defined $export) {
		die _tr("Export '%s' not found in DB, giving up!", $exportName);
	}
	my $vendorOS =
	  $openslxDB->fetchVendorOSByFilter({'id' => $export->{vendor_os_id}});

	$openslxDB->disconnect();

	$self->_initialize($vendorOS->{name}, $vendorOS->{id}, $export->{name},
		$export->{type});
	return;
}

sub initializeForNew
{
	my $self         = shift;
	my $vendorOSName = shift;
	my $exportType   = lc(shift);

	my $openslxDB = instantiateClass("OpenSLX::ConfigDB");
	$openslxDB->connect();

	my $vendorOS = $openslxDB->fetchVendorOSByFilter({'name' => $vendorOSName});
	if (!defined $vendorOS) {
		die _tr("vendor-OS '%s' not found in DB, giving up!", $vendorOSName);
	}

	my $exportName = "$vendorOSName:$exportType";

	$openslxDB->disconnect();

	$self->_initialize($vendorOS->{name}, $vendorOS->{id}, $exportName,
		$exportType);
	return;
}

sub exportVendorOS
{
	my $self = shift;

	if (!$self->{'exporter'}->checkRequirements($self->{'vendor-os-path'})) {
		die _tr(
			"clients wouldn't be able to access the exported root-fs!\nplease "
			  . "install the missing module(s) or use another export-type.");
	}

	$self->{'exporter'}->exportVendorOS($self->{'vendor-os-path'},);
	vlog(
		0,
		_tr(
			"vendor-OS '%s' successfully exported to '%s'!",
			$self->{'vendor-os-path'},
			$self->{exporter}->{'export-path'}
		)
	);
	$self->_addExportToConfigDB();
	return;
}

sub purgeExport
{
	my $self = shift;

	if ($self->{'exporter'}->purgeExport()) {
		vlog(
			0,
			_tr(
				"export '%s' successfully removed!",
				$self->{exporter}->{'export-path'}
			)
		);
	}
	$self->_removeExportFromConfigDB();
	return;
}

sub generateExportURI
{
	my $self = shift;

	return $self->{exporter}->generateExportURI(@_);
}

sub requiredFSMods
{
	my $self = shift;

	return $self->{exporter}->requiredFSMods();
}

################################################################################
### implementation methods
################################################################################
sub _initialize
{
	my $self         = shift;
	my $vendorOSName = shift;
	my $vendorOSId   = shift;
	my $exportName   = shift;
	my $exportType   = lc(shift);

	if (!grep { $_ eq $exportType } @supportedExportTypes) {
		vlog(0,
			    _tr("Sorry, export type '%s' is unsupported.\n", $exportType)
			  . _tr("List of supported export types:\n\t")
			  . join("\n\t", sort @supportedExportTypes));    
		exit 1;
	}
	$exportType =~ m[^(\w+)(?:-(\w+))?$];
	my $exportFS = lc($1);
	my $exportBD = lc($2);
	vlog(2, "export-fs='$exportFS' export-bd='$exportBD'");

	$self->{'vendor-os-name'} = $vendorOSName;
	$self->{'vendor-os-id'}   = $vendorOSId;
	$self->{'export-name'}    = $exportName;
	$self->{'export-type'}    = $exportType;
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
	my $distroModuleName = $supportedDistros{lc($distroName)}->{module};
	my $distro           =
	  instantiateClass("OpenSLX::OSExport::Distro::$distroModuleName");
	$distro->initialize($self);
	$self->{distro} = $distro;

	# load module for the requested export type:
	my $fsModuleName = $supportedExportFileSystems{$exportFS};
	my $exporter     =
	  instantiateClass("OpenSLX::OSExport::FileSystem::$fsModuleName");
	if (length($exportBD)) {
		my $blockModuleName = $supportedExportBlockDevices{$exportBD};
		my $blockDevice     =
		  instantiateClass("OpenSLX::OSExport::BlockDevice::$blockModuleName");
		$blockDevice->initialize($self, $exporter);
		$exporter->initialize($self, $blockDevice);
	} else {
		$exporter->initialize($self);
	}
	$self->{'exporter'} = $exporter;

	# setup source and target paths:
	$self->{'vendor-os-path'} =
	  "$openslxConfig{'private-path'}/stage1/$vendorOSName";
	vlog(
		1,
		_tr(
			"vendor-OS from '%s' will be exported to '%s'",
			$self->{'vendor-os-path'},
			$exporter->{'export-path'}
		)
	);
	return;
}

sub _addExportToConfigDB
{
	my $self = shift;

	my $openslxDB = instantiateClass("OpenSLX::ConfigDB");
	$openslxDB->connect();

	my $export = $openslxDB->fetchExportByFilter(
		{
			'name'         => $self->{'export-name'},
			'vendor_os_id' => $self->{'vendor-os-id'},
		}
	);
	if (defined $export) {
		vlog(
			0,
			_tr(
				"No need to change export '%s' in OpenSLX-database.\n",
				$self->{'export-name'}
			)
		);
		$self->{exporter}->showExportConfigInfo($export);
	} else {
		$export = {
			'vendor_os_id' => $self->{'vendor-os-id'},
			'name'         => $self->{'export-name'},
			'type'         => $self->{'export-type'},
		};

		my $id = $self->{exporter}->addExportToConfigDB($export, $openslxDB);
		vlog(
			0,
			_tr(
				"Export '%s' has been added to DB (ID=%s)...\n",
				$self->{'export-name'}, $id
			)
		);

		$self->{exporter}->showExportConfigInfo($export) if $id;
	}

	my $system = $openslxDB->fetchSystemByFilter({
		'name' => $self->{'export-name'},
	});
	if (!defined $system) {
		# now create a default system for that export, using the standard kernel:
		system("slxconfig add-system $self->{'export-name'}");
	}

	$openslxDB->disconnect();
	return;
}

sub _removeExportFromConfigDB
{
	my $self = shift;

	my $openslxDB = instantiateClass("OpenSLX::ConfigDB");
	$openslxDB->connect();

	# remove export from DB:
	my $exportName = $self->{'export-name'};
	my $export = $openslxDB->fetchExportByFilter({'name' => $exportName,});
	if (!defined $export) {
		vlog(
			0,
			_tr(
				"Export '%s' doesn't exist in OpenSLX-database.\n", $exportName
			)
		);
	} else {
		# remove all systems using this export and then remove the
		# export itself:
		my @systemIDs =
		  map { $_->{id} }
		  $openslxDB->fetchSystemByFilter({'export_id' => $export->{id}}, 'id');
		vlog(
			1,
			_tr(
				"removing systems '%s' from DB, since they belong to the export"
				  . " being deleted.\n",
				join ',',
				@systemIDs
			)
		);
		$openslxDB->removeSystem(\@systemIDs);
		$openslxDB->removeExport($export->{id});
		vlog(0, _tr("Export '%s' has been removed from DB.\n", $exportName));
	}

	$openslxDB->disconnect();
	return;
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

