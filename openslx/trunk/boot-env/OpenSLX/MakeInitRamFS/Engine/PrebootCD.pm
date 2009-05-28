# Copyright (c) 2006-2008 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your suggestions, praise, or complaints to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org/
# -----------------------------------------------------------------------------
# MakeInitialRamFS::Engine::PrebootCD.pm
#    - provides driver engine for MakeInitialRamFS API, implementing the
#      preboot behaviour that is specific for CDs.
# -----------------------------------------------------------------------------
package OpenSLX::MakeInitRamFS::Engine::PrebootCD;

use strict;
use warnings;

use base qw(OpenSLX::MakeInitRamFS::Engine::Preboot);

use OpenSLX::Basics;
use OpenSLX::Utils;

################################################################################
### implementation methods
################################################################################
sub _copyVariantSpecificFiles
{
    my $self = shift;

    my $dataDir = "$openslxConfig{'base-path'}/share/boot-env/preboot-cd";
    $self->addCMD("cp $dataDir/init $self->{'build-path'}/");
    
    return 1;
}

1;
