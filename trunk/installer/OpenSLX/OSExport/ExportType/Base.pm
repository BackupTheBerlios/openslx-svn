# Base.pm - provides empty base of the OpenSLX OSExport::ExportType API.
#
# (c) 2006 - OpenSLX.com
#
# Oliver Tappe <ot@openslx.com>
#
package OpenSLX::OSExport::ExportType::Base;

use vars qw($VERSION);
$VERSION = 1.01;		# API-version . implementation-version

use strict;
use Carp;

################################################################################
### interface methods
################################################################################
sub new
{
	confess "Creating OpenSLX::OSExport::ExportType::Base-objects directly makes no sense!";
}

sub initialize
{
	my $self = shift;
	my $engine = shift;

	$self->{'engine'} = $engine;

	# read filter information:
	my (@includeList, @excludeList);
	my $distroName = $engine->{'distro-name'};
	my $filterFile = "../lib/distro-info/$distroName/export-filter";
	if (open(FILTER, "< $filterFile")) {
		while(<FILTER>) {
			chomp;
			push @includeList, "$_" if /^\+\s+/;
			push @excludeList, "$_" if /^\-\s+/;
		}
		close(FILTER);
	}
	$self->{'exclude-list'} = \@excludeList;
	$self->{'include-list'} = \@includeList;
}

sub exportVendorOS
{
}

1;
################################################################################

=pod

=head1 NAME

OpenSLX::OSExport::ExportType::Base - the base class for all OSExport::ExportTypes

=head1 SYNOPSIS

  package OpenSLX::OSExport::ExportType::coolnewexporter;

  use vars qw(@ISA $VERSION);
  @ISA = ('OpenSLX::OSExport::ExportType::Base');
  $VERSION = 1.01;

  use coolnewexporter;

  sub new
  {
      my $class = shift;
      my $self = {};
      return bless $self, $class;
  }

  # override all methods of OpenSLX::OSExport::ExportType::Base in order to
  # implement the support for a new export-type
  ...

I<The synopsis above outlines a class that implements a
OSExport::ExportType for the (imaginary) export-type B<coolnewexporter>>

=cut
