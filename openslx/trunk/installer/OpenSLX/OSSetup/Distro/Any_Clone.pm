# Copyright (c) 2006, 2007 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your suggestions, praise, or complaints to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org/
# -----------------------------------------------------------------------------
# Any_Clone.pm
#	- provides generic clone-only overrides of the OpenSLX OSSetup API.
# -----------------------------------------------------------------------------
package OpenSLX::OSSetup::Distro::Any_Clone;

use strict;
use warnings;

use base qw(OpenSLX::OSSetup::Distro::Base);

################################################################################
### interface methods
################################################################################
sub new
{
	my $class = shift;
	my $self = {};
	return bless $self, $class;
}

1;