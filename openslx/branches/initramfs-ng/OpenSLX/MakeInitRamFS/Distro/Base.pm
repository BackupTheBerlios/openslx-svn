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
# MakeInitRamFS::Base.pm
#    - provides empty base of the distro-specific part of the OpenSLX
#      MakeInitRamFS API.
# -----------------------------------------------------------------------------
package OpenSLX::MakeInitRamFS::Distro::Base;

use strict;
use warnings;

our $VERSION = 1.01;        # API-version . implementation-version

use OpenSLX::Basics;

################################################################################
### interface methods
################################################################################
sub new
{
    my $class = shift;
    my $self = {
        'base-name' => 'base',
    };
    return bless $self, $class;
}

sub applyChanges
{
}

1;
