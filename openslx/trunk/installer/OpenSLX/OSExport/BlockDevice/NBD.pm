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
# NBD.pm
#    - provides NBD+Squashfs-specific overrides of the
#      OpenSLX::OSExport::BlockDevice API.
# -----------------------------------------------------------------------------
package OpenSLX::OSExport::BlockDevice::NBD;

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
    my $self = {'name' => 'nbd',};
    return bless $self, $class;
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

    my $serverIP = $export->{server_ip} || '';
    my $server 
        = length($serverIP) ? $serverIP : generatePlaceholderFor('serverip');
    $server .= ":$export->{port}" if length($export->{port});

    return "nbd://$server";
}

sub requiredBlockDeviceModules
{
    my $self = shift;

    return qw( nbd );
}

sub requiredBlockDeviceTools
{
    my $self = shift;

    return qw( nbd-client );
}

sub showExportConfigInfo
{
    my $self   = shift;
    my $export = shift;

    print(('#' x 80) . "\n");
    print _tr(
        "Please make sure you start a corresponding nbd-server:\n\t%s\n",
        "nbd-server $export->{port} $self->{fs}->{'export-path'} -r"
    );
    print(('#' x 80) . "\n");
    return;
}

1;
