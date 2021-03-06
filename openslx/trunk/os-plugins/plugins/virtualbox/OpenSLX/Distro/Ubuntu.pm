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
# virtualbox/OpenSLX/Distro/Ubuntu.pm
#    - provides Ubuntu-specific overrides of the Distro API for the virtualbox
#      plugin.
# -----------------------------------------------------------------------------
package virtualbox::OpenSLX::Distro::Ubuntu;

use strict;
use warnings;

# inherit everything from Debian (as Ubuntu is based on it anyway)
use base qw(virtualbox::OpenSLX::Distro::Debian);
use base qw(virtualbox::OpenSLX::Distro::Base);

use OpenSLX::Basics;
use OpenSLX::Utils;


################################################################################
#### interface methods
################################################################################
sub installVbox
{
    my $self     = shift;

    my $engine = $self->{'engine'};
    my $release = `lsb_release -rs`;
    chomp($release);

    # hardy (8.04LTS): only version VBox v1.5
    if ( $release eq "8.10" || $release eq "9.04") {
        #the usual "in stage1 chroot we get another kernel vers. problem"
        #   kernel modules need to be installed from the cloned system
        #$engine->installPackages("virtualbox-ose");
        #system('/etc/init.d/virtualbox-ose setup');
    } else {
        print "Couldn't install VirtualBox, no package from distribution!\n";
        exit;
    }


    return;
}

1;
