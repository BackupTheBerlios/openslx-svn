# Copyright (c) 2009 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your suggestions, praise, or complaints to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org/
# -----------------------------------------------------------------------------
# MakeInitRamFS::Distro::SciLin.pm
#    - provides Scientific Linux specific overrides of the 
#      MakeInitRamFS::Distro API.
# -----------------------------------------------------------------------------
package OpenSLX::MakeInitRamFS::Distro::SciLin;

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
        'base-name' => 'scilin',
    };
    return bless $self, $class;
}

sub applyChanges
{
    my $self   = shift;
    my $engine = shift;

    $engine->_addFilteredKernelModules( qw( unix ));

    return;
}

sub determineMatchingHwinfoVersion
{
    my $self          = shift;
    my $distroVersion = shift;

    my %versionMap = (
        '4.7' => '13.11',
        '5.0' => '15.3',
    );
    return $versionMap{$distroVersion}
        || $self->SUPER::determineMatchingHwinfoVersion($distroVersion);
}

1;
