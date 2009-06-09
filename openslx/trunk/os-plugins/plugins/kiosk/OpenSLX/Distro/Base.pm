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
# kiosk/OpenSLX/Distro/Base.pm
#    - provides base implementation of the Distro API for the kiosk plugin.
# -----------------------------------------------------------------------------
package kiosk::OpenSLX::Distro::Base;

use strict;
use warnings;

our $VERSION = 1.01;        # API-version . implementation-version

use Scalar::Util qw( weaken );

use OpenSLX::Basics;
use OpenSLX::Utils;

################################################################################
### interface methods
################################################################################
sub new
{
    my $class = shift;
    my $self = {};
    return bless $self, $class;
}

sub initialize
{
    my $self        = shift;
    $self->{engine} = shift;
    weaken($self->{engine});
        # avoid circular reference between plugin and its engine
    
    return 1;
}

sub getKgettySetupScript
{
    my $self = shift;

    my $script = unshiftHereDoc(<<"    End-of-Here");
        #!/bin/sh
        # written by OpenSLX-plugin 'kiosk'
        
        kgettyCmd=\$1
        sed -i /mnt/etc/inittab \\
            -e "s,^\(1:[^:]*:respawn\):.*tty1,\\1:\$kgettyCmd,"

    End-of-Here
    
    return $script;    

}


1;
