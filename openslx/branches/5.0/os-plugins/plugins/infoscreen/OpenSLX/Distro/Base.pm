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
# infoscreen/OpenSLX/Distro/Base.pm
#    - provides base implementation of the Distro API for the infoscreen plugin.
# -----------------------------------------------------------------------------
package infoscreen::OpenSLX::Distro::Base;

use strict;
use warnings;

our $VERSION = 1.01;        # API-version . implementation-version

use File::Basename;

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
    
    return 1;
}

sub getRequirements
{
	my $self        = shift;
	
	return ('libxml2', 'libcurl', 'libimlib2', 'libx11');
}

sub getPackagemanagerCommand
{
	my $self        = shift;
	
	return "yum install";
}

1;
