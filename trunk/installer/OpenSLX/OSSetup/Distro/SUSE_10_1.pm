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
# SUSE_10_1.pm
#	- provides SUSE-10.1-specific overrides of the OpenSLX OSSetup API.
# -----------------------------------------------------------------------------
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
				ftp://ftp.gwdg.de/pub/opensuse/distribution/SL-10.1/inst-source
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
				ftp://ftp.gwdg.de/pub/suse/update/10.1
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
		i586/kernel-default-2.6.16.13-4.i586.rpm i586/kernel-default-2.6.16.21-0.25.i586.rpm
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

		'gnome' => "
			3ddiag
			855resolution
			a2ps
			aaa_base
			aaa_skel
			aalib
			acl
			acpid
			alsa
			alsa-firmware
			alsa-tools
			apparmor-docs
			apparmor-parser
			apparmor-profiles
			apparmor-utils
			arts
			art-sharp
			art-sharp2
			ash
			aspell
			aspell-en
			at
			atk
			at-spi
			attr
			audiofile
			audit
			audit-libs
			autofs
			autoyast2
			autoyast2-installation
			awesfx
			banshee
			banshee-engine-gst
			banshee-plugins-DAAP
			bash
			bc
			beagle
			beagle-evolution
			beagle-firefox
			beagle-gui
			beagle-index
			bind-libs
			bind-utils
			binutils
			bitstream-vera
			blam
			blocxx
			blt
			bluez-libs
			bluez-utils
			boost
			bootsplash
			bootsplash-theme-SuSE
			bug-buddy
			busybox
			bzip2
			cabextract
			cairo
			capi4linux
			cdparanoia
			cdrdao
			cdrecord
			CheckHardware
			checkmedia
			cifs-mount
			compat
			compat-curl2
			compat-libstdc++
			compat-openssl097g
			contact-lookup-applet
			control-center2
			convmv
			coreutils
			cpio
			cpp
			cpufrequtils
			cracklib
			cron
			Crystalcursors
			cups
			cups-client
			cups-drivers
			cups-drivers-stp
			cups-libs
			cups-SUSE-ppds-dat
			curl
			cyrus-sasl
			cyrus-sasl-saslauthd
			dasher
			db
			dbus-1
			dbus-1-glib
			dbus-1-gtk
			dbus-1-mono
			dbus-1-python
			dbus-1-qt3
			dbus-1-x11
			dcraw
			dejavu
			deltarpm
			desktop-data-SuSE
			desktop-file-utils
			desktop-translations
			device-mapper
			devs
			dhcdbd
			dhcp
			dhcpcd
			dhcp-client
			dia
			dialog
			diffutils
			DirectFB
			dirmngr
			dmraid
			docbook_4
			dos2unix
			dosbootdisk
			dosfstools
			dvd+rw-tools
			e2fsprogs
			ed
			eel
			efont-unicode
			eject
			enigma
			eog
			epiphany
			epiphany-extensions
			esound
			ethtool
			evince
			evolution
			evolution-data-server
			evolution-exchange
			evolution-pilot
			evolution-sharp
			evolution-webcal
			expat
			fam
			fam-server
			fbset
			festival
			file
			file-roller
			fileshareset
			filesystem
			fillup
			filters
			findutils
			finger
			flac
			fontconfig
			fonts-config
			foomatic-filters
			freeciv
			freeglut
			freetype
			freetype2
			fribidi
			frozen-bubble
			f-spot
			fvwm2
			gail
			gaim
			gal2
			gawk
			gcalctool
			gconf2
			gconf-editor
			gconf-sharp
			gconf-sharp2
			gdb
			gdbm
			gdk-pixbuf
			gdm
			gecko-sharp
			gecko-sharp2
			gedit
			gettext
			ghex
			ghostscript-fonts-other
			ghostscript-fonts-std
			ghostscript-library
			ghostscript-x11
			giflib
			gimp
			gimp-cmyk
			gimp-help
			glade-sharp
			glade-sharp2
			gle
			glib
			glib2
			glibc
			glibc-i18ndata
			glibc-locale
			glibmm24
			glib-sharp
			glib-sharp2
			glitz
			gmime
			gnet
			gnome2-SuSE
			gnome2-user-docs
			gnome-applets
			gnome-audio
			gnome-backgrounds
			gnome-blog
			gnome-bluetooth
			gnome-cups-manager
			gnome-desktop
			gnome-doc-utils
			gnome-filesystem
			gnome-games
			gnome-icon-theme
			gnome-keyring
			gnome-keyring-manager
			gnome-mag
			gnome-media
			gnomemeeting
			gnome-menus
			gnome-mime-data
			gnome-netstatus
			gnome-nettool
			gnome-panel
			gnome-pilot
			gnome-power-manager
			gnome-printer-add
			gnome-screensaver
			gnome-session
			gnome-sharp
			gnome-sharp2
			gnome-speech
			gnome-spell2
			gnome-system-monitor
			gnome-terminal
			gnome-themes
			gnome-utils
			gnome-vfs2
			gnome-vfs-sharp2
			gnome-volume-manager
			gnopernicus
			gnumeric
			gnutls
			goffice
			gok
			gpart
			gpg
			gpg2
			gpgme
			gpm
			grep
			groff
			grub
			gsf-sharp
			gstreamer010
			gstreamer010-plugins-base
			gstreamer010-plugins-base-oil
			gstreamer010-plugins-base-visual
			gstreamer010-plugins-good
			gtk
			gtk2
			gtk2-engines
			gtk2-themes
			gtk-engines
			gtkhtml2
			gtkhtml-sharp2
			gtklp
			gtkmm24
			gtk-sharp
			gtk-sharp2
			gtk-sharp2-gapi
			gtk-sharp-gapi
			gtksourceview
			gtkspell
			gucharmap
			guile
			gzip
			hal
			hal-gnome
			hal-resmgr
			hdparm
			hermes
			hplip
			hplip-hpijs
			htdig
			hwinfo
			i4l-base
			i4lfirm
			i4l-isdnlog
			id3lib
			ifnteuro
			ifplugd
			ImageMagick
			ImageMagick-Magick++
			imlib
			info
			info2html
			initviocons
			inkscape
			insserv
			intlfnts
			ipod-sharp
			iproute2
			iptables
			iputils
			isapnp
			iso-codes
			iso_ent
			ispell
			ispell-american
			ispell-british
			jack
			java-1_4_2-gcj-compat
			jfsutils
			joe
			jpackage-utils
			kbd
			kdebase3
			kdebase3-ksysguardd
			kdebase3-SuSE
			kdebindings3-python
			kdelibs3
			kdelibs3-doc
			kernel-default
			kino
			kio_slp
			klogd
			krb5
			krb5-client
			ksymoops
			ldapcpplib
			less
			lftp
			libacl
			libao
			libapparmor
			libart_lgpl
			libattr
			libavc1394
			libbeagle
			libbonobo
			libbonoboui
			libbtctl
			libcap
			libcddb
			libcdio
			libcom_err
			libcroco
			libdc1394
			libdrm
			libdv
			libdvdnav
			libdvdread
			libEMF
			libevent
			libexif
			libgail-gnome
			libgcc
			libgcj
			libgcrypt
			libgda
			libgdiplus
			libgimpprint
			libglade2
			libgnome
			libgnomecanvas
			libgnomecups
			libgnomedb
			libgnomeprint
			libgnomeprintui
			libgnomesu
			libgnomeui
			libgpg-error
			libgphoto2
			libgsf
			libgsf-gnome
			libgssapi
			libgtkhtml
			libgtop
			libicu
			libid3tag
			libidl
			libidn
			libieee1284
			libiniparser
			libipoddevice
			libjasper
			libjpeg
			libksba
			liblcms
			libmikmod
			libmng
			libmusicbrainz
			libnetpbm
			libnjb
			libnl
			libnotify
			libnscd
			libnvtv
			libogg
			liboil
			libopencdk
			libosip2
			libpcap
			libpng
			libquicktime
			libraw1394
			librpcsecgss
			librsvg
			libsamplerate
			libsexy
			libshout
			libsigc++2
			libsmbclient
			libsndfile
			libsoup
			libstdc++
			libstroke
			libsvg
			libsvg-cairo
			libtheora
			libtiff
			libtool
			libusb
			libvisual
			libvorbis
			libwmf
			libwnck
			libxcrypt
			libxklavier
			libxml2
			libxml2-python
			libxslt
			liby2util
			libzio
			libzypp
			libzypp-zmd-backend
			liferea
			lilo
			limal
			limal-bootloader
			limal-perl
			linphone
			linphone-applet
			linux-atm-lib
			lirc
			log4net
			logrotate
			loudmouth
			lsb
			lsof
			lua
			lukemftp
			lzo
			m4
			mailx
			make
			man
			man-pages
			manufacturer-PPDs
			master-boot-code
			mc
			mdadm
			mDNSResponder
			mDNSResponder-lib
			mergeant
			Mesa
			metacity
			metacity-themes
			microcode_ctl
			mingetty
			mjpegtools
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
			mozilla-xulrunner
			mtools
			multisync
			multisync-backup
			multisync-evolution
			multisync-irmc
			multisync-irmc-bluetooth
			multisync-ldap
			multisync-opie
			multisync-syncml
			myspell-american
			myspell-british
			nano
			nautilus
			nautilus-cd-burner
			nautilus-open-terminal
			nautilus-sendto
			nautilus-share
			ncurses
			neon
			netcat
			netcfg
			netpbm
			net-snmp
			net-tools
			NetworkManager
			NetworkManager-gnome
			nfsidmap
			nfs-utils
			notification-daemon
			novfs-kmp-default
			nscd
			ntfsprogs
			openct
			OpenEXR
			openh323
			openldap2-client
			openmotif-libs
			openobex
			OpenOffice_org
			OpenOffice_org-gnome
			opensc
			openslp
			opensp
			openssh
			openssh-askpass
			openssl
			orbit2
			pam
			pam_krb5
			pam-modules
			pan
			pango
			parted
			patch
			pax
			pciutils
			pcre
			pcsc-lite
			perl
			perl-Bootloader
			perl-Compress-Zlib
			perl-Config-Crontab
			perl-Crypt-SmbHash
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
			perl-Parse-RecDescent
			perl-PDA-Pilot
			perl-PlRPC
			perl-spamassassin
			perl-TermReadKey
			perl-TermReadLine-Gnu
			perl-TimeDate
			perl-URI
			perl-X500-DN
			perl-XML-LibXML
			perl-XML-LibXML-Common
			perl-XML-NamespaceSupport
			perl-XML-Parser
			perl-XML-SAX
			perl-XML-Writer
			permissions
			pilot-link
			pin
			pinentry
			planner
			pmtools
			poppler
			poppler-glib
			popt
			portmap
			postfix
			powersave
			powersave-libs
			ppp
			pptp
			procinfo
			procmail
			procps
			providers
			psiconv
			psmisc
			pstoedit
			pwdutils
			pwlib
			python
			python-cairo
			python-gnome
			python-gnome-extras
			python-gtk
			python-imaging
			python-numeric
			python-orbit
			python-qt
			python-tk
			python-xml
			qscintilla
			qt3
			readline
			recode
			reiserfs
			release-notes
			resapplet
			resmgr
			rpm
			rrdtool
			rsh
			rsync
			rug
			samba
			samba-client
			samba-winbind
			sane
			sash
			sax2
			sax2-gui
			sax2-ident
			sax2-libsax
			sax2-libsax-perl
			sax2-tools
			scpm
			screen
			scrollkeeper
			scsi
			SDL
			SDL_image
			SDL_mixer
			SDL_net
			SDL_perl
			SDL_ttf
			sed
			sensors
			setserial
			sgml-skel
			shared-mime-info
			siga
			sisctrl
			skencil
			slang
			smpppd
			sound-juicer
			sox
			spamassassin
			speex
			sqlite
			sqlite2
			src_vipa
			startup-notification
			strace
			sudo
			supertux
			suse-build-key
			SuSEfirewall2
			susehelp
			susehelp_en
			suselinux-manual_en
			suseRegister
			suse-release
			suspend
			sysconfig
			sysfsutils
			syslinux
			syslog-ng
			sysvinit
			taglib
			tango-icon-theme
			tar
			tcl
			tcpd
			tcsh
			telnet
			terminfo
			testgart
			thinkeramik-style
			tightvnc
			timezone
			tiny-nvidia-installer
			tix
			tk
			tomboy
			totem
			tree
			udev
			unclutter
			unix2dos
			unixODBC
			unrar
			unzip
			update-alternatives
			usbutils
			utempter
			util-linux
			v4l-conf
			vacation
			vcdimager
			vim
			vte
			w3m
			wbxml2
			wdiff
			wget
			WindowMaker
			WindowMaker-applets
			WindowMaker-themes
			wireless-tools
			words
			wpa_supplicant
			wv
			wvdial
			wvstreams
			x11-input-gunze
			x11-input-synaptics
			x11-input-wacom
			x11-tools
			xdelta
			xdg-menu
			xdmbgrd
			xfsprogs
			xine-lib
			xinetd
			xkeyboard-config
			xli
			xlockmore
			xmlcharent
			xmms-lib
			xmoto
			xmset
			xntp
			xorg-x11
			xorg-x11-driver-video
			xorg-x11-driver-video-nvidia
			xorg-x11-fonts-100dpi
			xorg-x11-fonts-75dpi
			xorg-x11-fonts-scalable
			xorg-x11-libs
			xorg-x11-server
			xorg-x11-server-glx
			xorg-x11-Xnest
			xorg-x11-Xvnc
			xpdf
			xpdf-tools
			xsane
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
			yast2-dhcp-server
			yast2-dns-server
			yast2-firewall
			yast2-hardware-detection
			yast2-http-server
			yast2-inetd
			yast2-installation
			yast2-irda
			yast2-kerberos-client
			yast2-ldap
			yast2-ldap-client
			yast2-mail
			yast2-mail-aliases
			yast2-mouse
			yast2-ncurses
			yast2-network
			yast2-nfs-client
			yast2-nfs-server
			yast2-nis-client
			yast2-nis-server
			yast2-ntp-client
			yast2-online-update
			yast2-online-update-frontend
			yast2-packager
			yast2-pam
			yast2-perl-bindings
			yast2-phone-services
			yast2-pkg-bindings
			yast2-power-management
			yast2-powertweak
			yast2-printer
			yast2-profile-manager
			yast2-qt
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
			yast2-storage-lib
			yast2-support
			yast2-sysconfig
			yast2-tftp-server
			yast2-theme-SuSELinux
			yast2-trans-de
			yast2-transfer
			yast2-trans-stats
			yast2-tune
			yast2-tv
			yast2-update
			yast2-users
			yast2-vm
			yast2-x11
			yast2-xml
			yelp
			ypbind
			yp-tools
			zenity
			zen-updater
			zip
			ziptool
			zisofs-tools
			zlib
			zmd
			zsh
			zvbi
		",
	};
}

1;