package ODLX::Basics;

use strict;
use vars qw(@ISA @EXPORT $VERSION);

use Exporter;
$VERSION = 0.02;
@ISA = qw(Exporter);

@EXPORT = qw(
	&odlxInit %odlxConfig
	&_tr &trInit
	&vlog
);

use vars qw(%odlxConfig);

################################################################################
### Module implementation
################################################################################
use Carp;
use FindBin;
use Getopt::Long;

my %translations;
my $loadedTranslationModule;

# this hash will hold the active odlx configuration,
# it is populated from config files and/or cmdline arguments:
%odlxConfig = (
	'db-name' => 'odlx',
	'db-type' => 'CSV',
	'locale' => $ENV{LANG},
		# TODO: may need to be improved in order to be portable
	'private-basepath' => '/var/lib/openslx',
	'public-basepath' => '/srv/openslx',
	'shared-basepath' => '/usr/share/openslx',
	'temp-basepath' => '/tmp',
);
$odlxConfig{'db-basepath'} = "$odlxConfig{'private-basepath'}/db",

# specification of cmdline arguments that are shared by all odlx-scripts:
my %odlxCmdlineArgs = (
	'db-basepath=s' => \$odlxConfig{'db-basepath'},
		# basic path to odlx database, defaults to "$private-basepath/db"
	'db-datadir=s' => \$odlxConfig{'db-datadir'},
		# data folder created under db-basepath, default depends on db-type
	'db-spec=s' => \$odlxConfig{'db-spec'},
		# full specification of database, a special string defining the
		# precise database to connect to (the contents of this string
		# depend on db-type)
	'db-name=s' => \$odlxConfig{'db-name'},
		# name of database, defaults to 'odlx'
	'db-type=s' => \$odlxConfig{'db-type'},
		# type of database to connect to (CSV, SQLite, ...), defaults to 'CSV'
	'locale=s' => \$odlxConfig{'locale'},
		# locale to use for translations
	'logfile=s' => \$odlxConfig{'locale'},
		# file to write logging output to, defaults to STDERR
	'private-basepath=s' => \$odlxConfig{'private-basepath'},
		# basic path to private data (which is accessible for clients and
		# contains all data required for booting the clients)
	'public-basepath=s' => \$odlxConfig{'public-basepath'},
		# basic path to public data (which contains database, vendorOSes
		# and all local extensions [system specific scripts])
	'shared-basepath=s' => \$odlxConfig{'shared-basepath'},
		# basic path to shared data (functionality templates and distro-specs)
	'temp-basepath=s' => \$odlxConfig{'temp-basepath'},
		# basic path to temporary data (used during demuxing)
	'verbose-level=i' => \$odlxConfig{'verbose-level'},
		# level of logging verbosity (0-3)
);

# filehandle used for logging:
my $odlxLog = *STDERR;

# ------------------------------------------------------------------------------
sub vlog
{
	my $minLevel = shift;
	return if $minLevel > $odlxConfig{'verbose-level'};
	print $odlxLog '-'x$minLevel, @_, "\n";
}

# ------------------------------------------------------------------------------
sub odlxInit
{
	# try to read and evaluate config files:
	foreach my $f ("ODLX/odlxrc", "$ENV{HOME}/.odlxrc") {
		next unless open(CONFIG, "<$f");
		while(<CONFIG>) {
			chomp;
			s/#.*//;
			s/^\s+//;
			s/\s+$//;
			next unless length;
			my ($key, $value) = split(/\s*=\s*/, $_, 2);
			$odlxConfig{$key} = $value;
		}
		close CONFIG;
	}

	# push any cmdline argument directly into our config hash:
	GetOptions(%odlxCmdlineArgs);

	if (defined $odlxConfig{'logfile'}
	&& open(LOG, ">>$odlxConfig{'logfile'}")) {
		$odlxLog
	}
	if ($odlxConfig{'verbose-level'} >= 2) {
		foreach my $k (sort keys %odlxConfig) {
			vlog 2, "dump-config: $k = $odlxConfig{$k}";
		}
	}

	# setup translation "engine":
	trInit();
}

# ------------------------------------------------------------------------------
sub trInit
{
	my $locale = $odlxConfig{'locale'};
	$locale =~ tr[A-Z.\-][a-z__];

	my $trModule = "ODLX::Translations::$locale";
	if ($loadedTranslationModule eq $trModule) {
		# requested translations have already been loaded
		return;
	}

	# load Posix-Translations first in order to fall back to English strings
	# if a specific translation isn't available:
	if (eval "require ODLX::Translations::posix") {
		%translations = %ODLX::Translations::posix::translations;
	} else {
		carp "Unable to load translations module 'posix' ($!).";
	}

	if ($locale ne 'posix') {
		if (eval "require $trModule") {
			# Access ODLX::Translations::$locale::%translations
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