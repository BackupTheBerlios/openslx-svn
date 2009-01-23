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
# BootEnvironment::PREBOOT_CD.pm
#    - provides CD-specific implementation of the BootEnvironment API.
# -----------------------------------------------------------------------------
package OpenSLX::BootEnvironment::PREBOOT_CD;

use strict;
use warnings;

use base qw(OpenSLX::BootEnvironment::Base);

use File::Basename;
use File::Path;

use OpenSLX::Basics;
use OpenSLX::Utils;

sub initialize
{
    my $self   = shift;
    my $params = shift;
    
    return if !$self->SUPER::initialize($params);

    $self->{'original-path'} = "$openslxConfig{'public-path'}/preboot-cd";
    $self->{'target-path'}   = "$openslxConfig{'public-path'}/preboot-cd.new";

    if (!$self->{'dry-run'}) {
        mkpath([$self->{'original-path'}]);
        rmtree($self->{'target-path'});
        mkpath("$self->{'target-path'}/client-config");
    }

    return 1;
}

1;
