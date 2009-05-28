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
package xserver::OpenSLX::Distro::Suse_10_2;

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
        # suse specific extension to stage3 xserver.sh
        testmkd /mnt/var/lib/xkb/compiled
        testmkd /mnt/var/X11R6/bin
        ln -s /usr/bin/Xorg /mnt/var/X11R6/bin/X
        rm /mnt/etc/X11/xdm/SuSEconfig.xdm
        # relevant for older xservers only: check for kind of xorg module used
        # and patch the i8,9XX VGA BIOS if needed
        #if strinfile '"i810"' $xfc && [ -f /etc/hwinfo.display ] ; then
        #  highres=$(sort -run /etc/hwinfo.display|grep -i x -m 1)
        #  915resolution -l|sed -n "s/Mode //;/32 bits/p" > /tmp/915res
        #  strinfile ${highres} /tmp/915res || {
        #    915resolution $(grep -i x -m 1 /tmp/915res|sed "s/\ :.*//") $(echo \
        #      $highres|sed "s/x/\ /") 2>&1 >/dev/null;
        #  # for some reason the above does not work for a Dell laptop with Intel 
        #  # 855 chipset, so add another mode too
        #  915resolution 3c $(echo $highres|sed "s/x/\ /") 2>&1 >/dev/null; }
        #fi
    End-of-Here

    return $script;
}

1;
