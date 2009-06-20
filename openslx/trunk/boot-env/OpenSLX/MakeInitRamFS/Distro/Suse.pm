# Copyright (c) 2006..2009 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your suggestions, praise, or complaints to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org/
# -----------------------------------------------------------------------------
# MakeInitRamFS::Distro::SUSE.pm
#    - provides SUSE-specific overrides of the MakeInitRamFS::Distro API.
# -----------------------------------------------------------------------------
package OpenSLX::MakeInitRamFS::Distro::Suse;

use strict;
use warnings;

use base qw(OpenSLX::MakeInitRamFS::Distro::Base);

use OpenSLX::Basics;

################################################################################
### implementation
################################################################################
sub new
{
    my $class = shift;
    my $self = {
        'base-name' => 'suse',
    };
    return bless $self, $class;
}

sub applyChanges
{
    my $self   = shift;
    my $engine = shift;

    $engine->_addFilteredKernelModules( qw( hid hid_bright unix vesafb fbcon ));

    return;
}

sub determineMatchingHwinfoVersion
{
    my $self          = shift;
    my $distroVersion = shift;

    my %versionMap = (
        '10.2' => '13.11',
        '10.3' => '14.19',
        '11.0' => '15.3',
        '11.1' => '15.21',
    );
    return $versionMap{$distroVersion}
        || $self->SUPER::determineMatchingHwinfoVersion($distroVersion);
}

1;
