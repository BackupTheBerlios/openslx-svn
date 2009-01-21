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

use OpenSLX::Basics;
use OpenSLX::Utils;

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
}

sub exportVendorOS
{
}

################################################################################
### implementation methods
################################################################################
sub copyViaRsync
{
	my $self = shift;
	my $source = shift;
	my $target = shift;

	if (system("mkdir -p $target")) {
		die _tr("unable to create directory '%s', giving up! (%s)\n",
				$target, $!);
	}
	my $includeExcludeList = $self->determineIncludeExcludeList();
	vlog 1, _tr("using include-exclude-filter:\n%s\n", $includeExcludeList);
	open(RSYNC, "| rsync -av --delete --exclude-from=- $source/ $target")
		or die _tr("unable to start rsync for source '%s', giving up! (%s)",
				   $source, $!);
	print RSYNC $includeExcludeList;
	if (!close(RSYNC)) {
		die _tr("unable to export to target '%s', giving up! (%s)",
				$target, $!);
	}
}

sub determineIncludeExcludeList
{
	my $self = shift;

	# Rsync uses a first match strategy, so we mix the local specifications
	# in front of the filterset given by the package (as the local filters
	# should always overrule the vendor filters):
	my $distroName = $self->{engine}->{'distro-name'};
	my $localFilterFile = "../lib/distro-info/$distroName/export-filter.local";
	my $includeExcludeList = slurpFile($localFilterFile, 1);
	$includeExcludeList .= $self->{engine}->{distro}->{'export-filter'};
	$includeExcludeList =~ s[^\s+][]igms;
		# remove any leading whitespace, as rsync doesn't like it
	return $includeExcludeList;
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
