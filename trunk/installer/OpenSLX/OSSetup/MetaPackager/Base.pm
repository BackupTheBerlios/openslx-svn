# Base.pm - provides empty base of the OpenSLX OSSetup::MetaPackager API.
#
# (c) 2006 - OpenSLX.com
#
# Oliver Tappe <ot@openslx.com>
#
package OpenSLX::OSSetup::MetaPackager::Base;

use vars qw($VERSION);
$VERSION = 1.01;		# API-version . implementation-version

use strict;
use Carp;

################################################################################
### interface methods
################################################################################
sub new
{
	confess "Creating OpenSLX::OSSetup::MetaPackager::Base-objects directly makes no sense!";
}

sub initialize
{
	my $self = shift;
	my $engine = shift;

	$self->{'engine'} = $engine;
}

sub setupPackageSource
{
}

1;
################################################################################

=pod

=head1 NAME

OpenSLX::OSSetup::MetaPackager::Base - the base class for all OSSetup::MetaPackagers

=head1 SYNOPSIS

  package OpenSLX::OSSetup::MetaPackager::coolnewpkg;

  use vars qw(@ISA $VERSION);
  @ISA = ('OpenSLX::OSSetup::MetaPackager::Base');
  $VERSION = 1.01;

  use coolnewpkg;

  sub new
  {
      my $class = shift;
      my $self = {};
      return bless $self, $class;
  }

  # override all methods of OpenSLX::OSSetup::MetaPackager::Base in order to
  # implement the support for a new meta-packager
  ...

I<The synopsis above outlines a class that implements a
OSSetup::MetaPackager for the (imaginary) meta-packager B<coolnewpkg>>

=cut