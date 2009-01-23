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
#    - provides basic functionality of the OpenSLX config-db.
# -----------------------------------------------------------------------------
package OpenSLX::Basics;

use strict;
use warnings;

our (@ISA, @EXPORT, $VERSION);

use Exporter;
$VERSION = 1.01;
@ISA     = qw(Exporter);

@EXPORT = qw(
    &openslxInit %openslxConfig %cmdlineConfig
    &_tr &trInit
    &warn &die &croak &carp &confess &cluck
    &callInSubprocess &executeInSubprocess &slxsystem
    &vlog
    &checkParams
    &instantiateClass
    &addCleanupFunction &removeCleanupFunction
);

our (%openslxConfig, %cmdlineConfig, %openslxPath);

use subs qw(die warn);

use open ':utf8';

################################################################################
### Module implementation
################################################################################
require Carp;        # do not import anything as we are going to overload carp
                    # and croak!
use Carp::Heavy;    # use it here to have it loaded immediately, not at
                    # the time when carp() is being invoked (which might
                    # be at a point in time where the script executes in
                    # a chrooted environment, such that the module can't
                    # be loaded anymore).
use Config::General;
use Encode;
require File::Glob;
use FindBin;
use Getopt::Long;
use POSIX qw(locale_h);

my $translations;

# this hash will hold the active openslx configuration,
# the initial content is based on environment variables or default values.
# Each value may be overridden from config files and/or cmdline arguments.
%openslxConfig = (
    'db-name' => $ENV{SLX_DB_NAME} || 'openslx',
    'db-spec' => $ENV{SLX_DB_SPEC},
    'db-type' => $ENV{SLX_DB_TYPE} || 'SQLite',
    'locale'         => setlocale(LC_MESSAGES),
    'locale-charmap' => `locale charmap`,
    'base-path'      => $ENV{SLX_BASE_PATH} || '/opt/openslx',
    'config-path'    => $ENV{SLX_CONFIG_PATH} || '/etc/opt/openslx',
    'private-path'   => $ENV{SLX_PRIVATE_PATH} || '/var/opt/openslx',
    'public-path'    => $ENV{SLX_PUBLIC_PATH} || '/srv/openslx',
    'temp-path'      => $ENV{SLX_TEMP_PATH} || '/tmp',
    'verbose-level'  => $ENV{SLX_VERBOSE_LEVEL} || '0',

    #
    # options useful during development only:
    #
    'debug-confess' => '0',

    #
    # extended settings follow, which are only supported by slxsettings,
    # but not by any other script:
    #
    'db-user'                            => undef,
    'db-passwd'                          => undef,
    'default-shell'                      => 'bash',
    'default-timezone'                   => 'Europe/Berlin',
    'mirrors-preferred-top-level-domain' => undef,
    'mirrors-to-try-count'               => '20',
    'mirrors-to-use-count'               => '5',
    'ossetup-max-try-count'              => '5',
    'pxe-theme'                          => undef,
    'pxe-theme-menu-margin'              => '9',
);
chomp($openslxConfig{'locale-charmap'});

# specification of cmdline arguments that are shared by all openslx-scripts:
my %openslxCmdlineArgs = (

    # name of database, defaults to 'openslx'
    'db-name=s' => \$cmdlineConfig{'db-name'},

    # full specification of database, a special string defining the
    # precise database to connect to (the contents of this string
    # depend on db-type)
    'db-spec=s' => \$cmdlineConfig{'db-spec'},

    # type of database to connect to (SQLite, mysql, ...), defaults to 'SQLite'
    'db-type=s' => \$cmdlineConfig{'db-type'},

    # activates debug mode, this will show the lines where any error occured
    # (followed by a stacktrace):
    'debug-confess' => \$cmdlineConfig{'debug-confess'},

    # locale to use for translations
    'locale=s' => \$cmdlineConfig{'locale'},

    # locale-charmap to use for I/O (iso-8859-1, utf-8, etc.)
    'locale-charmap=s' => \$cmdlineConfig{'locale-charmap'},

    # file to write logging output to, defaults to STDERR
    'logfile=s' => \$cmdlineConfig{'locale'},

    # path to private data (which is *not* accesible by clients and contains
    # database, vendorOSes and all local extensions [system specific scripts])
    'private-path=s' => \$cmdlineConfig{'private-path'},

    # path to public data (which is accesible by clients and contains
    # PXE-configurations, kernels, initramfs and client configurations)
    'public-path=s' => \$cmdlineConfig{'public-path'},

    # path to temporary data (used during demuxing)
    'temp-path=s' => \$cmdlineConfig{'temp-path'},

    # level of logging verbosity (0-3)
    'verbose-level=i' => \$cmdlineConfig{'verbose-level'},
);

