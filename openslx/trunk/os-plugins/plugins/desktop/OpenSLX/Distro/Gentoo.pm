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
# desktop/OpenSLX/Distro/Gentoo.pm
#    - provides Gentoo-specific overrides of the Distro API for the desktop
#      plugin.
# -----------------------------------------------------------------------------
package desktop::OpenSLX::Distro::Gentoo;

use strict;
use warnings;

use base qw(desktop::OpenSLX::Distro::Base);

use OpenSLX::Basics;

################################################################################
### interface methods
################################################################################

# TODO: implement!

sub setupKDEHOME
{
    my $self     = shift;
    my $path     = "/etc/profile.d/kde.sh";

    my $script = unshiftHereDoc(<<'    End-of-Here');
        export KDEHOME=".kde-$(kde-config -v | grep KDE | \
            awk {'print $2'})-gentoo"
    End-of-Here

    spitFile($path, $script);

    return;
}

1;
