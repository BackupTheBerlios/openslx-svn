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

sub exportVendorOS
{
	my $self = shift;
	my $source = shift;
	my $target = shift;

	$self->copyViaRsync($source, $target);
	$self->addTargetToNfsExports($target);
}

################################################################################
### implementation methods
################################################################################
sub addTargetToNfsExports
{
	my $self = shift;
	my $target = shift;

	print (('#' x 80)."\n");
	print _tr("Please make sure the following line is contained in /etc/exports\nin order to activate the NFS-export of this vendor-OS:\n\t%s\n",
			  "$self->{engine}->{'export-path'}\t*(ro,root_squash,async,no_subtree_check)");
	print (('#' x 80)."\n");

# TODO : add something a bit more clever here...
#	my $exports = slurpFile("/etc/exports");
}

1;
