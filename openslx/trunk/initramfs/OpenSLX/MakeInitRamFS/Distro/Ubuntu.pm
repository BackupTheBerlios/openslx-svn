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
# MakeInitRamFS::Distro::Ubuntu.pm
#    - provides Ubuntu-specific overrides of the MakeInitRamFS::Distro API.
# -----------------------------------------------------------------------------
package OpenSLX::MakeInitRamFS::Distro::Ubuntu;

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
        'base-name' => 'ubuntu',
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

    # TODO: fill this map (see Suse.pm for an example)
    my %suseMap = (
    );
    return $suseMap{$distroVersion}
        || $self->SUPER::determineMatchingHwinfoVersion($distroVersion);
}

1;