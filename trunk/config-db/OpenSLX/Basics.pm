package OpenSLX::Basics;

use strict;
use vars qw(@ISA @EXPORT $VERSION);

use Exporter;
$VERSION = 0.02;
@ISA = qw(Exporter);

@EXPORT = qw(
	&openslxInit %openslxConfig
	&_tr &trInit
	&vlog
);

use vars qw(%openslxConfig);

################################################################################
### Module implementation
################################################################################
use Carp;
use FindBin;
use Getopt::Long;

my %translations;
my $loadedTranslationModule;

# this hash will hold the active openslx configuration,
# it is populated from config files and/or cmdline arguments:
%openslxConfig = (
	'db-name' => 'openslx',
	'db-type' => 'CSV',
	'locale' => $ENV{LANG},
		# TODO: may need to be improved in order to be portable
	'base-path' => $ENV{SLX_BASE_PATH} || '/opt/openslx',
	'config-path' => $ENV{SLX_CONFIG_PATH} || '/etc/opt/openslx',
	'private-path' => $ENV{SLX_PRIVATE_PATH} || '/var/opt/openslx',
	'public-path' => $ENV{SLX_PUBLIC_PATH} || '/srv/openslx',
	'temp-path' => $ENV{SLX_TEMP_BASE_PATH} || '/tmp',
);
$openslxConfig{'bin-path'} = "$openslxConfig{'base-path'}/bin",
$openslxConfig{'db-basepath'} = "$openslxConfig{'private-path'}/db",
$openslxConfig{'share-path'} = "$openslxConfig{'base-path'}/share",
$openslxConfig{'tftpboot-path'} = "$openslxConfig{'public-path'}/tftpboot",

# specification of cmdline arguments that are shared by all openslx-scripts:
my %cmdlineConfig;
my %openslxCmdlineArgs = (
	'db-basepath=s' => \$cmdlineConfig{'db-basepath'},
		# basic path to openslx database, defaults to "${private-path}/db"
	'db-datadir=s' => \$cmdlineConfig{'db-datadir'},
		# data folder created under db-basepath, default depends on db-type
	'db-spec=s' => \$cmdlineConfig{'db-spec'},
		# full specification of database, a special string defining the
		# precise database to connect to (the contents of this string
		# depend on db-type)
	'db-name=s' => \$cmdlineConfig{'db-name'},
		# name of database, defaults to 'openslx'
	'db-type=s' => \$cmdlineConfig{'db-type'},
		# type of database to connect to (CSV, SQLite, ...), defaults to 'CSV'
	'locale=s' => \$cmdlineConfig{'locale'},
		# locale to use for translations
	'logfile=s' => \$cmdlineConfig{'locale'},
		# file to write logging output to, defaults to STDERR
	'bin-path=s' => \$cmdlineConfig{'bin-path'},
		# path to binaries and scripts
	'config-path=s' => \$cmdlineConfig{'config-path'},
		# path to configuration files
	'base-path=s' => \$cmdlineConfig{'base-path'},
		# basic path to project files (binaries, functionality templates and
		# distro-specs)
	'private-path=s' => \$cmdlineConfig{'private-path'},
		# path to private data (which is accessible for clients and
		# contains all data required for booting the clients)
	'public-path=s' => \$cmdlineConfig{'public-path'},
		# path to public data (which contains database, vendorOSes
		# and all local extensions [system specific scripts])
	'share-path=s' => \$cmdlineConfig{'share-path'},
		# path to sharable data (functionality templates and distro-specs)
	'temp-basepath=s' => \$cmdlineConfig{'temp-basepath'},
		# basic path to temporary data (used during demuxing)
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
	print $openslxLog '-'x$minLevel, @_, "\n";
}

# ------------------------------------------------------------------------------
sub openslxInit
{
	# evaluate cmdline arguments:
	GetOptions(%openslxCmdlineArgs);

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
			vlog 2, "dump-config: $k = $openslxConfig{$k}";
		}
	}

	# setup translation "engine":
	trInit();
}

# ------------------------------------------------------------------------------
sub trInit
{
	my $locale = $openslxConfig{'locale'};
	$locale =~ tr[A-Z.\-][a-z__];

	my $trModule = "OpenSLX::Translations::$locale";
	if ($loadedTranslationModule eq $trModule) {
		# requested translations have already been loaded
		return;
	}

	# load Posix-Translations first in order to fall back to English strings
	# if a specific translation isn't available:
	if (eval "require OpenSLX::Translations::posix") {
		%translations = %OpenSLX::Translations::posix::translations;
	} else {
		carp "Unable to load translations module 'posix' ($!).";
	}

	if ($locale ne 'posix') {
		if (eval "require $trModule") {
			# Access OpenSLX::Translations::$locale::%translations
			# via a symbolic reference...
			no strict 'refs';
			my $translationsRef	= \%{"${trModule}::translations"};
			# ...and copy the available translations into our hash:
			foreach my $k (keys %{$translationsRef}) {
				$translations{$k} = $translationsRef->{$k};
			}
			$loadedTranslationModule = $trModule;
		} else {
			carp "Unable to load translations module '$locale' ($!).";
		}
	}

}

# ------------------------------------------------------------------------------
sub _tr
{
	my $trKey = shift;

	my $formatStr = $translations{$trKey};
	if (!defined $formatStr) {
#		carp "Translation key '$trKey' not found.";
		$formatStr = $trKey;
	}
	return sprintf($formatStr, @_);
}

1;