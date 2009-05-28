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
# infoscreen/OpenSLX/Distro/Ubuntu.pm
#    - provides Debian-specific overrides of the Distro API for the infoscreen 
#      plugin.
# -----------------------------------------------------------------------------
package infoscreen::OpenSLX::Distro::Ubuntu;

use strict;
use warnings;

use base qw(infoscreen::OpenSLX::Distro::Base);

use OpenSLX::Basics;
use OpenSLX::Utils;

################################################################################
### interface methods
################################################################################

sub getRequirements
{
    my $self        = shift;
    
    return ('libxml2', 'libcurl3', 'libimlib2', 'libx11-6');
}

sub getPackagemanagerCommand
{
    my $self        = shift;
    
    return "aptitude install";
}


1;
