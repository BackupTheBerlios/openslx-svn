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
# kiosk/OpenSLX/Distro/Ubuntu.pm
#    - provides Debian-specific overrides of the Distro API for the kiosk 
#      plugin.
# -----------------------------------------------------------------------------
package kiosk::OpenSLX::Distro::Ubuntu;

use strict;
use warnings;

use base qw(kiosk::OpenSLX::Distro::Base);

use OpenSLX::Basics;
use OpenSLX::Utils;

################################################################################
### interface methods
################################################################################

sub getKgettySetupScript
{
    my $self = shift;

    my $script = unshiftHereDoc(<<"    End-of-Here");
        #!/bin/sh
        # written by OpenSLX-plugin 'kiosk'
        
        kgettyCmd=\$1
        sed -i /mnt/etc/event.d/tty1 \\
            -e "s,exec.*,exec \$kgettyCmd,"

    End-of-Here
    
    return $script;    

}

1;
