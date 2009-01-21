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
# Basics.pm
#	- provides basic functionality of the OpenSLX config-db.
# -----------------------------------------------------------------------------
package OpenSLX::Basics;

use strict;
use vars qw(@ISA @EXPORT $VERSION);

use Exporter;
$VERSION = 1.01;
@ISA = qw(Exporter);

@EXPORT = qw(
	&openslxInit %openslxConfig %cmdlineConfig
	&_tr &trInit
	&die &executeInSubprocess &slxsystem
	&vlog
);

use vars qw(%openslxConfig %cmdlineConfig);

################################################################################
### Module implementation
################################################################################
use Carp;
use FindBin;
use Getopt::Long;
use POSIX qw(locale_h);

my %translations;

# this hash will hold the active openslx configuration,
# the initial content is based on environment variables or default values.
# Each value may be overrided from config files and/or cmdline arguments.
%openslxConfig = (
	'croak' => '0',
	'db-datadir' => $ENV{SLX_DB_DATADIR},
	'db-name' => $ENV{SLX_DB_NAME} || 'openslx',
	'db-spec' => $ENV{SLX_DB_SPEC},
	'db-type' => $ENV{SLX_DB_TYPE} || 'CSV',
	'locale' => setlocale(LC_MESSAGES),
	'locale-charmap' => `locale charmap`,
	'base-path' => $ENV{SLX_BASE_PATH} || '/opt/openslx',
	'config-path' => $ENV{SLX_CONFIG_PATH} || '/etc/opt/openslx',
	'private-path' => $ENV{SLX_PRIVATE_PATH} || '/var/opt/openslx',
	'public-path' => $ENV{SLX_PUBLIC_PATH} || '/srv/openslx',
	'temp-path' => $ENV{SLX_TEMP_PATH} || '/tmp',
	'verbose-level' => $ENV{SLX_VERBOSE_LEVEL} || '0',
);
chomp($openslxConfig{'locale-charmap'});
$openslxConfig{'bin-path'}
	= $ENV{SLX_BIN_PATH} || "$openslxConfig{'base-path'}/bin",
$openslxConfig{'db-basepath'}
	= $ENV{SLX_DB_PATH} || "$openslxConfig{'private-path'}/db",
$openslxConfig{'export-path'}
	= $ENV{SLX_EXPORT_PATH} || "$openslxConfig{'public-path'}/export",
$openslxConfig{'share-path'}
	= $ENV{SLX_SHARE_PATH} || "$openslxConfig{'base-path'}/share",
$openslxConfig{'stage1-path'}
	= $ENV{SLX_STAGE1_PATH} || "$openslxConfig{'private-path'}/stage1",
$openslxConfig{'tftpboot-path'}
	= $ENV{SLX_TFTPBOOT_PATH} || "$openslxConfig{'public-path'}/tftpboot",

