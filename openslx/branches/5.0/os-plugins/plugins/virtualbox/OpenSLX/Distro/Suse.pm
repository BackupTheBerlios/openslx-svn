# Copyright (c) 2009 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your suggestions, praise, or complaints to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org/
# -----------------------------------------------------------------------------
# virtualbox/OpenSLX/Distro/Suse.pm
#    - provides SUSE specific overrides of the distro API for the VirtualBox
#      plugin.
# -----------------------------------------------------------------------------
package virtualbox::OpenSLX::Distro::Suse;

use strict;
use warnings;

use base qw(virtualbox::OpenSLX::Distro::Base);

use OpenSLX::Basics;
use OpenSLX::Utils;

################################################################################
### interface methods
################################################################################

sub installVbox
{
    my $self     = shift;

    my $engine = $self->{'engine'};
    my $release = `lsb_release -rs`;
    chomp($release);
    
    if ( $release eq "11.1" || $release eq "11.0" || $release eq "10.3") {
        $engine->installPackages('virtualbox-ose');
    } else {
        print "Couldn't install VirtualBox, no package from distribution\n";
        exit;
    }

    return;
}

1;
