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
# desktop/OpenSLX/Distro/Debian.pm
#    - provides Debian-specific overrides of the Distro API for the desktop 
#      plugin.
# -----------------------------------------------------------------------------
package desktop::OpenSLX::Distro::Debian;

use strict;
use warnings;

use base qw(desktop::OpenSLX::Distro::Base);

use OpenSLX::Basics;
use OpenSLX::Utils;

################################################################################
### interface methods
################################################################################

sub setupGDMScript
{
    my $self     = shift;
    my $repoPath = shift;

    my $script = $self->SUPER::setupGDMScript($repoPath);
    
    $script .= unshiftHereDoc(<<'    End-of-Here');
        rllinker gdm 1 1
        echo '/usr/bin/gdm' > /mnt/etc/X11/default-display-manager
    End-of-Here

    return $script;
}


1;