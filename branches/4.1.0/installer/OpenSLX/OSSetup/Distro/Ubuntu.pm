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
# Ubuntu.pm
#	- provides Ubuntu-specific overrides of the OpenSLX OSSetup API.
# -----------------------------------------------------------------------------
package OpenSLX::OSSetup::Distro::Ubuntu;

use strict;
use warnings;

use base qw(OpenSLX::OSSetup::Distro::Base);

use OpenSLX::Basics;

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
	my $self = shift;
	my $engine = shift;

	$self->SUPER::initialize($engine);
	$self->{'packager-type'}       = 'dpkg';
	$self->{'meta-packager-type'}  = $ENV{SLX_META_PACKAGER} || 'apt';
	$self->{'stage1c-faked-files'} = [];
	return;
}

1;
