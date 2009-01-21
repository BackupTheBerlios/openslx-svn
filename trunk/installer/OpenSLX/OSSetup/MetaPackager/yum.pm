# yum.pm
#	- provides yum-specific overrides of the OpenSLX::OSSetup::MetaPackager API.
#
# (c) 2006 - OpenSLX.com
#
# Oliver Tappe <ot@openslx.com>
#
package OpenSLX::OSSetup::MetaPackager::yum;

use vars qw(@ISA $VERSION);
@ISA = ('OpenSLX::OSSetup::MetaPackager::Base');
$VERSION = 1.01;		# API-version . implementation-version

use strict;
use Carp;
use OpenSLX::Basics;
use OpenSLX::OSSetup::MetaPackager::Base 1.01;

################################################################################
### implementation
################################################################################
sub new
{
	my $class = shift;
	my $self = {
		'name' => 'yum',
	};
	return bless $self, $class;
}

sub initialize
{
	my $self = shift;
	my $engine = shift;

	$self->SUPER::initialize($engine);
	$ENV{LC_ALL} = 'POSIX';
}

sub setupPackageSource
{
	my $self = shift;
	my $repoName = shift;
	my $repoInfo = shift;

	my $repoURL = $self->{engine}->selectBaseURL($repoInfo);
	if (length($repoInfo->{'repo-subdir'})) {
		$repoURL .= "/$repoInfo->{'repo-subdir'}";
	}
	my $repoDescr = "[$repoName]\nname=$repoInfo->{name}\nbaseurl=$repoURL\n";
	slxsystem("cp /proc/cpuinfo $self->{engine}->{'vendor-os-path'}/proc");
	slxsystem("rm -f $self->{engine}->{'vendor-os-path'}/etc/yum.repos.d/*");
	slxsystem("mkdir -p $self->{engine}->{'vendor-os-path'}/etc/yum.repos.d");
	my $repoFile
		= "$self->{engine}->{'vendor-os-path'}/etc/yum.repos.d/$repoName.repo";
	open(REPO, "> $repoFile")
		or die _tr("unable to create repo-file <%s> (%s)\n", $repoFile, $1);
	print REPO $repoDescr;
	close(REPO);
}

sub updateBasicVendorOS
{
	my $self = shift;

	if (slxsystem("yum -y update")) {
		if ($! == 2) {
			# file not found => yum isn't installed
			die _tr("unable to update this vendor-os, as it seems to lack an installation of yum!\n");
		}
		die _tr("unable to update this vendor-os (%s)\n", $!);
	}
}

sub installSelection
{
	my $self = shift;
	my $pkgSelection = shift;

	if (slxsystem("yum -y install $pkgSelection")) {
		die _tr("unable to install selection (%s)\n", $!);
	}
	slxsystem('rm /proc/cpuinfo');
}

1;