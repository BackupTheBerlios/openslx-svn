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
# Base.pm
#	- provides empty base of the OpenSLX OSExport::ExportType API.
# -----------------------------------------------------------------------------
package OpenSLX::OSExport::ExportType::Base;

use vars qw($VERSION);
$VERSION = 1.01;		# API-version . implementation-version

use strict;
use Carp;

use OpenSLX::Basics;
use OpenSLX::Utils;

################################################################################
### interface methods
################################################################################
sub new
{
	confess "Creating OpenSLX::OSExport::ExportType::Base-objects directly makes no sense!";
}

sub initialize
{
	my $self = shift;
	my $engine = shift;

	$self->{'engine'} = $engine;
}

sub exportVendorOS
{
}

sub purgeExport
{
}

sub checkRequirements
{
	return 1;
}

sub addExportToConfigDB
{
	my $self = shift;
	my $export = shift;
	my $openslxDB = shift;

	return $openslxDB->addExport($export);
}

sub generateExportURI
{
}

sub requiredFSMods
{
}

################################################################################
### implementation methods
################################################################################
sub determineIncludeExcludeList
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

1;
################################################################################

=pod

=head1 NAME

OpenSLX::OSExport::ExportType::Base - the base class for all OSExport::ExportTypes

=head1 SYNOPSIS

  package OpenSLX::OSExport::ExportType::coolnewexporter;

  use vars qw(@ISA $VERSION);
  @ISA = ('OpenSLX::OSExport::ExportType::Base');
  $VERSION = 1.01;

  use coolnewexporter;

  sub new
  {
      my $class = shift;
      my $self = {};
      return bless $self, $class;
  }

  # override all methods of OpenSLX::OSExport::ExportType::Base in order to
  # implement the support for a new export-type
  ...

I<The synopsis above outlines a class that implements a
OSExport::ExportType for the (imaginary) export-type B<coolnewexporter>>

=cut