my %cleanupFunctions;

# filehandle used for logging:
my $openslxLog = *STDERR;

$Carp::CarpLevel = 1;

# ------------------------------------------------------------------------------
sub vlog
{
    my $minLevel = shift;
    return if $minLevel > $openslxConfig{'verbose-level'};
    my $str = join("", '-' x $minLevel, @_);
    if (substr($str, -1, 1) ne "\n") {
        $str .= "\n";
    }
    print $openslxLog $str;
    return;
}

# ------------------------------------------------------------------------------
sub openslxInit
{
    # evaluate cmdline arguments:
    Getopt::Long::Configure('no_pass_through');
    GetOptions(%openslxCmdlineArgs);

    # try to read and evaluate config files:
    my $configPath = $cmdlineConfig{'config-path'}
      || $openslxConfig{'config-path'};
    my $sharePath = "$openslxConfig{'base-path'}/share";
    my $verboseLevel = $cmdlineConfig{'verbose-level'} || 0;
    foreach my $f ("$sharePath/settings.default", "$configPath/settings",
        "$ENV{HOME}/.openslx/settings")
    {
        next unless -e $f;
        if ($verboseLevel >= 2) {
            vlog(0, "reading config-file $f...");
        }
        my $configObject = Config::General->new(
            -AutoTrue       => 1, 
            -ConfigFile     => $f, 
            -LowerCaseNames => 1,
            -SplitPolicy    => 'equalsign',
        );
        my %config = $configObject->getall();
        foreach my $key (keys %config) {
            # N.B.: these config files are used by shell-scripts, too, so in
            # order to comply with shell-style, the config files use shell
            # syntax and an uppercase, underline-as-separator format.
            # Internally, we use lowercase, minus-as-separator format, so we
            # need to convert the environment variable names to our own
            # internal style here (e.g. 'SLX_BASE_PATH' to 'base-path'):
            my $ourKey = $key;
            $ourKey =~ s[^slx_][];
            $ourKey =~ tr/_/-/;
            $openslxConfig{$ourKey} = $config{$key};
        }
    }

    # push any cmdline argument into our config hash, possibly overriding any
    # setting from the config files:
    while (my ($key, $val) = each(%cmdlineConfig)) {
        next unless defined $val;
        $openslxConfig{$key} = $val;
    }

    if (defined $openslxConfig{'logfile'}) {
        open($openslxLog, '>>', $openslxConfig{'logfile'})
          or croak(
            _tr(
                "unable to append to logfile '%s'! (%s)",    
                $openslxConfig{'logfile'}, $!
            )
          );
    }
    if ($openslxConfig{'verbose-level'} >= 2) {
        foreach my $key (sort keys %openslxConfig) {
            my $val = $openslxConfig{$key} || '';
            vlog(2, "config-dump: $key = $val");
        }
    }

    # setup translation "engine":
    trInit();

    return 1;
}

# ------------------------------------------------------------------------------
sub trInit
{
    # activate automatic charset conversion on all the standard I/O streams,
    # just to give *some* support to shells in other charsets:
    binmode(STDIN,  ":encoding($openslxConfig{'locale-charmap'})");
    binmode(STDOUT, ":encoding($openslxConfig{'locale-charmap'})");
    binmode(STDERR, ":encoding($openslxConfig{'locale-charmap'})");

    my $locale = $openslxConfig{'locale'};
    if (lc($locale) eq 'c') {
        # treat locale 'c' as equivalent for 'posix':
        $locale = 'posix';
    }

    if (lc($locale) ne 'posix') {
        # parse locale and canonicalize it (e.g. to 'de_DE') and generate
        # two filenames from it (language+country and language only):
        if ($locale !~ m{^\s*([^_]+)(?:_(\w+))?}) {
            die "locale $locale has unknown format!?!";
        }
        my @locales;
        if (defined $2) {
            push @locales, lc($1) . '_' . uc($2);
        }
        push @locales, lc($1);

        # try to load any of the Translation modules (starting with the more
        # specific one [language+country]):
        my $loadedTranslationModule;
        foreach my $trName (@locales) {
            vlog(2,    "trying to load translation module $trName...");
            my $trModule = "OpenSLX/Translations/$trName.pm";
            my $trModuleSpec = "OpenSLX::Translations::$trName";
            if (eval { require $trModule } ) {
                # copy the translations available in the given locale into our 
                # hash:
                $translations = $trModuleSpec->getAllTranslations();
                $loadedTranslationModule = $trModule;
                vlog(
                    1,
                    _tr(
                        "translations module %s loaded successfully", $trModule
                    )
                );
                last;
            }
        }
        if (!defined $loadedTranslationModule) {
            vlog(1,
                "unable to load any translations module for locale '$locale' ($!)."
            );
        }
    }
    return;
}

