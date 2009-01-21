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
#	- provides empty base of the OpenSLX OSSetup::Packager API.
# -----------------------------------------------------------------------------
package OpenSLX::OSSetup::Packager::Base;

use strict;
use warnings;

our $VERSION = 1.01;		# API-version . implementation-version

use Carp qw(confess);

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

sub importTrustedPackageKeys
{
}

sub installPrerequiredPackages
{
}

sub installPackages
{
}

sub getInstalledPackages
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
