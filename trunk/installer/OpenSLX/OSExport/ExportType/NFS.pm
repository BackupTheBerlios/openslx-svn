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

	my $excludeIncludeList
		= join("\n", @{$self->{'include-list'}}, @{$self->{'exclude-list'}});
	vlog 1, "using exclude-include-filter:\n$excludeIncludeList\n";
	open(RSYNC, "| rsync -av --delete --exclude-from=- $source/ $target")
		or die _tr("unable to start rsync for source '%s', giving up! (%s)",
				   $source, $!);
	print RSYNC $excludeIncludeList;
	if (!close(RSYNC)) {
		die _tr("unable to export to target '%s', giving up! (%s)",
				$target, $!);
	}
}

sub addTargetToNfsExports
{
	my $self = shift;
	my $target = shift;

	my $exports = slurpFile("/etc/exports");
print "$exports\n";
}

1;
