# SUSE_10_2.pm
#	- provides SUSE-10.1-specific overrides of the OpenSLX OSSetup API.
#
# (c) 2006 - OpenSLX.com
#
# Oliver Tappe <ot@openslx.com>
#
package OpenSLX::OSSetup::Distro::SUSE_10_1;

use vars qw(@ISA $VERSION);
@ISA = ('OpenSLX::OSSetup::Distro::Base');
$VERSION = 1.01;		# API-version . implementation-version

use strict;
use Carp;
use OpenSLX::Basics;
use OpenSLX::OSSetup::Distro::Base 1.01;

################################################################################
### implementation
################################################################################
sub new
{
	my $class = shift;
	my $self = {
		'base-name' => 'suse-10.1',
	};
	return bless $self, $class;
}

sub initialize
{
	my $self = shift;
	my $engine = shift;

	$self->SUPER::initialize($engine);
	$self->{'packager-type'} = 'rpm';
	$self->{'meta-packager-type'} = $ENV{SLX_META_PACKAGER} || 'yum';
	$ENV{YAST_IS_RUNNING} = "instsys";
}

sub fixPrerequiredFiles
{
	my $self = shift;
	my $stage1cDir = shift;

	if (system("chown root: $stage1cDir/etc/{group,passwd,shadow}")) {
		die _tr("unable to fix pre-required files (%s)", $!);
	}
}

