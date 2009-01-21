# Copyright (c) 2007 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your suggestions, praise, or complaints to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org/
# -----------------------------------------------------------------------------
# Fedora_6_x86_64.pm
# - provides Fedora-6-x86_64-specific overrides of the OpenSLX OSSetup API.
# -----------------------------------------------------------------------------
package OpenSLX::OSSetup::Distro::Fedora_6_x86_64;

use strict;
use warnings;

use base qw(OpenSLX::OSSetup::Distro::Fedora);

use OpenSLX::Basics;

################################################################################
### implementation
################################################################################
sub new
{
	my $class = shift;
	my $self = {
		'base-name' => 'fedora-6_x86_64',
	};
	return bless $self, $class;
}

sub initDistroInfo
{
	my $self = shift;
	$self->{config}->{'repository'} = {
		'base' => {
			'urls' => "
				ftp://ftp5.gwdg.de/pub/linux/fedora/linux/core/6/x86_64/os
				http://mirror.linux.duke.edu/pub/fedora/linux/core/6/x86_64/os
				ftp://www.las.ic.unicamp.br/pub/fedora/linux/core/6/x86_64/os
				ftp://sunsite.mff.cuni.cz/pub/fedora/linux/core/6/x86_64/os
				ftp://ftp.funet.fi/pub/mirrors/ftp.redhat.com/pub/fedora/linux/core/6/x86_64/os
			",
			'name' => 'Fedora Core 6',
			'repo-subdir' => '',
		},
		'base_update' => {
			'urls' => '
				ftp://ftp5.gwdg.de/pub/linux/fedora/linux/core/updates/$releasever/$basearch/
			',
			'name' => 'Fedora Core 6 updates',
			'repo-subdir' => '',
		},
	};

	$self->{config}->{'package-subdir'} = 'Fedora/RPMS';

	$self->{config}->{'prereq-packages'} = "
		beecrypt-4.1.2-10.1.1.x86_64.rpm
		bzip2-libs-1.0.3-3.x86_64.rpm
		e2fsprogs-libs-1.39-7.x86_64.rpm
		elfutils-libelf-0.123-1.fc6.x86_64.rpm
		expat-1.95.8-8.2.1.x86_64.rpm
		glibc-2.5-3.x86_64.rpm
		krb5-libs-1.5-7.x86_64.rpm
		libgcc-4.1.1-30.x86_64.rpm
		libselinux-1.30.29-2.x86_64.rpm
		libsepol-1.12.27-1.x86_64.rpm
		libstdc++-4.1.1-30.x86_64.rpm
		neon-0.25.5-5.1.x86_64.rpm
		popt-1.10.2-32.x86_64.rpm
		openssl-0.9.8b-8.x86_64.rpm
		rpm-4.4.2-32.x86_64.rpm
		rpm-libs-4.4.2-32.x86_64.rpm
		sqlite-3.3.6-2.x86_64.rpm
		zlib-1.2.3-3.x86_64.rpm
	";

	$self->{config}->{'bootstrap-prereq-packages'} = "";

	$self->{config}->{'bootstrap-packages'} = "
		audit-libs-1.2.8-1.fc6.x86_64.rpm
		basesystem-8.0-5.1.1.noarch.rpm
		bash-3.1-16.1.x86_64.rpm
		chkconfig-1.3.30-1.x86_64.rpm
		coreutils-5.97-11.x86_64.rpm
		cpio-2.6-19.x86_64.rpm
		cracklib-2.8.9-3.1.x86_64.rpm
		cracklib-dicts-2.8.9-3.1.x86_64.rpm
		db4-4.3.29-9.fc6.x86_64.rpm
		device-mapper-1.02.07-3.x86_64.rpm
		dmraid-1.0.0.rc13-1.fc6.x86_64.rpm
		e2fsprogs-1.39-7.x86_64.rpm
		ethtool-3-1.2.2.x86_64.rpm
		fedora-release-6-4.noarch.rpm
		fedora-release-notes-6-3.noarch.rpm
		filesystem-2.4.0-1.x86_64.rpm
		findutils-4.2.27-4.1.x86_64.rpm
		gawk-3.1.5-11.x86_64.rpm
		gdbm-1.8.0-26.2.1.x86_64.rpm
		glib2-2.12.3-2.fc6.x86_64.rpm
		glibc-common-2.5-3.x86_64.rpm
		grep-2.5.1-54.1.x86_64.rpm
		gzip-1.3.5-9.x86_64.rpm
		info-4.8-11.1.x86_64.rpm
		initscripts-8.45.3-1.x86_64.rpm
		iproute-2.6.16-6.fc6.x86_64.rpm
		iputils-20020927-41.fc6.x86_64.rpm
		kernel-2.6.18-1.2798.fc6.x86_64.rpm
		kpartx-0.4.7-5.x86_64.rpm
		less-394-4.1.x86_64.rpm
		libacl-2.2.39-1.1.x86_64.rpm
		libattr-2.4.32-1.1.x86_64.rpm
		libcap-1.10-25.x86_64.rpm
		libtermcap-2.0.8-46.1.x86_64.rpm
		lvm2-2.02.06-4.x86_64.rpm
		MAKEDEV-3.23-1.2.x86_64.rpm
		mcstrans-0.1.8-3.x86_64.rpm
		mingetty-1.07-5.2.2.x86_64.rpm
		mkinitrd-5.1.19-1.x86_64.rpm
		mktemp-1.5-23.2.2.x86_64.rpm
		module-init-tools-3.3-0.pre1.4.17.x86_64.rpm
		nash-5.1.19-1.x86_64.rpm
		ncurses-5.5-24.20060715.x86_64.rpm
		net-tools-1.60-73.x86_64.rpm
		pam-0.99.6.2-3.fc6.x86_64.rpm
		pcre-6.6-1.1.x86_64.rpm
		procps-3.2.7-8.x86_64.rpm
		psmisc-22.2-5.x86_64.rpm
		python-2.4.3-18.fc6.x86_64.rpm
		readline-5.1-1.1.x86_64.rpm
		sed-4.1.5-5.fc6.x86_64.rpm
		setup-2.5.55-1.noarch.rpm
		shadow-utils-4.0.17-5.x86_64.rpm
		sysklogd-1.4.1-39.2.x86_64.rpm
		SysVinit-2.86-14.x86_64.rpm
		tar-1.15.1-19.x86_64.rpm
		termcap-5.5-1.20060701.1.noarch.rpm
		tzdata-2006m-2.fc6.noarch.rpm
		udev-095-14.x86_64.rpm
		util-linux-2.13-0.44.fc6.x86_64.rpm
		libxml2-2.6.26-2.1.1.x86_64.rpm
		python-elementtree-1.2.6-5.x86_64.rpm
		python-sqlite-1.1.7-1.2.1.x86_64.rpm
		python-urlgrabber-2.9.9-2.noarch.rpm
		rpm-python-4.4.2-32.x86_64.rpm
		yum-3.0-6.noarch.rpm
		yum-metadata-parser-1.0-8.fc6.x86_64.rpm
	";

	$self->{config}->{'selection'} = {
		'default' => "",
	};
	return;
}

1;
