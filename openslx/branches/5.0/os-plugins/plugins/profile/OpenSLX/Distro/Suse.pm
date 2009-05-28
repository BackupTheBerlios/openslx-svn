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
# profile/OpenSLX/Distro/Suse.pm
#    - provides Suse-specific overrides of the Distro API for the profile 
#      plugin.
# -----------------------------------------------------------------------------
package profile::OpenSLX::Distro::Suse;

use strict;
use warnings;

use base qw(profile::OpenSLX::Distro::Base);

use OpenSLX::Basics;
use OpenSLX::Utils;

################################################################################
### interface methods
################################################################################

sub _getKdeHomeMap
{
    my $self        = shift;
    
    return;
}

sub getProfileDPAth
{
    my $self        = shift;
    
    
    return "/etc/profile.d/slx-kdehome.sh";
}

sub getKdeHome
{
    my $self        = shift;

    return ".openslx/suse/kde";
}

sub getGconfPathConfig
{
    my $self        = shift;
    
    return "/etc/gconf/2/path";
}


sub getGconfHome
{
    my $self        = shift;
    
    return ".openslx/suse/gconf";
}



1;
