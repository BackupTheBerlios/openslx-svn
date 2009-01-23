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
package OpenSLX::Basics;

use strict;
use warnings;

our (@ISA, @EXPORT, $VERSION);

use Exporter;
$VERSION = 1.01;
@ISA     = qw(Exporter);

@EXPORT = qw(
    &openslxInit %openslxConfig %cmdlineConfig
    &_tr
    &warn &die &croak &carp &confess &cluck
    &callInSubprocess &executeInSubprocess &slxsystem
    &vlog
    &checkParams
    &instantiateClass &loadDistroModule
);

=head1 NAME

OpenSLX::Basics - implements basic functionality for OpenSLX.

=head1 DESCRIPTION

This module exports basic functions, which are expected to be used all across
OpenSLX.

=cut

our (%openslxConfig, %cmdlineConfig, %openslxPath);

use subs qw(die warn);

use open ':utf8';

require Carp;       # do not import anything as we are going to overload carp
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

=head1 PUBLIC VARIABLES

=over

=item B<%openslxConfig>

This hash holds the active openslx configuration. 

The initial content is based on environment variables or default values. Calling
C<openslxInit()> will read the configuration files and/or cmdline arguments
and modify this hash accordingly.

The individual entries of this hash are documented in the manual of the
I<slxsettings>-script, so please look there if you'd like to know more.

=cut

%openslxConfig = (
    'db-name' => $ENV{SLX_DB_NAME} || 'openslx',
    'db-spec' => $ENV{SLX_DB_SPEC},
    'db-type' => $ENV{SLX_DB_TYPE} || 'SQLite',
    'locale'         => setlocale(LC_MESSAGES),
    'locale-charmap' => `locale charmap`,
    'base-path'      => $ENV{SLX_BASE_PATH} || '/opt/openslx',
    'config-path'    => $ENV{SLX_CONFIG_PATH} || '/etc/opt/openslx',
    'log-level'      => $ENV{SLX_VERBOSE_LEVEL} || '0',
    'private-path'   => $ENV{SLX_PRIVATE_PATH} || '/var/opt/openslx',
    'public-path'    => $ENV{SLX_PUBLIC_PATH} || '/srv/openslx',
    'temp-path'      => $ENV{SLX_TEMP_PATH} || '/tmp',

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

=item B<%cmdlineConfig>

This hash holds the config items that were specified via cmdline. This can be
useful if you need to find out which settings have been specified via cmdline
and which ones have come from a config file.

Currently, only the slxsettings script and some tests make use of this hash.

=cut

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

    # level of logging verbosity (0-3)
    'log-level=i' => \$cmdlineConfig{'log-level'},

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
);

# filehandle used for logging:
my $openslxLog = *STDERR;

$Carp::CarpLevel = 1;

=back

=head1 PUBLIC FUNCTIONS

=over

=item B<openslxInit()>

Initializes OpenSLX environment - every script should invoke this function
before it invokes any other.

Basically, this function reads in the configuration and sets up logging
and translation backends.

Returns 1 upon success and dies in case of a problem.

=cut

