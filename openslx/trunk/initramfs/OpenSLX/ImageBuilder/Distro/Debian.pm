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
# ImageBuilder::Distro::Debian.pm
#    - provides Debian-specific overrides of the ImageBuilder::Distro API.
# -----------------------------------------------------------------------------
package OpenSLX::ImageBuilder::Distro::Debian;

use strict;
use warnings;

use base qw(OpenSLX::ImageBuilder::Distro::Base);

use OpenSLX::Basics;

################################################################################
### implementation
################################################################################
sub new
{
    my $class = shift;
    my $self = {
        'base-name' => 'debian',
    };
    return bless $self, $class;
}

sub applyChanges
{
    my $self   = shift;
    my $engine = shift;

    $engine->_addFilteredKernelModules( qw( af_packet hid unix ));

    $engine->_addRequiredLib('/lib/libnss_compat.so.2');

    return;
}

1;