sub initDistroInfo
{
	my $self = shift;
	$self->{config}->{'repository'} = {
		'base' => {
			'urls' => "
				http://ftp.gwdg.de/pub/opensuse/distribution/SL-10.1/inst-source
				ftp://suse.inode.at/opensuse/distribution/SL-10.1/inst-source
				http://mirrors.uol.com.br/pub/suse/distribution/SL-10.1/inst-source
				ftp://klid.dk/opensuse/distribution/SL-10.1/inst-source
				ftp://ftp.estpak.ee/pub/suse/opensuse/distribution/SL-10.1/inst-source
				ftp://ftp.jaist.ac.jp/pub/Linux/openSUSE/distribution/SL-10.1/inst-source
			",
			'name' => 'SUSE Linux 10.1',
			'repo-subdir' => 'suse',
		},
		'base_update' => {
			'urls' => "
				http://ftp.gwdg.de/pub/suse/update/10.1
			",
			'name' => 'SUSE Linux 10.1 updates',
			'repo-subdir' => '',
		},
	};

	$self->{config}->{'package-subdir'} = 'suse';

	$self->{config}->{'prereq-packages'} = "
		i586/bzip2-1.0.3-15.i586.rpm
		i586/glibc-2.4-25.i586.rpm i586/glibc-2.4-31.1.i586.rpm
		i586/popt-1.7-268.i586.rpm
		i586/rpm-4.4.2-40.i586.rpm i586/rpm-4.4.2-43.4.i586.rpm
		i586/zlib-1.2.3-13.i586.rpm
	";

	$self->{config}->{'bootstrap-prereq-packages'} = "";

	$self->{config}->{'bootstrap-packages'} = "
		i586/aaa_base-10.1-41.i586.rpm
		i586/aaa_skel-2006.3.29-5.i586.rpm i586/aaa_skel-2006.5.19-0.2.i586.rpm
		i586/ash-1.6.1-13.i586.rpm
		i586/bash-3.1-22.i586.rpm i586/bash-3.1-24.3.i586.rpm
		i586/blocxx-1.0.0-15.i586.rpm
		i586/coreutils-5.93-20.i586.rpm
		i586/cpio-2.6-17.i586.rpm
		i586/cracklib-2.8.6-12.i586.rpm
		i586/cyrus-sasl-2.1.21-18.i586.rpm
		i586/db-4.3.29-13.i586.rpm
		i586/diffutils-2.8.7-15.i586.rpm
		i586/e2fsprogs-1.38-25.i586.rpm
		i586/expat-2.0.0-11.i586.rpm
		i586/file-4.16-13.i586.rpm i586/file-4.16-15.4.i586.rpm
		i586/filesystem-10.1-5.i586.rpm
		i586/fillup-1.42-116.i586.rpm
		i586/findutils-4.2.27-12.i586.rpm
		i586/gawk-3.1.5-18.i586.rpm
		i586/gdbm-1.8.3-241.i586.rpm
		i586/gpg-1.4.2-23.i586.rpm i586/gpg-1.4.2-23.7.i586.rpm
		i586/grep-2.5.1a-18.i586.rpm
		i586/gzip-1.3.5-157.i586.rpm i586/gzip-1.3.5-159.5.i586.rpm
		i586/info-4.8-20.i586.rpm
		i586/insserv-1.04.0-18.i586.rpm
		i586/irqbalance-0.09-58.i586.rpm
		i586/kernel-default-2.6.16.21-0.25.i586.rpm
		i586/libacl-2.2.34-12.i586.rpm
		i586/libattr-2.4.28-14.i586.rpm
		i586/libcom_err-1.38-25.i586.rpm
		i586/libgcc-4.1.0-25.i586.rpm
		i586/libstdc++-4.1.0-25.i586.rpm
		i586/libxcrypt-2.4-10.i586.rpm
		i586/libzio-0.1-15.i586.rpm
		i586/limal-1.1.6-8.i586.rpm
		i586/limal-bootloader-1.1.2-7.i586.rpm
		i586/limal-perl-1.1.6-8.i586.rpm
		i586/logrotate-3.7.3-11.i586.rpm
		i586/mdadm-2.2-30.i586.rpm
		i586/mingetty-0.9.6s-86.i586.rpm
		i586/mkinitrd-1.2-103.i586.rpm i586/mkinitrd-1.2-106.19.i586.rpm
		i586/mktemp-1.5-742.i586.rpm
		i586/module-init-tools-3.2.2-32.i586.rpm i586/module-init-tools-3.2.2-32.13.i586.rpm
		i586/ncurses-5.5-16.i586.rpm
		i586/net-tools-1.60-581.i586.rpm
		i586/openldap2-client-2.3.19-18.i586.rpm
		i586/openssl-0.9.8a-16.i586.rpm i586/openssl-0.9.8a-18.10.i586.rpm
		i586/pam-0.99.3.0-25.i586.rpm i586/pam-0.99.3.0-29.3.i586.rpm
		i586/pciutils-2.2.1-14.i586.rpm
		i586/pcre-6.4-12.i586.rpm
		i586/perl-5.8.8-12.i586.rpm
		i586/perl-Bootloader-0.2.20-7.i586.rpm i586/perl-Bootloader-0.2.27-0.4.i586.rpm
		i586/perl-gettext-1.05-11.i586.rpm
		i586/permissions-2006.2.24-8.i586.rpm
		i586/readline-5.1-22.i586.rpm
		i586/reiserfs-3.6.19-17.i586.rpm
		i586/sed-4.1.4-15.i586.rpm
		i586/suse-release-10.1-9.i586.rpm
		i586/sysvinit-2.86-19.i586.rpm
		i586/udev-085-29.i586.rpm i586/udev-085-30.15.i586.rpm
		i586/util-linux-2.12r-35.i586.rpm
		noarch/suse-build-key-1.0-685.noarch.rpm
		i586/libxml2-2.6.23-13.i586.rpm
		i586/libxml2-python-2.6.23-15.i586.rpm
		i586/python-2.4.2-18.i586.rpm
		i586/python-elementtree-1.2.6-18.i586.rpm
		i586/python-sqlite-1.1.6-17.i586.rpm
		i586/python-urlgrabber-2.9.7-15.i586.rpm
		i586/rpm-python-4.4.2-40.i586.rpm
		i586/sqlite-3.2.8-14.i586.rpm
		i586/yum-2.4.2-13.i586.rpm
	";

	$self->{config}->{'selection'} = {
		'default' => "",
	}
}

1;