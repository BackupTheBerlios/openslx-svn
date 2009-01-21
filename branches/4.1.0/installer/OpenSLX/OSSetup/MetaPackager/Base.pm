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
#	- provides empty base of the OpenSLX OSSetup::MetaPackager API.
# -----------------------------------------------------------------------------
package OpenSLX::OSSetup::MetaPackager::Base;

use strict;
use warnings;

our $VERSION = 1.01;		# API-version . implementation-version

use Carp qw(confess);
use OpenSLX::Basics;

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

sub initPackageSources
{
}

sub setupPackageSource
{
}

sub updateBasicVendorOS
{
}

sub installSelection
{
}

sub startSession
{
	my $self = shift;
	
	addCleanupFunction('slxos-setup::meta-packager', 
	                   sub { $self->finishSession(); } );

	system('mount -t proc proc /proc 2>/dev/null');

	$self->{engine}->{distro}->startSession();
		# allow vendor specific extensions
}

sub finishSession
{
	my $self = shift;
	
	$self->{engine}->{distro}->finishSession();
		# allow vendor specific extensions

	system('umount /proc 2>/dev/null');

	removeCleanupFunction('slxos-setup::meta-packager');
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