# ------------------------------------------------------------------------------
sub _tr
{
    my $trOrig = shift;

    my $trKey = $trOrig;
    $trKey =~ s[\n][\\n]g;
    $trKey =~ s[\t][\\t]g;

    my $formatStr;
    if (defined $translations) {
        $formatStr = $translations->{$trKey};
    }
    if (!defined $formatStr) {
        $formatStr = $trOrig;
    }
    return sprintf($formatStr, @_);
}

# ------------------------------------------------------------------------------
sub callInSubprocess
{
    my $childFunc = shift;

    my $pid = fork();
    if (!$pid) {

        # child...
        # ...execute the given function and exit:
        my $ok = eval { $childFunc->(); 1 };
        if (!$ok) {
            print STDERR "*** $@";
            exit 5;
        }
        exit 0;
    }

    # parent...
    # ...pass on interrupt- and terminate-signals to child...
    local $SIG{INT}  = sub { kill 'INT',  $pid; waitpid($pid, 0); exit $? };
    local $SIG{TERM} = sub { kill 'TERM', $pid; waitpid($pid, 0); exit $? };

    # ...and wait for child to do its work:
    waitpid($pid, 0);
    if ($?) {
        exit $?;
    }
    return;
}

# ------------------------------------------------------------------------------
sub executeInSubprocess
{
    my @cmdlineArgs = @_;

    my $pid = fork();
    if (!$pid) {

        # child...
        # ...exec the given cmdline:
        exec(@cmdlineArgs);
    }

    # parent...
    return $pid;
}

# ------------------------------------------------------------------------------
sub addCleanupFunction
{
    my $name = shift;
    my $func = shift;

    $cleanupFunctions{$name} = $func;
    return;
}

# ------------------------------------------------------------------------------
sub removeCleanupFunction
{
    my $name = shift;

    delete $cleanupFunctions{$name};
    return;
}

# ------------------------------------------------------------------------------
sub invokeCleanupFunctions
{
    my @funcNames = keys %cleanupFunctions;
    foreach my $name (@funcNames) {
        vlog(2, "invoking cleanup function '$name'...");
        $cleanupFunctions{$name}->();
    }
    return;
}

# ------------------------------------------------------------------------------
sub slxsystem
{
    vlog(2, _tr("executing: %s", join ' ', @_));
    my $res = system(@_);
    if ($res > 0) {
        # check if child got killed, if so we stop, too (unless the signal is
        # SIGPIPE, which we ignore in order to loop over failed FTP connections
        # and the like):
        my $signalNo = $res & 127;
        if ($signalNo > 0 && $signalNo != 13) {
            die _tr("child-process reveived signal '%s', parent stops!",
                $signalNo);
        }
    }
    return $res;
}

# ------------------------------------------------------------------------------
sub cluck
{
    _doThrowOrWarn('cluck', @_);
    return;
}

# ------------------------------------------------------------------------------
sub carp
{
    _doThrowOrWarn('carp', @_);
    return;
}

# ------------------------------------------------------------------------------
sub warn
{
    _doThrowOrWarn('warn', @_);
    return;
}

# ------------------------------------------------------------------------------
sub confess
{
    invokeCleanupFunctions();
    _doThrowOrWarn('confess', @_);
    return;
}

# ------------------------------------------------------------------------------
sub croak
{
    invokeCleanupFunctions();
    _doThrowOrWarn('croak', @_);
    return;
}

# ------------------------------------------------------------------------------
sub die
{
    invokeCleanupFunctions();
    _doThrowOrWarn('die', @_);
    return;
}

# ------------------------------------------------------------------------------
sub _doThrowOrWarn
{
    my $type = shift;
    my $msg = shift;
    
    # use '°°°' for warnings and '***' for errors
    if ($type eq 'carp' || $type eq 'warn' || $type eq 'cluck') {
        $msg =~ s[^°°° ][]igms;
        $msg =~ s[^][°°° ]igms;
    }
    else {
        $msg =~ s[^\*\*\* ][]igms;
        $msg =~ s[^][*** ]igms;
    }

    if ($openslxConfig{'debug-confess'}) {
        my %functionFor = (
            'carp' => sub { Carp::cluck @_ },
            'cluck' => sub { Carp::cluck @_ },
            'confess' => sub { Carp::confess @_ },
            'croak' => sub { Carp::confess @_ },
            'die' => sub { Carp::confess @_ },
            'warn' => sub { Carp::cluck @_ },
        );
        my $func = $functionFor{$type};
        $func->($msg);
    }
    else {
        chomp $msg;
        my %functionFor = (
            'carp' => sub { Carp::carp @_ },
            'cluck' => sub { Carp::cluck @_ },
            'confess' => sub { Carp::confess @_ },
            'croak' => sub { Carp::croak @_ },
            'die' => sub { CORE::die @_},
            'warn' => sub { CORE::warn @_ },
        );
        my $func = $functionFor{$type};
        $func->("$msg\n");
    }
    return;
}