sub openslxInit
{
    # evaluate cmdline arguments:
    Getopt::Long::Configure('no_pass_through');
    GetOptions(%openslxCmdlineArgs);

    # try to read and evaluate config files:
    my $configPath 
        = $cmdlineConfig{'config-path'} || $openslxConfig{'config-path'};
    my $sharePath = "$openslxConfig{'base-path'}/share";
    my $verboseLevel = $cmdlineConfig{'log-level'} || 0;
    foreach my $f (
        "$sharePath/settings.default", 
        "$configPath/settings",
        "$ENV{HOME}/.openslx/settings"
    ) {
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
    if ($openslxConfig{'log-level'} >= 2) {
        foreach my $key (sort keys %openslxConfig) {
            my $val = $openslxConfig{$key} || '';
            vlog(2, "config-dump: $key = $val");
        }
    }

    # setup translation "engine":
    _trInit();

    return 1;
}

=item B<vlog($level, $message)>

Logs the given I<$message> if the current log level is equal or greater than
the given I<$level>.

=cut

sub vlog
{
    my $minLevel = shift;
    return if $minLevel > $openslxConfig{'log-level'};
    my $str = join("", '-' x $minLevel, @_);
    if (substr($str, -1, 1) ne "\n") {
        $str .= "\n";
    }
    print $openslxLog $str;
    return;
}

=item B<_tr($originalMsg, @msgParams)>

Translates the english text given in I<$originalMsg> to the currently selected
language, passing on any given additional I<$msgParams> to the translation
process (as printf arguments).

N.B.: although it starts with an underscore, this is still a public function!

=cut

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

=item B<callInSubprocess($childFunc)>

Forks the current process and invokes the code given in I<$childFunc> in the
child process. The parent blocks until the child has executed that function.

If an error occured during execution of I<$childFunc>, the parent process will
cleanup the child and then pass back that error with an invocation of die().

If the process of executing I<$childFunc> is being interrupted by a signal,
the parent will cleanup and then exit with an appropriate exit code.

=cut

sub callInSubprocess
{
    my $childFunc = shift;

    my $pid = fork();
    if (!$pid) {
        # child -> execute the given function and exit:
        eval { $childFunc->(); 1 }
            or die $@;
        exit 0;
    }

    # parent -> pass on interrupt- and terminate-signals to child ...
    $SIG{INT}  = sub { kill 'INT',  $pid; };
    $SIG{TERM} = sub { kill 'TERM', $pid; };

    # ... and wait until child has done its work
    waitpid($pid, 0);
    exit $? if $?;

    return;
}

=item B<executeInSubprocess(@cmdlineArgs)>

Forks the current process and executes the program given in I<@cmdlineArgs> in 
the child process. 

The parent process returns immediately after having spawned the new process, 
returning the process-ID of the child.

=cut

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

=item B<slxsystem(@cmdlineArgs)>

Executes a new program specified by I<@cmdlineArgs> and waits until it is done.

Returns the exit code of the execution (usually 0 if everything is ok).

If any signal (other than SIGPIPE) interrupts the execution, this function
dies with an appropriate error message. SIGPIPE is being ignored in order
to ignore any failed FTP connections and the like (we just return the
error code instead).

=cut

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
            die _tr(
                "child-process received signal '%s', parent stops!", $signalNo
            );
        }
    }
    return $res;
}

=item B<cluck()>, B<carp()>, B<warn()>, B<confess()>, B<croak()>, B<die()>

Overrides of the respective functions in I<Carp::> or I<CORE::> that mark
any warnings with '°°°' and any errors with '***' in order to make them
more visible in the output.

=cut

sub cluck
{
    _doThrowOrWarn('cluck', @_);
    return;
}

sub carp
{
    _doThrowOrWarn('carp', @_);
    return;
}

sub warn
{
    _doThrowOrWarn('warn', @_);
    return;
}

sub confess
{
    _doThrowOrWarn('confess', @_);
    return;
}

sub croak
{
    _doThrowOrWarn('croak', @_);
    return;
}

sub die
{
    _doThrowOrWarn('die', @_);
    return;
}

=item B<checkParams($params, $paramsSpec)>

Utility function that can be used by any function that accepts param-hashes
to check if the parameters given in I<$params> actually match the expectations
specified in I<$paramsSpec>.

Each individual parameter has a specification that describes the expectation
that the calling function has towards this param. The following specifications
are supported:

* '!'          - the parameter is required
* '?'          - the parameter is optional
* 'm{regex}'   - the parameter must match the given regex
* '!class=...' - the parameter is required and must be an object of the given class
* '?class=...' - if the parameter has been given, it must be an object of the given class

The function will confess for any unknown, missing, or non-matching param.

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

=item B<instantiateClass($class, $flags)>

Loads the required module and instantiates an object of the class given in 
I<$class>.

The following flags can be specified via I<$flags>-hashref:

=over

=item acceptMissing   [optional]

Usually, this function will die if the corresponding module could not be found
(acceptMissing == 0). Pass in acceptMissing => 1 if you want this function
to return undef instead.

=item pathToClass   [optional]

Sometimes, the module specified in I<$class> lives relative to another path.
If so, you can specify the base path of that module via this flag.

=item incPaths   [optional]

Some modules live outside of the standard perl search paths. If you'd like to
load such a module, you can specify one (or more) paths that will be added
to @INC while trying to load the module.

=item version   [optional]

If you require a specific version of the module, you can specify the version
number via the I<$version> flag.

=back

=cut

