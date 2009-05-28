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
# MakeInitRamFS::Distro::Ubuntu_9.pm
#    - provides Ubuntu-9.X-specific overrides of the MakeInitRamFS::Distro API.
# -----------------------------------------------------------------------------
package OpenSLX::MakeInitRamFS::Distro::Ubuntu_9;

use strict;
use warnings;

use base qw(OpenSLX::MakeInitRamFS::Distro::Ubuntu);

use OpenSLX::Basics;

################################################################################
### implementation
################################################################################
sub applyChanges
{
    my $self   = shift;
    my $engine = shift;

    $engine->_addFilteredKernelModules( 
        qw( af_packet unix hid uhci-hcd ohci-hcd )
    );

    return;
}

1;
