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
# xserver/OpenSLX/Distro/Suse.pm
#    - provides SUSE-specific overrides of the Distro API for the xserver
#      plugin.
# -----------------------------------------------------------------------------
package xserver::OpenSLX::Distro::Suse;

use strict;
use warnings;

use base qw(xserver::OpenSLX::Distro::Base);

use File::Path;

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
        # SuSE specific extension to stage3 xserver.sh
        testmkd /mnt/var/lib/xkb/compiled
        testmkd /mnt/var/X11R6/bin
        testmkd /mnt/var/lib/xdm/authdir/authfiles 0700
        ln -s /usr/bin/Xorg /mnt/var/X11R6/bin/X
        rm /mnt/etc/X11/xdm/SuSEconfig.xdm
    End-of-Here

    return $script;
}

1;