=item checkParams()

Utility function that can be used by any method that accepts param-hashes
to check if the given parameters actually match the expectations.

Each individual parameter has a specification that describes the expectation
that the calling function has towards this param. The following specifications
are supported:

* '!'          - the parameter is required
* '?'          - the parameter is optional
* 'm{regex}'   - the parameter must match the given regex
* '!class=...' - the parameter is required and must be an object of the given class
* '?class=...' - if the parameter has been given, it must be an object of the given class

The function will confess for any unknown, missing, or non-matching param.

If accepted as useful, this function could be moved to a utility module of
the framework in order to be available to all other OTRS-modules.

=cut

sub checkParams
{
    my $params     = shift or confess('need to pass in params-hashref!');
    my $paramsSpec = shift or confess('need to pass in params-spec-hashref!');

    # print a warning for any unknown parameters that have been given:
    my @unknownParams
        =   grep { !exists $paramsSpec->{$_}; }
            keys %$params;
    if (@unknownParams) {
        my $unknownParamsStr = join ',', @unknownParams;
        confess("Enocuntered unknown params: '$unknownParamsStr'!\n");
    }

    # check if all required params have been specified:
    foreach my $param (keys %$paramsSpec) {
        my $spec = $paramsSpec->{$param};
        if (ref($spec) eq 'HASH') {
            # Handle nested specs by recursion:
            my $subParams = $params->{$param};
            if (!defined $subParams) {
                confess("Required param '$param' is missing!");
            }
            checkParams($subParams, $spec);
        }
        elsif (ref($spec) eq 'ARRAY') {
            # Handle nested spec arrays by looped recursion:
            my $subParams = $params->{$param};
            if (!defined $subParams) {
                confess("Required param '$param' is missing!");
            }
            elsif (ref($subParams) ne 'ARRAY') {
                confess("Value for param '$param' must be an array-ref!");
            }
            foreach my $subParam (@$subParams) {
                checkParams($subParam, $spec->[0]);
            }
        }
        elsif ($spec eq '!') {
            # required parameter:
            if (!exists $params->{$param}) {
                confess("Required param '$param' is missing!");
            }
        }
        elsif ($spec =~ m{^\!class=(.+)$}i) {
            my $class = $1;
            # required parameter ...
            if (!exists $params->{$param}) {
                confess("Required param '$param' is missing!");
            }
            # ... of specific class
            if (!$params->{$param}->isa($class)) {
                confess("Param '$param' is not a '$class', but that is required!");
            }
        }
        elsif ($spec eq '?') {
            # optional parameter - nothing to do
        }
        elsif ($spec =~ m{^\?class=(.+)$}i) {
            my $class = $1;
            # optional parameter ...
            if (exists $params->{$param}) {
                # ... has been given, so it must match specific class
                if (!$params->{$param}->isa($class)) {
                    confess("Param '$param' is not a '$class', but that is required!");
                }
            }
        }
        elsif ($spec =~ m{^m{(.+)}$}) {
            # try to match given regex:
            my $regex = $1;
            my $value = $params->{$param};
            if ($value !~ m{$regex}) {
                confess("Required param '$param' isn't matching regex '$regex' (given value was '$value')!");
            }
        }
        else {
            # complain about unknown spec:
            confess("Unknown param-spec '$spec' encountered!");
        }
    }

    return scalar 1;
}

# ------------------------------------------------------------------------------
sub instantiateClass
{
    my $class = shift;
    my $flags = shift || {};

    checkParams($flags, { 
        'pathToClass' => '?', 
        'version'     => '?' 
    });
    my $pathToClass      = $flags->{pathToClass};
    my $requestedVersion = $flags->{version};

    my $moduleName = defined $pathToClass ? "$pathToClass/$class" : $class;
    $moduleName =~ s[::][/]g;
    $moduleName .= '.pm';
    unless (eval { require $moduleName } ) {
        if ($! == 2) {
            die _tr("Module '%s' not found!\n", $moduleName);
        }
        else {
            die _tr("Unable to load module '%s' (%s)\n", $moduleName, $@);
        }
    }
    if (defined $requestedVersion) {
        my $classVersion = $class->VERSION;
        if ($classVersion < $requestedVersion) {
            die _tr(
                'Could not load class <%s> (Version <%s> required, but <%s> found)',
                $class, $requestedVersion, $classVersion);
        }
    }
    return $class->new;
}

1;
