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
# AoE.pm
#	- provides ATA-over-Ethernet specific overrides of the
#	  OpenSLX::OSExport::BlockDevice API.
# -----------------------------------------------------------------------------
package OpenSLX::OSExport::BlockDevice::AoE;

use vars qw($VERSION);
use base qw(OpenSLX::OSExport::BlockDevice::Base);
$VERSION = 1.01;    # API-version . implementation-version

use strict;
use Carp;
use File::Basename;
use OpenSLX::Basics;
use OpenSLX::ConfigDB qw(:support);
use OpenSLX::OSExport::BlockDevice::Base 1;
use OpenSLX::Utils;

#
#
# N.B.: currently this is just a stub
#
#


################################################################################
### interface methods
################################################################################
sub new
{
	my $class = shift;
	my $self = {'name' => 'aoe',};
	return bless $self, $class;
}

sub initialize
{
	my $self   = shift;
	my $engine = shift;
	my $fs     = shift;    

	$self->{'engine'} = $engine;
	$self->{'fs'}     = $fs;
}

sub getExportPort
{
	my $self      = shift;
	my $openslxDB = shift;

	return $openslxDB->incrementGlobalCounter('next-nbd-server-port');
}

sub generateExportURI
{
	my $self   = shift;
	my $export = shift;

	my $server =
	  length($export->{server_ip})
	  ? $export->{server_ip}
	  : generatePlaceholderFor('serverip');
	$server .= ":$export->{port}" if length($export->{port});

	return "aoe://$server";
}

sub requiredBlockDeviceModules
{
	my $self = shift;

	return 'aoe';
}

sub showExportConfigInfo
{
	my $self   = shift;
	my $export = shift;

	print(('#' x 80) . "\n");
	print _tr(
		"Please make sure you start a corresponding aoe-server:\n\t%s\n",
		"... (don't know how this is done yet)"
	);
	print(('#' x 80) . "\n");
}

1;