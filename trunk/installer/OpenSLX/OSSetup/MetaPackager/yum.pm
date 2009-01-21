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
	system("cp /proc/cpuinfo $self->{engine}->{'vendor-os-path'}/proc");
	system("rm -f $self->{engine}->{'vendor-os-path'}/etc/yum.repos.d/*");
	system("mkdir -p $self->{engine}->{'vendor-os-path'}/etc/yum.repos.d");
	my $repoFile
		= "$self->{engine}->{'vendor-os-path'}/etc/yum.repos.d/$repoName.repo";
	open(REPO, "> $repoFile")
		or die _tr("unable to create repo-file <%s> (%s)", $repoFile, $1);
	print REPO $repoDescr;
	close(REPO);
}

sub updateBasicSystem
{
	my $self = shift;

	if (system("yum -y update")) {
		die _tr("unable to update basic system (%s)", $!);
	}
}

sub installSelection
{
	my $self = shift;
	my $pkgSelection = shift;

	if (system("yum -y install $pkgSelection")) {
		die _tr("unable to install selection (%s)", $!);
	}
	system('rm /proc/cpuinfo');
}

1;