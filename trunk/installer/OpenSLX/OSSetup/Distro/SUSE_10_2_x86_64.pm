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
# SUSE_10_2_x86_64.pm
#	- provides SUSE-10.2-x86_64-specific overrides of the OpenSLX OSSetup API.
# -----------------------------------------------------------------------------
package OpenSLX::OSSetup::Distro::SUSE_10_2_x86_64;

use strict;
use warnings;

use base qw(OpenSLX::OSSetup::Distro::Base);

use OpenSLX::Basics;

################################################################################
### implementation
################################################################################
sub new
{
	my $class = shift;
	my $self = {
		'base-name' => 'suse-10.2_x86_64',
	};
	return bless $self, $class;
}

sub initialize
{
	my $self = shift;
	my $engine = shift;

	$self->SUPER::initialize($engine);
	$self->{'packager-type'} = 'rpm';
	$self->{'meta-packager-type'} = $ENV{SLX_META_PACKAGER} || 'smart';
	$ENV{YAST_IS_RUNNING} = "instsys";
	return;
}

sub fixPrerequiredFiles
{
	my $self = shift;
	my $stage1cDir = shift;

	chown(0, 0, "$stage1cDir/etc/group", "$stage1cDir/etc/passwd",
		"$stage1cDir/etc/shadow");    
	return;
}