# specification of cmdline arguments that are shared by all openslx-scripts:
%cmdlineConfig;
my %openslxCmdlineArgs = (
	'base-path=s' => \$cmdlineConfig{'base-path'},
		# basic path to project files (binaries, functionality templates and
		# distro-specs)
	'bin-path=s' => \$cmdlineConfig{'bin-path'},
		# path to binaries and scripts
	'config-path=s' => \$cmdlineConfig{'config-path'},
		# path to configuration files
	'croak' => \$cmdlineConfig{'croak'},
		# activates debug mode, this will show the lines where any error occured
	'db-basepath=s' => \$cmdlineConfig{'db-basepath'},
		# basic path to openslx database, defaults to "${private-path}/db"
	'db-datadir=s' => \$cmdlineConfig{'db-datadir'},
		# data folder created under db-basepath, default depends on db-type
	'db-name=s' => \$cmdlineConfig{'db-name'},
		# name of database, defaults to 'openslx'
	'db-spec=s' => \$cmdlineConfig{'db-spec'},
		# full specification of database, a special string defining the
		# precise database to connect to (the contents of this string
		# depend on db-type)
	'db-type=s' => \$cmdlineConfig{'db-type'},
		# type of database to connect to (CSV, SQLite, ...), defaults to 'CSV'
	'export-path=s' => \$cmdlineConfig{'export-path'},
		# path to root of all exports, each different export-type (e.g. nfs, nbd)
		# has a separate subfolder in here.
	'locale=s' => \$cmdlineConfig{'locale'},
		# locale to use for translations
	'locale-charmap=s' => \$cmdlineConfig{'locale-charmap'},
		# locale-charmap to use for I/O (iso-8859-1, utf-8, etc.)
	'logfile=s' => \$cmdlineConfig{'locale'},
		# file to write logging output to, defaults to STDERR
	'private-path=s' => \$cmdlineConfig{'private-path'},
		# path to private data (which is *not* accesible by clients and contains
		# database, vendorOSes and all local extensions [system specific scripts])
	'public-path=s' => \$cmdlineConfig{'public-path'},
		# path to public data (which is accesible by clients and contains
		# PXE-configurations, kernels, initramfs and client configurations)
	'share-path=s' => \$cmdlineConfig{'share-path'},
		# path to sharable data (functionality templates and distro-specs)
	'stage1-path=s' => \$cmdlineConfig{'stage1-path'},
		# path to stage1 systems
	'temp-path=s' => \$cmdlineConfig{'temp-path'},
		# path to temporary data (used during demuxing)
	'tftpboot-path=s' => \$cmdlineConfig{'tftpboot-path'},
		# path to root of tftp-server, tftpable data will be stored there
	'verbose-level=i' => \$cmdlineConfig{'verbose-level'},
		# level of logging verbosity (0-3)
);

# filehandle used for logging:
my $openslxLog = *STDERR;

# ------------------------------------------------------------------------------
sub vlog
{
	my $minLevel = shift;
	return if $minLevel > $openslxConfig{'verbose-level'};
	my $str = join("", '-'x$minLevel, @_);
	if (substr($str,-1,1) ne "\n") {
		$str .= "\n";
	}
	print $openslxLog $str;
}

# ------------------------------------------------------------------------------
sub openslxInit
{
	# evaluate cmdline arguments:
	Getopt::Long::Configure('no_pass_through');
	GetOptions(%openslxCmdlineArgs) or return 0;

	# try to read and evaluate config files:
	my $configPath = $cmdlineConfig{'config-path'}
						|| $openslxConfig{'config-path'};
	foreach my $f ("$configPath/settings.default",
				   "$configPath/settings.local",
				   "$ENV{HOME}/.openslx/settings") {
		next unless open(CONFIG, "<$f");
		if ($cmdlineConfig{'verbose-level'} >= 2) {
			vlog 0, "reading config-file $f...";
		}
		while(<CONFIG>) {
			chomp;
			s/#.*//;
			s/^\s+//;
			s/\s+$//;
			next unless length;
			if (! /^(\w+)=(.*)$/) {
				die _tr("config-file <%s> has incorrect syntax here:\n\t%s\n",
						$f, $_);
			}
			my ($key, $value) = ($1, $2);
			# N.B.: the config files are used by shell-scripts, too, so in
			# order to comply with shell-style, the config files use shell
			# syntax and an uppercase, underline-as-separator format.
			# Internally, we use lowercase, minus-as-separator format, so we
			# need to convert the environment variable names to our own
			# internal style here (e.g. 'SLX_BASE_PATH' to 'base-path'):
			$key =~ s[^SLX_][];
			$key =~ tr/[A-Z]_/[a-z]-/;
			$openslxConfig{$key} = $value;
		}
		close CONFIG;
	}

	# push any cmdline argument into our config hash, possibly overriding any
	# setting from the config files:
	while(my ($key, $val) = each(%cmdlineConfig)) {
		next unless defined $val;
		$openslxConfig{$key} = $val;
	}

	if (defined $openslxConfig{'logfile'}
	&& open(LOG, ">>$openslxConfig{'logfile'}")) {
		$openslxLog
	}
	if ($openslxConfig{'verbose-level'} >= 2) {
		foreach my $k (sort keys %openslxConfig) {
			vlog 2, "config-dump: $k = $openslxConfig{$k}";
		}
	}

	# setup translation "engine":
	trInit();

	return 1;
}

