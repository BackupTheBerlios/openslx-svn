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
# xserver/OpenSLX/Distro/Ubuntu.pm
#    - provides Ubuntu-specific overrides of the distro API for the xserver
#      plugin.
# -----------------------------------------------------------------------------
package xserver::OpenSLX::Distro::Ubuntu;

use strict;
use warnings;

use base qw(xserver::OpenSLX::Distro::Base);

use OpenSLX::Basics;
use OpenSLX::Utils;

################################################################################
### interface methods
################################################################################

sub setupXserverScript
{
    my $self     = shift;
    my $repoPath = shift;

    my $script = $self->SUPER::setupXserverScript($repoPath);

    $script .= unshiftHereDoc(<<'    End-of-Here');
        # ubuntu specific extension to stage3 xserver.sh
    End-of-Here

    return $script;
}

1;