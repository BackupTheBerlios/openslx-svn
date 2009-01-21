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
# SUSE_10_2.pm
#	- provides SUSE-10.2-specific overrides of the OpenSLX OSSetup API.
# -----------------------------------------------------------------------------
package OpenSLX::OSSetup::Distro::SUSE_10_2;

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
		'base-name' => 'suse-10.2',
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
				ftp://ftp.gwdg.de/pub/opensuse/distribution/10.2/repo/oss
				ftp://suse.inode.at/opensuse/distribution/10.2/repo/oss
				http://mirrors.uol.com.br/pub/suse/distribution/10.2/repo/oss
				ftp://klid.dk/opensuse/distribution/10.2/repo/oss
				ftp://ftp.estpak.ee/pub/suse/opensuse/distribution/10.2/repo/oss
				ftp://ftp.jaist.ac.jp/pub/Linux/openSUSE/distribution/10.2/repo/oss
			",
			'name' => 'openSUSE 10.2',
			'repo-subdir' => 'suse',
		},
		'base_update' => {
			'urls' => "
				ftp://ftp.gwdg.de/pub/suse/update/10.2
			",
			'name' => 'openSUSE 10.2 updates',
			'repo-subdir' => '',
		},
	};

	$self->{config}->{'package-subdir'} = 'suse';

	$self->{config}->{'prereq-packages'} = "
		i586/bzip2-1.0.3-36.i586.rpm
		i586/glibc-2.5-25.i586.rpm
		i586/popt-1.7-304.i586.rpm
		i586/rpm-4.4.2-76.i586.rpm
		i586/zlib-1.2.3-33.i586.rpm
	";

	$self->{config}->{'bootstrap-prereq-packages'} = "";

	$self->{config}->{'bootstrap-packages'} = "
		i586/aaa_base-10.2-38.i586.rpm
		i586/aaa_skel-2006.5.19-20.i586.rpm
		i586/audit-libs-1.2.6-20.i586.rpm
		i586/bash-3.1-55.i586.rpm
		i586/blocxx-1.0.0-36.i586.rpm
		i586/coreutils-6.4-10.i586.rpm
		i586/cpio-2.6-40.i586.rpm
		i586/cracklib-2.8.9-20.i586.rpm
		i586/cyrus-sasl-2.1.22-28.i586.rpm
		i586/db-4.4.20-16.i586.rpm
		i586/diffutils-2.8.7-38.i586.rpm
		i586/e2fsprogs-1.39-21.i586.rpm
		i586/file-4.17-23.i586.rpm
		i586/filesystem-10.2-22.i586.rpm
		i586/fillup-1.42-138.i586.rpm
		i586/findutils-4.2.28-24.i586.rpm
		i586/gawk-3.1.5-41.i586.rpm
		i586/gdbm-1.8.3-261.i586.rpm
		i586/gpg-1.4.5-24.i586.rpm
		i586/grep-2.5.1a-40.i586.rpm
		i586/gzip-1.3.5-178.i586.rpm
		i586/info-4.8-43.i586.rpm
		i586/insserv-1.04.0-42.i586.rpm
		i586/irqbalance-0.09-80.i586.rpm
		i586/kernel-default-2.6.18.2-34.i586.rpm
		i586/libacl-2.2.34-33.i586.rpm
		i586/libattr-2.4.28-38.i586.rpm
		i586/libcom_err-1.39-21.i586.rpm
		i586/libgcc41-4.1.2_20061115-5.i586.rpm
		i586/libstdc++41-4.1.2_20061115-5.i586.rpm
		i586/libvolume_id-103-12.i586.rpm
		i586/libxcrypt-2.4-30.i586.rpm
		i586/libzio-0.2-20.i586.rpm
		i586/limal-1.2.9-5.i586.rpm
		i586/limal-bootloader-1.2.4-6.i586.rpm
		i586/limal-perl-1.2.9-5.i586.rpm
		i586/logrotate-3.7.4-21.i586.rpm
		i586/mdadm-2.5.3-17.i586.rpm
		i586/mingetty-0.9.6s-107.i586.rpm
		i586/mkinitrd-1.2-149.i586.rpm
		i586/mktemp-1.5-763.i586.rpm
		i586/module-init-tools-3.2.2-62.i586.rpm
		i586/ncurses-5.5-42.i586.rpm
		i586/net-tools-1.60-606.i586.rpm
		i586/openldap2-client-2.3.27-25.i586.rpm
		i586/openssl-0.9.8d-17.i586.rpm
		i586/openSUSE-release-10.2-35.i586.rpm
		i586/pam-0.99.6.3-24.i586.rpm
		i586/pciutils-2.2.4-13.i586.rpm
		i586/pcre-6.7-21.i586.rpm
		i586/perl-5.8.8-32.i586.rpm
		i586/perl-Bootloader-0.4.5-3.i586.rpm
		i586/perl-gettext-1.05-31.i586.rpm
		i586/permissions-2006.11.13-5.i586.rpm
		i586/readline-5.1-55.i586.rpm
		i586/reiserfs-3.6.19-37.i586.rpm
		i586/sed-4.1.5-21.i586.rpm
		i586/sysvinit-2.86-47.i586.rpm
		i586/udev-103-12.i586.rpm
		i586/util-linux-2.12r-61.i586.rpm
		noarch/pciutils-ids-2006.11.18-2.noarch.rpm
		noarch/suse-build-key-1.0-707.noarch.rpm
		i586/glib2-2.12.4-15.i586.rpm
		i586/gnome-filesystem-0.1-288.i586.rpm
		i586/libxml2-2.6.26-26.i586.rpm
		i586/libxml2-python-2.6.26-29.i586.rpm
		i586/rpm-python-4.4.2-76.i586.rpm
		i586/python-2.5-19.i586.rpm
		i586/python-sqlite-1.1.8-11.i586.rpm
		i586/python-urlgrabber-3.1.0-18.i586.rpm
		i586/python-xml-2.5-19.i586.rpm
		i586/sqlite-3.3.8-14.i586.rpm
		i586/yum-3.0.1-9.i586.rpm
		i586/yum-metadata-parser-1.0.2-23.i586.rpm
	";

	$self->{config}->{'selection'} = {
		'default' => "",
	}
}

1;