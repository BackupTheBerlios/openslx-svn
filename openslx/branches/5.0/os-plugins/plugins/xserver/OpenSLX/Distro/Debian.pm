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
# xserver/OpenSLX/Distro/Debian.pm
#    - provides Debian-specific overrides of the distro API for the xserver
#      plugin.
# -----------------------------------------------------------------------------
package xserver::OpenSLX::Distro::Debian;

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
        # Debian specific extension to stage3 xserver.sh
        testmkd /mnt/var/lib/xkb
    End-of-Here

    return $script;
}

# stage3 script might need to add special path /var/X11R6/bin to the PATH variable
# # fixme!! add path directly to /etc/profile!?
# #[ "x$addpath" != "x" ] && \
# #  echo -e "# added path component by $0: $date\n\
# #PATH=\"\$PATH:/var/X11R6/bin\"" >>/mnt/etc/profile

1;
