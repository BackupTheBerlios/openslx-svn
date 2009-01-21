# Base.pm - provides empty base of the distro-specific part of the
# OpenSLX OSExport API.
#
# (c) 2006 - OpenSLX.com
#
# Oliver Tappe <ot@openslx.com>
#
package OpenSLX::OSExport::Distro::Base;

use vars qw($VERSION);
$VERSION = 1.01;		# API-version . implementation-version

use strict;
use Carp;
use File::Basename;
use OpenSLX::Basics;

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
