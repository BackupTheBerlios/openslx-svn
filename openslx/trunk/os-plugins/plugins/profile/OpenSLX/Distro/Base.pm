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
# profile/OpenSLX/Distro/Base.pm
#    - provides base implementation of the Distro API for the profile plugin.
# -----------------------------------------------------------------------------
package profile::OpenSLX::Distro::Base;

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

sub getXsessionDPath
{
    my $self = shift;
    
    return "/etc/X11/Xsession.d/10slx-home_env";
}


sub getProfileDPAth
{
    my $self = shift;
    
    return "/etc/profile.d/slx-kdehome.sh";
}

sub getKdeHome
{
    my $self = shift;

    return ".openslx/unknown/kde";
}

sub getGconfPathConfig
{
	my $self = shift;
	
	return "/etc/gconf/2/path";
}


sub getGconfHome
{
    my $self = shift;
    
    return ".openslx/unknown/gconf";
}


1;
