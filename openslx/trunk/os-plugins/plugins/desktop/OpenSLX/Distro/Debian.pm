# Copyright (c) 2006..2009 - OpenSLX GmbH
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
        # gdm does not like AUFS/UnionFS on its var directory
        rm -rf /mnt/var/lib/gdm
        mkdir -m 1770 /mnt/var/lib/gdm
        chown root:gdm /mnt/var/lib/gdm
    End-of-Here

    return $script;
}

sub setupKDMScript
{
    my $self     = shift;
    my $repoPath = shift;

    my $script = $self->SUPER::setupKDMScript($repoPath);
    
    $script .= unshiftHereDoc(<<'    End-of-Here');
        rllinker kdm 1 1
        echo '/usr/bin/kdm' > /mnt/etc/X11/default-display-manager
    End-of-Here

    return $script;
}

1;
