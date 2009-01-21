# NFS.pm
#	- provides NFS-specific overrides of the OpenSLX::OSExport::ExportType API.
#
# (c) 2006 - OpenSLX.com
#
# Oliver Tappe <ot@openslx.com>
#
package OpenSLX::OSExport::ExportType::NFS;

use vars qw(@ISA $VERSION);
@ISA = ('OpenSLX::OSExport::ExportType::Base');
$VERSION = 1.01;		# API-version . implementation-version

use strict;
use Carp;
use File::Basename;
use OpenSLX::Basics;
use OpenSLX::Utils;
use OpenSLX::OSExport::ExportType::Base 1.01;

################################################################################
### interface methods
################################################################################
sub new
{
	my $class = shift;
	my $self = {
		'name' => 'NFS',
	};
	return bless $self, $class;
}

sub initialize
{
	my $self = shift;
	my $engine = shift;

	$self->SUPER::initialize($engine);
}

sub exportVendorOS
{
	my $self = shift;
	my $source = shift;
	my $target = shift;

	$self->exportViaRsync($source, $target);
	$self->addTargetToNfsExports($target);
}

################################################################################
### implementation methods
################################################################################

sub exportViaRsync
{
	my $self = shift;
	my $source = shift;
	my $target = shift;

	my $includeExcludeList = $self->determineIncludeExcludeList();
	vlog 1, "using include-exclude-filter:\n$includeExcludeList\n";
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

	# Rsync uses a best (longest) match strategy. If there is more than one
	# match with the same length, the first wins. This means that we have
	# to mix the local specifications in front of the filterset given by
	# the package (as the local filters should always overrule the vendor
	# filters):
	my $distroName = $self->{engine}->{'distro-name'};
	my $localFilterFile = "../lib/distro-info/$distroName/export-filter.local";
	my $includeExcludeList = slurpFile($localFilterFile, 1);
	$includeExcludeList .= $self->{engine}->{distro}->{'export-filter'};
	$includeExcludeList =~ s[^\s+][]igms;
		# remove any leading whitespace, as rsync doesn't like it
	return $includeExcludeList;
}

sub addTargetToNfsExports
{
	my $self = shift;
	my $target = shift;

	my $exports = slurpFile("/etc/exports");
print "$exports\n";
}

1;