sub instantiateClass
{
    my $class = shift;
    my $flags = shift || {};

    checkParams($flags, { 
        'acceptMissing' => '?',
        'pathToClass'   => '?',
        'incPaths'      => '?',
        'version'       => '?',
    });
    my $pathToClass      = $flags->{pathToClass};
    my $requestedVersion = $flags->{version};
    my $incPaths         = $flags->{incPaths} || [];

    my $moduleName = defined $pathToClass ? "$pathToClass/$class" : $class;
    $moduleName =~ s[::][/]g;
    $moduleName .= '.pm';

    vlog(3, "trying to load $moduleName...");
    my @originalINC = @INC;
    if (!eval { unshift @INC, @$incPaths; require $moduleName; 1 } ) {
        @INC = @originalINC;
        # check if module does not exists anywhere in search path
        if (!-e $moduleName) {
            return if $flags->{acceptMissing};
            die _tr("Module '%s' not found!\n", $moduleName);
        }
        # some other error (probably compilation problems)
        die _tr("Unable to load module '%s' (%s)\n", $moduleName, $@);
    }
    @INC = @originalINC;
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

=item B<loadDistroModule($params)>

Tries to determine the most appropriate distro module for the context specified
via the given I<$params>.

During that process, this function will try to load several different modules,
working its way from the most specific down to a generic fallback. 

For example: when given I<suse-10.3_x86_64> as distroName, this function would 
try the following modules:

=over

=item I<Suse_10_3_x86_64>

=item I<Suse_10_3>

=item I<Suse_10>

=item I<Suse>

=item I<Base>                    (or whatever has been given as fallback name)

=back

The I<$params>-hashref supports the following entries:

=over

=item distroName

Specifies the name of the distro as it was retrieved from the vendor-OS
(e.g. 'suse-10.2' or 'ubuntu-8.04_amd64').

=item distroScope

Specifies the scope of the required distro class (e.g. 
'OpenSLX::OSSetup::Distro' or 'vmware::OpenSLX::Distro').

=item fallbackName   [optional]

Instead of the default 'Base', you can specify the name of a different fallback
class that will be tried if no module matching the given distro name could be
found.

=item pathToClass   [optional]

If you require the distro modules to be loaded relative to a specific path,
you can specify that base path via the I<$pathToClass> param.

=back

=cut


sub loadDistroModule
{
    my $params = shift;
    
    checkParams($params, {
        'distroName'   => '!',
        'distroScope'  => '!',
        'fallbackName' => '?',
        'pathToClass'  => '?',
    });
    my $distroName   = ucfirst(lc($params->{distroName}));
    my $distroScope  = $params->{distroScope};
    my $fallbackName = $params->{fallbackName} || 'Base';
    my $pathToClass  = $params->{pathToClass};
    
    vlog(1, "finding a ${distroScope} module for $distroName ...");

    # try to load the distro module starting with the given name and then
    # working the way upwards (from most specific to generic).
    $distroName =~ tr{.-}{__};
    my @distroModules;
    my $blockRX = qr{
        ^(.+?)_     # everything before the last block (the rest is dropped)
        (?:x86_)?   # takes care to treat 'x86_64' as one block
        [^_]*$      # the last _-block
    }x;
    while($distroName =~ m{$blockRX}) {
        push @distroModules, $distroName;
        $distroName = $1;
    }
    push @distroModules, $distroName;
    push @distroModules, $fallbackName;

    my $pluginBasePath = "$openslxConfig{'base-path'}/lib/plugins";

    my $distro;
    for my $distroModule (@distroModules) {
        my $loaded = eval {
            vlog(1, "trying ${distroScope}::$distroModule ...");
            my $flags = { acceptMissing => 1 };
            if ($pathToClass) {
                $flags->{pathToClass} = $pathToClass;
                $flags->{incPaths}    = [ $pathToClass ];
            }
            $distro = instantiateClass("${distroScope}::$distroModule", $flags);
            return 0 if !$distro;   # module does not exist, try next
            vlog(1, "ok - using ${distroScope}::$distroModule.");
            1;
        };
        last if $loaded;
        if (!defined $loaded) {
            vlog(0, _tr(
                "Error when trying to load distro module '%s':\n%s", 
                $distroModule, $@
            ));
        }
    }

    return $distro;
}

sub _trInit
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

sub _doThrowOrWarn
{
    my $type = shift;
    my $msg = shift;
    
    # use '°°°' for warnings and '***' for errors
    if ($type eq 'carp' || $type eq 'warn' || $type eq 'cluck') {
        $msg =~ s[^!   ][]igms;
        $msg =~ s[^][!   ]igms;
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

=back

=cut

1;
