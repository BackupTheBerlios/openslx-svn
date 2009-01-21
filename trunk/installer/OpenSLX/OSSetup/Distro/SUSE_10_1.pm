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
		'default' => "
			AdobeICCProfiles
			BEAJava2-JRE
			MozillaFirefox
			MozillaFirefox-translations
			NX
			NetworkManager
			NetworkManager-kde
			OpenEXR
			OpenEXR-32bit
			OpenOffice_org
			OpenOffice_org-Quickstarter
			OpenOffice_org-kde
			RealPlayer
			aalib
			aalib-32bit
			acroread
			amarok
			amarok-helix
			amarok-libvisual
			apparmor-docs
			apparmor-parser
			apparmor-profiles
			apparmor-utils
			aspell
			aspell-32bit
			aspell-en
			atk
			atk-32bit
			audit
			audit-libs
			beagle-firefox
			beagle-index
			cairo
			cairo-32bit
			cdparanoia
			cdparanoia-32bit
			crafty
			cyrus-sasl-crammd5
			cyrus-sasl-digestmd5
			cyrus-sasl-plain
			dejavu
			desktop-data-SuSE
			desktop-file-utils
			dhcdbd
			dhcp-client
			digikam
			digikam-doc
			digikamimageplugins
			dirmngr
			dragonegg
			dvd+rw-tools
			efont-unicode
			enscript
			fam
			fam-32bit
			fam-server
			flac
			flac-32bit
			flash-player
			gconf2
			gconf2-32bit
			ghostscript-library
			gimp
			gimp-cmyk
			glitz
			glitz-32bit
			gnome-mime-data
			gnome-vfs2
			gnome-vfs2-32bit
			gnutls
			gnutls-32bit
			goom2k4
			gpgme
			gtk-qt-engine
			gtk-qt-engine-32bit
			gtk2
			gtk2-32bit
			gwenview
			htdig
			imlib2
			imlib2-loaders
			jack
			jack-32bit
			java-1_4_2-sun
			java-1_4_2-sun-plugin
			jpackage-utils
			k3b
			kaffeine
			kdeaddons3-kate
			kdeaddons3-kicker
			kdeaddons3-konqueror
			kdeartwork3-kscreensaver
			kdeartwork3-sound
			kdeartwork3-xscreensaver
			kdebase3
			kdebase3-32bit
			kdebase3-SuSE
			kdebase3-kdm
			kdebase3-ksysguardd
			kdebase3-nsplugin
			kdebase3-samba
			kdebase3-session
			kdebindings3-python
			kdebluetooth
			kdegames3
			kdegraphics3
			kdegraphics3-fax
			kdegraphics3-kamera
			kdegraphics3-pdf
			kdegraphics3-postscript
			kdegraphics3-scan
			kdelibs3
			kdelibs3-32bit
			kdemultimedia3
			kdemultimedia3-CD
			kdemultimedia3-mixer
			kdenetwork3
			kdenetwork3-InstantMessenger
			kdenetwork3-news
			kdenetwork3-vnc
			kdepim3
			kdepim3-kpilot
			kdepim3-networkstatus
			kdepim3-sync
			kdetv
			kdeutils3
			kdeutils3-laptop
			kerry
			kio_beagle
			kio_ipodslave
			kio_slp
			kipi-plugins
			knights
			konversation
			kphone
			kpowersave
			krecord
			kscpm
			ktorrent
			libapparmor
			libapr0
			libart_lgpl
			libart_lgpl-32bit
			libbonobo
			libbonobo-32bit
			libcddb
			libcddb-32bit
			libcdio
			libcdio-32bit
			libexif
			libexif-32bit
			libgcc-mainline
			libgimpprint
			libgnome
			libgnome-32bit
			libgphoto2
			libgphoto2-32bit
			libid3tag
			libidl
			libidl-32bit
			libidn
			libidn-32bit
			libieee1284
			libieee1284-32bit
			libjasper
			libjasper-32bit
			libjpeg
			libjpeg-32bit
			libksba
			liblcms
			liblcms-32bit
			libmng
			libmng-32bit
			libmusicbrainz
			libnl
			libogg
			libogg-32bit
			libopencdk
			libopencdk-32bit
			libpcap
			libpng
			libpng-32bit
			libsmbclient
			libsmbclient-32bit
			libsndfile
			libsndfile-32bit
			libstdc++-mainline
			libtheora
			libtheora-32bit
			libtool
			libtool-32bit
			libtunepimp
			libvisual
			libvisual-plugins
			libvorbis
			libvorbis-32bit
			lzo
			lzo-32bit
			mDNSResponder
			mDNSResponder-32bit
			mDNSResponder-lib
			mDNSResponder-lib-32bit
			mkisofs
			mozilla-nspr
			mozilla-nspr-32bit
			mozilla-nss
			mozilla-nss-32bit
			myspell-american
			myspell-british
			neon
			neon-32bit
			net-snmp
			nvidiagl
			orbit2
			orbit2-32bit
			pango
			pango-32bit
			perl-Net-Daemon
			perl-PDA-Pilot
			perl-PlRPC
			perl-TermReadKey
			pilot-link
			pinentry
			ppp
			preload
			psutils
			python
			python-32bit
			python-xml
			qt3
			qt3-32bit
			rrdtool
			samba
			samba-32bit
			sane
			sane-32bit
			sensors
			slang
			slang-32bit
			speex
			speex-32bit
			sqlite
			sqlite-32bit
			sqlite2
			sqlite2-32bit
			startup-notification
			startup-notification-32bit
			susehelp
			taglib
			taglib-32bit
			unixODBC
			unixODBC-32bit
			vcdimager
			vcdimager-32bit
			vorbis-tools
			wvstreams
			xine-internal
			xine-lib
			xine-lib-32bit
			xorg-modular
			xscreensaver
			yast2-apparmor
			zvbi
",
	}
}

1;