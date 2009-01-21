# NBD_Squash.pm
#	- provides NBD+Squashfs-specific overrides of the OpenSLX::OSExport::ExportType API.
#
# (c) 2006 - OpenSLX.com
#
# Oliver Tappe <ot@openslx.com>
#
package OpenSLX::OSExport::ExportType::NBD_Squash;

use vars qw(@ISA $VERSION);
@ISA = ('OpenSLX::OSExport::ExportType::Base');
$VERSION = 1.01;		# API-version . implementation-version

use strict;
use Carp;
use File::Basename;
use OpenSLX::Basics;
use OpenSLX::OSExport::ExportType::Base 1.01;

################################################################################
### interface methods
################################################################################
sub new
{
	my $class = shift;
	my $self = {
		'name' => 'NBD_Squash',
	};
	return bless $self, $class;
}

sub exportVendorOS
{
	my $self = shift;
	my $source = shift;
	my $target = shift;

	# TODO: once the include/exclude-patch by Vito has been applied
	#       to mksquashfs, the extra route via rsync isn't necessary anymore:
	my $mksquashfsCanFilter = 0;
	if ($mksquashfsCanFilter) {
		# do filtering as part of mksquashfs (needs additional mapping of
		# our internal (rsync-)filter format to regexes):
		my $includeExcludeList = $self->determineIncludeExcludeList();
		vlog 1, _tr("using include-exclude-filter:\n%s\n", $includeExcludeList);
		$self->createSquashFS($source, $target, $includeExcludeList);
	} else {
		# do filtering via an rsync copy:
		vlog 0, _tr("taking detour via rsync...");
		my $tmpTarget = "${target}_###RSYNC_TMP###";
		$self->copyViaRsync($source, $tmpTarget);
		$self->createSquashFS($tmpTarget, $target);
#		system("rm -r $tmpTarget");
	}
	$self->showNbdParams($target);
}

################################################################################
### implementation methods
################################################################################

sub createSquashFS
{
	my $self = shift;
	my $source = shift;
	my $target = shift;
	my $includeExcludeList = shift;

	system("rm -rf $target");
		# mksquasfs isn't significantly faster if fs already exists, but it
		# causes the filesystem to grow somewhat, so we remove it in order to
		# get the smallest FS-file possible.
	if (system("mksquashfs $source $target -info")) {
		die _tr("unable to create squashfs for source '%s into target '%s', giving up! (%s)",
				$source, $target, $!);
	}
}

sub showNbdParams
{
	my $self = shift;
	my $target = shift;

	print (('#' x 80)."\n");
	print _tr("Please make sure you start a corresponding nbd-server:\n\t%s\n",
			  "nbd-server -r $self->{engine}->{'export-path'}");
	print (('#' x 80)."\n");
}

1;
