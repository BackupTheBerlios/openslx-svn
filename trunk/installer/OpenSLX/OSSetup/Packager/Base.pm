# Base.pm - provides empty base of the OpenSLX OSSetup::Packager API.
#
# (c) 2006 - OpenSLX.com
#
# Oliver Tappe <ot@openslx.com>
#
package OpenSLX::OSSetup::Packager::Base;

use vars qw($VERSION);
$VERSION = 1.01;		# API-version . implementation-version

use strict;
use Carp;

################################################################################
### interface methods
################################################################################
sub new
{
	confess "Creating OpenSLX::OSSetup::Packager::Base-objects directly makes no sense!";
}

sub initialize
{
	my $self = shift;
	my $distro = shift;

	$self->{'distro'} = $distro;
}

sub unpackPackages
{
}

sub unpackPackages
{
}

sub importTrustedPackageKeys
{
}

sub installPrerequiredPackages
{
}

sub installPackages
{
}

1;
################################################################################

=pod

=head1 NAME

OpenSLX::OSSetup::Packager::Base - the base class for all OSSetup::Packagers

=head1 SYNOPSIS

  package OpenSLX::OSSetup::Packager::coolnewpkg;

  use vars qw(@ISA $VERSION);
  @ISA = ('OpenSLX::OSSetup::Packager::Base');
  $VERSION = 1.01;

  use coolnewpkg;

  sub new
  {
      my $class = shift;
      my $self = {};
      return bless $self, $class;
  }

  # override all methods of OpenSLX::OSSetup::Packager::Base in order to
  # implement the support for a new packager
  ...

I<The synopsis above outlines a class that implements a
OSSetup::Packager for the (imaginary) packager B<coolnewpkg>>

=cut
