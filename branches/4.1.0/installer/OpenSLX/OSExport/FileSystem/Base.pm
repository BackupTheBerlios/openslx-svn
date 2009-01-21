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
#	- provides empty base of the OpenSLX OSExport::FileSystem API.
# -----------------------------------------------------------------------------
package OpenSLX::OSExport::FileSystem::Base;

use strict;
use warnings;

our $VERSION = 1.01;		# API-version . implementation-version

use OpenSLX::Basics;

################################################################################
### interface methods
################################################################################
sub new
{
	confess "Creating OpenSLX::OSExport::FileSystem::Base-objects directly makes no sense!";
}

sub initialize
{
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

sub showExportConfigInfo
{
}

1;

################################################################################

=pod

=head1 NAME

OpenSLX::OSExport::FileSystem::Base - the base class for all OSExport::FileSystems

=cut