sub updateDistroConfig
{
	my $self = shift;

	# make sure there's a /dev/zero, as SuSEconfig requires it:
	if (!-e "/dev/zero" && slxsystem("mknod /dev/zero c 1 5")) {
		die _tr("unable to create node '%s' (%s)\n", "/dev/zero", $!);
	}
	# invoke SuSEconfig in order to allow it to update the configuration:
	if (slxsystem("SuSEconfig")) {
		die _tr("unable to run SuSEconfig (%s)", $!);
	}
	$self->SUPER::updateDistroConfig();
	return;
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
		'base_non-oss' => {
			'urls' => "
				ftp://ftp5.gwdg.de/pub/opensuse/distribution/10.2/repo/non-oss
				ftp://suse.inode.at/opensuse/distribution/10.2/repo/non-oss
				http://mirrors.uol.com.br/pub/suse/distribution/10.2/repo/non-oss
				ftp://klid.dk/opensuse/distribution/10.2/repo/non-oss
				ftp://ftp.estpak.ee/pub/suse/opensuse/distribution/10.2/repo/non-oss
				ftp://ftp.jaist.ac.jp/pub/Linux/openSUSE/distribution/10.2/repo/non-oss
			",
			'name' => 'openSUSE 10.2 non-OSS',
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
		x86_64/bzip2-1.0.3-36.x86_64.rpm
		x86_64/glibc-2.5-25.x86_64.rpm
		x86_64/popt-1.7-304.x86_64.rpm
		x86_64/rpm-4.4.2-76.x86_64.rpm
		x86_64/zlib-1.2.3-33.x86_64.rpm
	";

	$self->{config}->{'bootstrap-prereq-packages'} = "";

	$self->{config}->{'bootstrap-packages'} = "
		x86_64/aaa_base-10.2-38.x86_64.rpm
		x86_64/aaa_skel-2006.5.19-20.x86_64.rpm
		x86_64/audit-libs-1.2.6-20.x86_64.rpm
		x86_64/bash-3.1-55.x86_64.rpm
		x86_64/blocxx-1.0.0-36.x86_64.rpm
		x86_64/coreutils-6.4-10.x86_64.rpm
		x86_64/cpio-2.6-40.x86_64.rpm
		x86_64/cracklib-2.8.9-20.x86_64.rpm
		x86_64/cyrus-sasl-2.1.22-28.x86_64.rpm
		x86_64/db-4.4.20-16.x86_64.rpm
		x86_64/diffutils-2.8.7-38.x86_64.rpm
		x86_64/e2fsprogs-1.39-21.x86_64.rpm
		x86_64/file-4.17-23.x86_64.rpm
		x86_64/filesystem-10.2-22.x86_64.rpm
		x86_64/fillup-1.42-138.x86_64.rpm
		x86_64/findutils-4.2.28-24.x86_64.rpm
		x86_64/gawk-3.1.5-41.x86_64.rpm
		x86_64/gdbm-1.8.3-261.x86_64.rpm
		x86_64/glibc-32bit-2.5-25.x86_64.rpm
		x86_64/gpg-1.4.5-24.x86_64.rpm
		x86_64/grep-2.5.1a-40.x86_64.rpm
		x86_64/gzip-1.3.5-178.x86_64.rpm
		x86_64/info-4.8-43.x86_64.rpm
		x86_64/insserv-1.04.0-42.x86_64.rpm
		x86_64/irqbalance-0.09-80.x86_64.rpm
		x86_64/kernel-default-2.6.18.2-34.x86_64.rpm
		x86_64/libacl-2.2.34-33.x86_64.rpm
		x86_64/libattr-2.4.28-38.x86_64.rpm
		x86_64/libcom_err-1.39-21.x86_64.rpm
		x86_64/libgcc41-4.1.2_20061115-5.x86_64.rpm
		x86_64/libstdc++41-4.1.2_20061115-5.x86_64.rpm
		x86_64/libvolume_id-103-12.x86_64.rpm
		x86_64/libxcrypt-2.4-30.x86_64.rpm
		x86_64/libzio-0.2-20.x86_64.rpm
		x86_64/limal-1.2.9-5.x86_64.rpm
		x86_64/limal-bootloader-1.2.4-6.x86_64.rpm
		x86_64/limal-perl-1.2.9-5.x86_64.rpm
		x86_64/logrotate-3.7.4-21.x86_64.rpm
		x86_64/mdadm-2.5.3-17.x86_64.rpm
		x86_64/mingetty-0.9.6s-107.x86_64.rpm
		x86_64/mkinitrd-1.2-149.x86_64.rpm
		x86_64/mktemp-1.5-763.x86_64.rpm
		x86_64/module-init-tools-3.2.2-62.x86_64.rpm
		x86_64/ncurses-5.5-42.x86_64.rpm
		x86_64/net-tools-1.60-606.x86_64.rpm
		x86_64/openldap2-client-2.3.27-25.x86_64.rpm
		x86_64/openssl-0.9.8d-17.x86_64.rpm
		x86_64/openSUSE-release-10.2-35.x86_64.rpm
		x86_64/pam-0.99.6.3-24.x86_64.rpm
		x86_64/pciutils-2.2.4-13.x86_64.rpm
		x86_64/pcre-6.7-21.x86_64.rpm
		x86_64/perl-5.8.8-32.x86_64.rpm
		x86_64/perl-Bootloader-0.4.5-3.x86_64.rpm
		x86_64/perl-gettext-1.05-31.x86_64.rpm
		x86_64/permissions-2006.11.13-5.x86_64.rpm
		x86_64/readline-5.1-55.x86_64.rpm
		x86_64/reiserfs-3.6.19-37.x86_64.rpm
		x86_64/sed-4.1.5-21.x86_64.rpm
		x86_64/sysvinit-2.86-47.x86_64.rpm
		x86_64/udev-103-12.x86_64.rpm
		x86_64/util-linux-2.12r-61.x86_64.rpm
		noarch/pciutils-ids-2006.11.18-2.noarch.rpm
		noarch/suse-build-key-1.0-707.noarch.rpm
	";

	$self->{config}->{'metapackager-packages'} = {
		'smart' => "
			x86_64/python-2.5-19.x86_64.rpm
			x86_64/python-xml-2.5-19.x86_64.rpm
			x86_64/rpm-python-4.4.2-76.x86_64.rpm
			x86_64/smart-0.42-43.x86_64.rpm
		",
		'yum' => "
			x86_64/glib2-2.12.4-15.x86_64.rpm
			x86_64/gnome-filesystem-0.1-288.x86_64.rpm
			x86_64/libxml2-2.6.26-26.x86_64.rpm
			x86_64/libxml2-python-2.6.26-29.x86_64.rpm
			x86_64/python-2.5-19.x86_64.rpm
			x86_64/python-sqlite-1.1.8-11.x86_64.rpm
			x86_64/python-urlgrabber-3.1.0-18.x86_64.rpm
			x86_64/python-xml-2.5-19.x86_64.rpm
			x86_64/rpm-python-4.4.2-76.x86_64.rpm
			x86_64/sqlite-3.3.8-14.x86_64.rpm
			x86_64/yum-3.0.1-9.x86_64.rpm
			x86_64/yum-metadata-parser-1.0.2-23.x86_64.rpm
		",
	};

	$self->{config}->{'selection'} = {
		'default' => "
			acl
			acpid
			apparmor-docs
			apparmor-profiles
			apparmor-utils
			ash
			at
			atk
			attr
			audit
			autofs
			autoyast2
			bc
			bind-libs
			bind-utils
			boost
			bootsplash-theme-SuSE
			compat
			compat-libstdc++
			compat-openssl097g
			cpufrequtils
			cron
			cups-client
			cyrus-sasl
			cyrus-sasl-saslauthd
			db-utils
			deltarpm
			dhcpcd
			dmraid
			dos2unix
			dosfstools
			ed
			eject
			ethtool
			fbset
			findutils
			fontconfig
			freetype2
			gdb
			gdbm
			glib2
			glibc-i18ndata
			gpg-pubkey
			gpg-pubkey
			gpg-pubkey
			gpg-pubkey
			gpg-pubkey
			gpg-pubkey
			gpm
			hal-resmgr
			hfsutils
			ifplugd
			initviocons
			inst-source-utils
			iputils
			joe
			kbd
			kernel-default
			krb5
			ksh
			ksymoops
			libacl
			libapparmor
			libart_lgpl
			libattr
			libcap
			libcom_err
			libdrm
			libevent
			libgcc41
			libgcrypt
			libgimpprint
			libgpg-error
			libicu
			libidn
			libjpeg
			liblazy
			liblcms
			libltdl
			libmng
			libnscd
			libopencdk
			libpcap
			libpng
			librpcsecgss
			libstdc++41
			libtiff
			libusb
			libvolume_id
			libxcrypt
			lukemftp
			lvm2
			lzo
			mailx
			man
			man-pages
			microcode_ctl
			module-init-tools
			multipath-tools
			nbd
			ncurses
			net-snmp
			nfs-utils
			nfsidmap
			nscd
			ntfsprogs
			openSUSE-release
			openct
			opensc
			openssh
			openssl
			patch
			pax
			perl-Crypt-SmbHash
			perl-URI
			perl-XML-Parser
			perl-XML-Writer
			postfix
			powersave-libs
			preload
			procinfo
			procmail
			procps
			providers
			qlogic-firmware
			recode
			rrdtool
			rsync
			sash
			screen
			scsi
			sensors
			sharutils
			smart
			smartmontools
			smpppd
			squashfs-kmp-default
			strace
			sudo
			suse-build-key
			suspend
			sysfsutils
			syslog-ng
			tcpd
			tcpdump
			tcsh
			telnet
			terminfo
			timezone
			ulimit
			usbutils
			utempter
			vim
			wdiff
			wget
			wvstreams
			xfsprogs
			xinetd
			xntp
			yast2-apparmor
			yast2-backup
			yast2-bluetooth
			yast2-bootfloppy
			yast2-irda
			yast2-iscsi-client
			yast2-mail
			yast2-ncurses
			yast2-nis-client
			yast2-ntp-client
			yast2-online-update-frontend
			yast2-power-management
			yast2-powertweak
			yast2-profile-manager
			yast2-repair
			yast2-restore
			yast2-runlevel
			yast2-samba-client
			yast2-scanner
			yast2-sudo
			yast2-support
			yast2-theme-openSUSE
			yast2-trans-de
			yast2-tv
			ypbind
			zip
			zisofs-tools
			zsh
		",
	};
	return;
}

1;