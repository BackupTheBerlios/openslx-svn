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
		'base_non-oss' => {
			'urls' => "
				ftp://ftp.gwdg.de/pub/opensuse/distribution/10.2/repo/non-oss
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

		'kde' => "
			3ddiag
			915resolution
			a2ps
			aaa_base
			aaa_skel
			aalib
			acl
			acpid
			AdobeICCProfiles
			agfa-fonts
			alsa
			amarok
			amarok-libvisual
			amarok-xine
			apparmor-docs
			apparmor-parser
			apparmor-profiles
			apparmor-utils
			arts
			ash
			aspell
			aspell-de
			aspell-en
			at
			atk
			attr
			audiofile
			audit
			audit-libs
			autofs
			autoyast2
			autoyast2-installation
			bash
			bc
			beagle
			beagle-firefox
			beagle-index
			bind-libs
			bind-utils
			binutils
			blocxx
			bluez-libs
			bluez-utils
			boost
			bootsplash
			bootsplash-theme-SuSE
			bzip2
			cabextract
			cairo
			cdparanoia
			cdrdao
			CheckHardware
			checkmedia
			chromium
			classpath
			compat
			compat-libstdc++
			compat-openssl097g
			compiz
			coreutils
			cpio
			cpp
			cpp41
			cpufrequtils
			cracklib
			cron
			Crystalcursors
			cups
			cups-client
			cups-drivers
			cups-libs
			curl
			cyrus-sasl
			cyrus-sasl-crammd5
			cyrus-sasl-digestmd5
			cyrus-sasl-plain
			cyrus-sasl-saslauthd
			db
			dbus-1
			dbus-1-glib
			dbus-1-mono
			dbus-1-qt3
			dbus-1-x11
			db-utils
			dcraw
			dejavu
			deltarpm
			desktop-data-SuSE
			desktop-file-utils
			desktop-translations
			device-mapper
			dhcdbd
			dhcp
			dhcpcd
			dhcp-client
			dialog
			diffutils
			digikam
			digikamimageplugins
			dirmngr
			dmraid
			dos2unix
			dosbootdisk
			dosfstools
			dvd+rw-tools
			e2fsprogs
			ed
			efont-unicode
			eject
			enscript
			esound
			ethtool
			evms
			evms-gui
			exiftool
			expat
			fam
			fbset
			fftw3
			file
			fileshareset
			filesystem
			fillup
			findutils
			flac
			flash-player
			fontconfig
			fonts-config
			foomatic-filters
			freealut
			freeciv
			freeglut
			freetype
			freetype2
			fribidi
			frozen-bubble
			ft2demos
			ftgl
			fvwm2
			gail
			gawk
			gcc41-gij
			gcc-gij
			gconf2
			gdb
			gdbm
			gettext
			ghostscript-fonts-other
			ghostscript-fonts-std
			ghostscript-library
			ghostscript-x11
			giflib
			gimp
			gimp-help
			gle
			glib
			glib2
			glibc
			glibc-i18ndata
			glibc-locale
			glib-sharp2
			glitz
			gmime
			gmp
			gnokii
			gnome-filesystem
			gnome-icon-theme
			gnome-keyring
			gnome-mime-data
			gnome-vfs2
			gnutls
			gpart
			gpg
			gpg2
			gpgme
			gpm
			GraphicsMagick
			grep
			groff
			grub
			gsf-sharp
			gstreamer010
			gstreamer010-plugins-base
			gtk
			gtk2
			gtk-sharp2
			gtksourceview
			gutenprint
			gwenview
			gzip
			hal
			hal-resmgr
			hdparm
			hfsutils
			hplip
			hplip-hpijs
			htdig
			hwinfo
			id3lib
			ifnteuro
			ifplugd
			ImageMagick
			ImageMagick-Magick++
			imlib
			imlib2
			imlib2-loaders
			info
			info2html
			initviocons
			insserv
			inst-source-utils
			intlfnts
			iproute2
			iptables
			iputils
			irqbalance
			ispell
			ispell-american
			ispell-german
			ispell-ngerman
			jack
			java-1_4_2-gcj-compat
			java-1_5_0-sun
			java-1_5_0-sun-plugin
			jfsutils
			joe
			jpackage-utils
			jpeg
			k3b
			kaffeine
			kbd
			kcm_gtk
			kde3-i18n-de
			kdeaddons3-kicker
			kdeaddons3-konqueror
			kdeartwork3-kscreensaver
			kdeartwork3-xscreensaver
			kdebase3
			kdebase3-beagle
			kdebase3-kdm
			kdebase3-ksysguardd
			kdebase3-nsplugin
			kdebase3-samba
			kdebase3-session
			kdebase3-SuSE
			kdebluetooth
			kdegames3
			kdegraphics3
			kdegraphics3-kamera
			kdegraphics3-pdf
			kdegraphics3-postscript
			kdegraphics3-scan
			kdelibs3
			kdelibs3-doc
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
			kdepim3-notes
			kdetv
			kdeutils3
			kernel-default
			kerry
			kio_beagle
			kio_ipodslave
			kio_iso
			kio_slp
			kipi-plugins
			kitchensync
			klogd
			knights
			koffice
			koffice-i18n-de
			koffice-i18n-de-doc
			koffice-illustration
			konversation
			kpowersave
			krb5
			krecord
			ksh
			ksudoku
			ksymoops
			ktorrent
			kwin-decor-suse2
			lbreakout
			ldapcpplib
			less
			libacl
			libakode
			libao
			libapparmor
			libart_lgpl
			libattr
			libbeagle
			libbonobo
			libbonoboui
			libcap
			libcom_err
			libcroco
			libdrm
			libevent
			libexif
			libgcc41
			libgcj41
			libgcrypt
			libgimpprint
			libglade2
			libgnome
			libgnomecanvas
			libgnomecups
			libgnomeprint
			libgnomeprintui
			libgnomesu
			libgnomeui
			libgpg-error
			libgphoto2
			libgpod
			libgsf
			libgsf-gnome
			libgssapi
			libgtkhtml
			libical
			libicu
			libidl
			libidn
			libieee1284
			libjasper
			libjpeg
			libkexif
			libkipi
			libksba
			liblazy
			liblcms
			libltdl
			libmal
			libmikmod
			libmng
			libmpcdec
			libmtp
			libmusicbrainz
			libnetpbm
			libnjb
			libnl
			libnscd
			libofa
			libogg
			liboil
			libopencdk
			libopensync
			libopensync-plugin-file
			libopensync-plugin-gnokii
			libopensync-plugin-gpe
			libopensync-plugin-irmc
			libopensync-plugin-kdepim
			libopensync-plugin-opie
			libopensync-plugin-palm
			libopensync-plugin-sunbird
			libopensync-plugin-syncml
			libopensync-tools
			libpcap
			libpng
			libqt4
			libqt4-dbus-1
			libqt4-qt3support
			libqt4-sql
			libqt4-x11
			libqtpod
			librpcsecgss
			librsvg
			libsamplerate
			libsmbclient
			libsndfile
			libsoup
			libstdc++41
			libstroke
			libsyncml
			libtheora
			libtiff
			libtunepimp
			libusb
			libvisual
			libvolume_id
			libvorbis
			libwmf
			libwnck
			libxcrypt
			libxml2
			libxslt
			liby2util
			libzio
			libzypp
			libzypp-zmd-backend
			limal
			limal-bootloader
			limal-perl
			logrotate
			lsb
			lsof
			lua-libs
			lukemftp
			lvm2
			lzo
			m4
			mailx
			make
			man
			man-pages
			manufacturer-PPDs
			master-boot-code
			mdadm
			mDNSResponder-lib
			Mesa
			metacity
			microcode_ctl
			mingetty
			mkinitrd
			mkisofs
			mktemp
			module-init-tools
			mono-core
			mono-data
			mono-data-sqlite
			mono-web
			MozillaFirefox
			MozillaFirefox-translations
			mozilla-nspr
			mozilla-nss
			mozilla-xulrunner181
			multipath-tools
			myspell-american
			myspell-german
			ncurses
			neon
			netcat
			netcfg
			netpbm
			net-snmp
			net-tools
			NetworkManager
			NetworkManager-kde
			nfsidmap
			nfs-utils
			nscd
			ntfsprogs
			numlockx
			ocrad
			openal
			openct
			OpenEXR
			openldap2-client
			openobex
			OpenOffice_org
			OpenOffice_org-de
			OpenOffice_org-kde
			OpenOffice_org-Quickstarter
			opensc
			openslp
			openssh
			openssh-askpass
			openssl
			opensuse-manual_de
			opensuse-manual_en
			opensuse-quickstart_de
			opensuse-quickstart_en
			openSUSE-release
			opensuse-updater
			orbit2
			pam
			pam-config
			pam-modules
			pango
			parted
			patch
			pax
			pciutils
			pciutils-ids
			pcre
			pcsc-lite
			perl
			perl-Bootloader
			perl-Compress-Zlib
			perl-Config-Crontab
			perl-Crypt-SmbHash
			perl-Crypt-SSLeay
			perl-DBD-SQLite
			perl-DBI
			perl-Digest-HMAC
			perl-Digest-MD4
			perl-Digest-SHA1
			perl-File-Tail
			perl-gettext
			perl-HTML-Parser
			perl-HTML-Tagset
			perl-IO-Zlib
			perl-libwww-perl
			perl-Net-Daemon
			perl-Net-DNS
			perl-Net-IP
			perl-PlRPC
			perl-spamassassin
			perl-TermReadKey
			perl-TimeDate
			perl-URI
			perl-XML-Parser
			perl-XML-Writer
			permissions
			phalanx
			pilot-link
			pinentry
			pinentry-qt
			pkgconfig
			pmtools
			pm-utils
			PolicyKit
			poppler
			poppler-qt
			popt
			portmap
			postfix
			powersave
			powersave-libs
			ppp
			pptp
			preload
			procinfo
			procmail
			procps
			providers
			psmisc
			pwdutils
			python
			python-qt
			python-xml
			qca
			qlogic-firmware
			qscintilla
			qt3
			qtcurve-gtk2
			rdesktop
			readline
			RealPlayer
			recode
			reiserfs
			release-notes
			resmgr
			rpm
			rrdtool
			rsync
			ruby
			rug
			sane
			sane-frontends
			sash
			sax2
			sax2-gui
			sax2-ident
			sax2-libsax
			sax2-libsax-perl
			sax2-tools
			scpm
			screen
			scsi
			SDL
			SDL_image
			SDL_mixer
			SDL_net
			SDL_Pango
			SDL_perl
			SDL_ttf
			sed
			sensors
			sgml-skel
			shared-mime-info
			sharutils
			siga
			smartmontools
			smpppd
			spamassassin
			speex
			sqlite
			sqlite2
			sqlite-zmd
			startup-notification
			strace
			sudo
			supertux
			suse-build-key
			SuSEfirewall2
			susehelp
			susehelp_de
			suseRegister
			suspend
			sysconfig
			sysfsutils
			syslog-ng
			sysvinit
			taglib
			tar
			tcl
			tcpd
			tcpdump
			tcsh
			telnet
			terminfo
			tightvnc
			timezone
			tk
			udev
			ufraw
			ufraw-gimp
			ulimit
			unclutter
			unzip
			update-alternatives
			usbutils
			utempter
			util-linux
			v4l-conf
			vim
			w3m
			wbxml2
			wdiff
			wget
			wireless-tools
			wodim
			words
			wpa_supplicant
			wv
			wvdial
			wvstreams
			x11-input-synaptics
			x11-input-wacom
			x11-tools
			xaw3d
			xdg-menu
			xdg-utils
			xdmbgrd
			xfsprogs
			xgl
			xgl-hardware-list
			xine-lib
			xinetd
			xkeyboard-config
			xli
			xlockmore
			xmoto
			xntp
			xorg-x11
			xorg-x11-driver-input
			xorg-x11-driver-video
			xorg-x11-fonts
			xorg-x11-fonts-core
			xorg-x11-libfontenc
			xorg-x11-libICE
			xorg-x11-libs
			xorg-x11-libSM
			xorg-x11-libX11
			xorg-x11-libX11-ccache
			xorg-x11-libXau
			xorg-x11-libXdmcp
			xorg-x11-libXext
			xorg-x11-libXfixes
			xorg-x11-libxkbfile
			xorg-x11-libXmu
			xorg-x11-libXp
			xorg-x11-libXpm
			xorg-x11-libXprintUtil
			xorg-x11-libXrender
			xorg-x11-libXt
			xorg-x11-libXv
			xorg-x11-server
			xorg-x11-Xvnc
			xpdf-tools
			xscreensaver
			xterm
			xtermset
			yast2
			yast2-apparmor
			yast2-backup
			yast2-bluetooth
			yast2-bootfloppy
			yast2-bootloader
			yast2-control-center
			yast2-core
			yast2-country
			yast2-firewall
			yast2-hardware-detection
			yast2-inetd
			yast2-installation
			yast2-irda
			yast2-iscsi-client
			yast2-kerberos-client
			yast2-ldap
			yast2-ldap-client
			yast2-mail
			yast2-mail-aliases
			yast2-mouse
			yast2-ncurses
			yast2-network
			yast2-nfs-client
			yast2-nis-client
			yast2-ntp-client
			yast2-online-update
			yast2-online-update-frontend
			yast2-packager
			yast2-pam
			yast2-perl-bindings
			yast2-pkg-bindings
			yast2-power-management
			yast2-powertweak
			yast2-printer
			yast2-profile-manager
			yast2-qt
			yast2-registration
			yast2-repair
			yast2-restore
			yast2-runlevel
			yast2-samba-client
			yast2-samba-server
			yast2-scanner
			yast2-schema
			yast2-security
			yast2-slp
			yast2-sound
			yast2-storage
			yast2-storage-evms
			yast2-storage-lib
			yast2-sudo
			yast2-support
			yast2-sysconfig
			yast2-theme-openSUSE
			yast2-trans-de
			yast2-transfer
			yast2-trans-stats
			yast2-tune
			yast2-tv
			yast2-update
			yast2-users
			yast2-x11
			yast2-xml
			ypbind
			yp-tools
			zen-updater
			zip
			zisofs-tools
			zlib
			zmd
			zsh
			zvbi
			zypper
		",
	};
}

1;