# ------------------------------------------------------------------------------
sub trInit
{
	# set the specified locale...
	setlocale('LC_ALL', $openslxConfig{'locale'});

	# ...and activate automatic charset conversion on all I/O streams:
	binmode(STDIN, ":encoding($openslxConfig{'locale-charmap'})");
	binmode(STDOUT, ":encoding($openslxConfig{'locale-charmap'})");
	binmode(STDERR, ":encoding($openslxConfig{'locale-charmap'})");
	use open ':locale';

	my $locale = $openslxConfig{'locale'};
	if (lc($locale) eq 'c') {
		# treat locale 'c' as equivalent for 'posix':
		$locale = 'posix';
	}

	# load Posix-Translations first in order to fall back to English strings
	# if a specific translation isn't available:
	if (eval "require OpenSLX::Translations::posix") {
		%translations = %OpenSLX::Translations::posix::translations;
	} else {
		vlog 1, "unable to load translations module 'posix' ($@).";
	}

	if (lc($locale) ne 'posix') {
		# parse locale and canonicalize it (e.g. to 'de_DE') and generate
		# two filenames from it (language+country and language only):
		if ($locale !~ m{^\s*([^_]+)(?:_(\w+))?}) {
			die "locale $locale has unknown format!?!";
		}
		my @locales;
		if (defined $2) {
			push @locales, lc($1).'_'.uc($2);
		}
		push @locales, lc($1);

		# try to load any of the Translation modules (starting with the more
		# specific one [language+country]):
		my $loadedTranslationModule;
		foreach my $trName (@locales) {
			my $trModule = "OpenSLX::Translations::$trName";
			if (eval "require $trModule") {
				# Access OpenSLX::Translations::<locale>::translations
				# via a symbolic reference...
				no strict 'refs';
				my $translationsRef	= \%{ "${trModule}::translations" };
				# ...and copy the available translations into our hash:
				foreach my $k (keys %{$translationsRef}) {
					$translations{$k} = $translationsRef->{$k};
				}
				$loadedTranslationModule = $trModule;
				vlog 1, _tr("translations module %s loaded successfully",
							$trModule);
				last;
			}
		}
		if (!defined $loadedTranslationModule) {
			vlog 1, "unable to load any translations module for locale '$locale' ($!).";
		}
	}
}

# ------------------------------------------------------------------------------
sub _tr
{
	my $trOrig = shift;

	my $trKey = $trOrig;
	$trKey =~ s[\n][\\n]g;
	$trKey =~ s[\t][\\t]g;

	my $formatStr = $translations{$trKey};
	if (!defined $formatStr) {
		vlog 2, "Translation key '$trKey' not found.";
		$formatStr = $trOrig;
	}
	return sprintf($formatStr, @_);
}

# ------------------------------------------------------------------------------
sub executeInSubprocess
{
	my $childFunc = shift;

	my $pid = fork();
	if (!$pid) {
		# child...
		# ...execute the given function and exit:
		&$childFunc();
		exit 0;
	}

	# parent...
	# ...pass on interrupt- and terminate-signals to child...
	local $SIG{INT}
		= sub { kill 'INT', $pid; waitpid($pid, 0); exit $? };
	local $SIG{TERM}
		= sub { kill 'TERM', $pid; waitpid($pid, 0); exit $? };
	# ...and wait for child to do its work:
	waitpid($pid, 0);
	if ($?) {
		exit $?;
	}
}

# ------------------------------------------------------------------------------
sub slxsystem
{
	my $res = system(@_);
	if ($res & 127) {
		# child got killed, so we stop, too
		exit;
	}
	return $res;
}

# ------------------------------------------------------------------------------
sub die
{
	my $msg = shift;
	if ($openslxConfig{'croak'}) {
		print STDERR "*** ";
		croak $msg;
	} else {
		$msg =~ s[^][*** ]igms;
		chomp $msg;
		print STDERR "$msg\n";
		exit 5 unless ($!);
		exit $!;
	}
}

1;