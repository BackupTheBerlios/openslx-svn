# Copyright (c) 2008 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your suggestions, praise, or complaints to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org/
# -----------------------------------------------------------------------------
# qemukvm/OpenSLX/Distro/debian.pm
#    - provides Debian-specific overrides of the Distro API for the qemukvm 
#      plugin.
# -----------------------------------------------------------------------------
package qemukvm::OpenSLX::Distro::Debian;

use strict;
use warnings;

use base qw(qemukvm::OpenSLX::Distro::Base);

use OpenSLX::Basics;
use OpenSLX::Utils;

################################################################################
### interface methods
################################################################################

sub fillRunlevelScript
{
    my $self     = shift;
    my $location = shift;
    my $kind     = shift;

    my $script = unshiftHereDoc(<<'    End-of-Here');
 
    # something into here ...

    End-of-Here
    return $script;
}

1;
