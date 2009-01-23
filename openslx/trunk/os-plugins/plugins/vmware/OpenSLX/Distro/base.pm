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
# base.pm
#	- provides empty base of the OpenSLX OSPlugin Distro API for the vmware
#     plugin.
# -----------------------------------------------------------------------------
package OpenSLX::Distro::base;

use strict;
use warnings;

our $VERSION = 1.01;		# API-version . implementation-version

use OpenSLX::Basics;
use OpenSLX::Utils;

################################################################################
### interface methods
################################################################################
sub new
{
	confess "Creating OpenSLX::OSPlugin::Distro::Base-objects directly makes no sense!";
}

sub initialize
{
	my $self = shift;
	my $engine = shift;
	
	return 1;
}


1;
