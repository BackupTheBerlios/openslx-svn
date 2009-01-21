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
# Base.pm
#	- provides empty base of the distro-specific part of the OpenSLX
#	  OSExport API.
# -----------------------------------------------------------------------------
package OpenSLX::OSExport::Distro::Base;

use strict;
use warnings;

our $VERSION = 1.01;		# API-version . implementation-version

use Carp qw(confess);

################################################################################
### interface methods
################################################################################
sub new
{
	confess "Creating OpenSLX::OSExport::Distro::Base-objects directly makes no sense!";
}

sub initialize
{
	my $self = shift;
	my $engine = shift;

	$self->{'engine'} = $engine;

	$self->initDistroInfo();
}

sub initDistroInfo
{
}

1;
################################################################################

=pod

=head1 NAME

OpenSLX::OSExport::Distro::Base

=head1 SYNOPSIS

...

=cut
