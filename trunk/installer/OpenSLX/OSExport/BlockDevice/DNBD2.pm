# Copyright (c) 2006, 2008 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your suggestions, praise, or complaints to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org/
# -----------------------------------------------------------------------------
# DNBD2.pm
#	- provides DNBD2+Squashfs-specific overrides of the
#	  OpenSLX::OSExport::BlockDevice API.
# -----------------------------------------------------------------------------
package OpenSLX::OSExport::BlockDevice::DNBD2;

use strict;
use warnings;

use base qw(OpenSLX::OSExport::BlockDevice::Base);

use File::Basename;
use OpenSLX::Basics;
use OpenSLX::ConfigDB qw(:support);
use OpenSLX::OSExport::BlockDevice::Base 1;
use OpenSLX::Utils;

################################################################################
### interface methods
################################################################################
sub new
{
	my $class = shift;
	my $self = {'name' => 'dnbd2',};
	return bless $self, $class;
}

sub initialize
{
	my $self   = shift;
	my $engine = shift;
	my $fs     = shift;    

	$self->{'engine'} = $engine;
	$self->{'fs'}     = $fs;
	return;
}

sub getExportPort
{
	my $self      = shift;
	my $openslxDB = shift;

	return $openslxDB->incrementGlobalCounter('next-dnbd2-server-port');
}

sub generateExportURI
{
	my $self   = shift;
	my $export = shift;

	my $serverIP = $export->{server_ip} || '';
	my $server 
		= length($serverIP) ? $serverIP : generatePlaceholderFor('serverip');
	$server .= ":$export->{port}" if length($export->{port});

	return "dnbd2://$server";
}

sub requiredBlockDeviceModules
{
	my $self = shift;

	return qw( dnbd2 );
}

sub requiredBlockDeviceTools
{
	my $self = shift;

	return qw( );
}

sub showExportConfigInfo
{
	my $self   = shift;
	my $export = shift;

	print(('#' x 80) . "\n");
	print _tr(
		"Please make sure you start a corresponding dnbd2-server:\n\t%s\n",
		"Create or modify a config file like /etc/dnbd2/server.conf, looking like:",
		"$server",
		"$export->{port}",
		"$self->{fs}->{'export-path'}
		"dnbd2-server /etc/dnbd2/server.conf"
	);
	print(('#' x 80) . "\n");
	return;
}

1;
