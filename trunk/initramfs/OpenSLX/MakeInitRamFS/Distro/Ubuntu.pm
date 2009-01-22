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
# MakeInitRamFS::Ubuntu.pm
#	- provides Ubuntu-specific overrides of the OpenSLX MakeInitRamFS API.
# -----------------------------------------------------------------------------
package OpenSLX::MakeInitRamFS::Distro::Ubuntu;

use strict;
use warnings;

use base qw(OpenSLX::MakeInitRamFS::Distro::Debian);

use OpenSLX::Basics;

################################################################################
### implementation
################################################################################
sub new
{
	my $class = shift;
	my $self = {
		'base-name' => 'ubuntu',
	};
	return bless $self, $class;
}

1;