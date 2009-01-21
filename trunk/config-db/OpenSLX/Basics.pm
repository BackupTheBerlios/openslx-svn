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
	'private-basepath' => '/var/lib/openslx',
	'public-basepath' => '/srv/openslx',
	'shared-basepath' => '/usr/share/openslx',
	'temp-basepath' => '/tmp',
);
$openslxConfig{'db-basepath'} = "$openslxConfig{'private-basepath'}/db",

# specification of cmdline arguments that are shared by all openslx-scripts:
my %openslxCmdlineArgs = (
	'db-basepath=s' => \$openslxConfig{'db-basepath'},
		# basic path to openslx database, defaults to "$private-basepath/db"
	'db-datadir=s' => \$openslxConfig{'db-datadir'},
		# data folder created under db-basepath, default depends on db-type
	'db-spec=s' => \$openslxConfig{'db-spec'},
		# full specification of database, a special string defining the
		# precise database to connect to (the contents of this string
		# depend on db-type)
	'db-name=s' => \$openslxConfig{'db-name'},
		# name of database, defaults to 'openslx'
	'db-type=s' => \$openslxConfig{'db-type'},
		# type of database to connect to (CSV, SQLite, ...), defaults to 'CSV'
	'locale=s' => \$openslxConfig{'locale'},
		# locale to use for translations
	'logfile=s' => \$openslxConfig{'locale'},
		# file to write logging output to, defaults to STDERR
	'private-basepath=s' => \$openslxConfig{'private-basepath'},
		# basic path to private data (which is accessible for clients and
		# contains all data required for booting the clients)
	'public-basepath=s' => \$openslxConfig{'public-basepath'},
		# basic path to public data (which contains database, vendorOSes
		# and all local extensions [system specific scripts])
	'shared-basepath=s' => \$openslxConfig{'shared-basepath'},
		# basic path to shared data (functionality templates and distro-specs)
	'temp-basepath=s' => \$openslxConfig{'temp-basepath'},
		# basic path to temporary data (used during demuxing)
	'verbose-level=i' => \$openslxConfig{'verbose-level'},
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
	# try to read and evaluate config files:
	foreach my $f ("/etc/openslx/settings.default",
				   "/etc/openslx/settings.local",
				   "$ENV{HOME}/.openslx/settings") {
		next unless open(CONFIG, "<$f");
		while(<CONFIG>) {
			chomp;
			s/#.*//;
			s/^\s+//;
			s/\s+$//;
			next unless length;
			my ($key, $value) = split(/\s*=\s*/, $_, 2);
			$openslxConfig{$key} = $value;
		}
		close CONFIG;
	}

	# push any cmdline argument directly into our config hash:
	GetOptions(%openslxCmdlineArgs);

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