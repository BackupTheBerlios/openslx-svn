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
# virtualbox/OpenSLX/Distro/debian.pm
#    - provides Debian-specific overrides of the Distro API for the VirtualBox 
#      plugin.
# -----------------------------------------------------------------------------
package virtualbox::OpenSLX::Distro::Debian;

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

    # lenny(5.0) has v1.6
    # testing is ok. but no clue which lsb_release -rs it has...
    if ( $release eq "999999.0") {
        #the usual "in stage1 chroot we get another kernel vers. problem"
        #   kernel modules need to be installed from the cloned system
        #$engine->installPackages('virtualbox-ose');
        #system('/etc/init.d/virtualbox-ose setup');
    } else {
        print "Couldn't install VirtualBox, no package from distribution\n";
        exit;
    }

    return;
}

1;
