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
#    - provides empty base of the OpenSLX OSExport::BlockDevice API.
# -----------------------------------------------------------------------------
package OpenSLX::OSExport::BlockDevice::Base;

use strict;
use warnings;

our $VERSION = 1.01;        # API-version . implementation-version

use Scalar::Util qw( weaken );

use OpenSLX::Basics;

################################################################################
### interface methods
################################################################################
sub new
{
    confess "Creating OpenSLX::OSExport::BlockDevice::Base-objects directly makes no sense!";
}

sub initialize
{
    my $self = shift;
    my $engine = shift;
    my $fs     = shift;    

    $self->{'engine'} = $engine;
    weaken($self->{'engine'});
        # avoid circular reference between block-device and its engine

    $self->{'fs'} = $fs;
    weaken($self->{'fs'});
        # avoid circular reference between block-device and its file-system
}

sub getExportPort
{
}

sub generateExportURI
{
}

sub requiredBlockDeviceModules
{
}

sub requiredBlockDeviceTools
{
}

sub showExportConfigInfo
{
}

1;
################################################################################

=pod

=head1 NAME

OpenSLX::OSExport::BlockDevice::Base - the base class for all OSExport::BlockDevices

=cut
