#! /usr/bin/perl

# add the folder this script lives in to perl's search path for modules:
use FindBin;
use lib $FindBin::Bin;

use OpenSLX::Basics;

use Getopt::Long qw(:config pass_through);
use Pod::Usage;

my (
	$noShow,
	$quiet,
	@remove,
	$helpReq,
	$manReq,
	$versionReq,
);

GetOptions(
	'noshow' => \$noshow,
		# will display current configuration
	'quiet' => \$quiet,
		# will avoid printing anything
	'remove=s' => \@remove,
		# will avoid printing anything

	'help|?' => \$helpReq,
	'man' => \$manReq,
	'version' => \$versionReq,
);
pod2usage(1) if $helpReq;
pod2usage(-verbose => 2) if $manReq;
if ($versionReq) {
	system('slxversion');
	exit 1;
}

openslxInit() or pod2usage(2);

# fetch current content of local settings file...
open(SETTINGS, "< $openslxConfig{'config-path'}/settings.local");
$/ = undef;
my $settings = <SETTINGS>;
close(SETTINGS);

my $changeCount;

# ...set new values...
foreach my $key (sort keys %cmdlineConfig) {
	next if $key eq 'config-path';
		# config-path can't be changed, it is used to find settings.local
	my $value = $cmdlineConfig{$key};
	next if !defined $value;
	vlog 0, _tr('setting %s to <%s>', $key, $value) unless $quiet;
	$key =~ tr[-][_];
	my $externalKey = "SLX_".uc($key);
	if (!($settings =~ s[^\s*$externalKey=.*?$][$externalKey=$value]ms)) {
		$settings .= "$externalKey=$value\n";
	}
	$changeCount++;
}

# ...remove any keys we should do away with...
foreach my $key (@remove) {
	if (!exists $cmdlineConfig{$key}) {
		vlog 0, _tr('ignoring unknown key <%s>', $key);
		next;
	}
	vlog 0, _tr('removing %s', $key) unless $quiet;
	$key =~ tr[-][_];
	my $externalKey = "SLX_".uc($key);
	$settings =~ s[^\s*$externalKey=.*?$][]ms;
	$changeCount++;
}

# ... and write local settings file if necessary
if ($changeCount) {
	my $f = "$openslxConfig{'config-path'}/settings.local";
	open(SETTINGS, "> $f")
		or die _tr('Unable to write local settings file <%s> (%s)', $f, $!);
	print SETTINGS $settings;
	close(SETTINGS);
}

if (!($noshow || $quiet)) {
	print "\n"._tr("resulting settings:")."\n";
	foreach my $key (sort keys %openslxConfig) {
		print "\t$key=$openslxConfig{$key}\n";
	}
}

__END__

=head1 NAME

slxsetup.pl - OpenSLX-script to show & change local settings

=head1 SYNOPSIS

slxsetup.pl [options]

  Script Options:
      --noshow            do not print resulting settings
      --quiet             do not print anything
      --remove=s          remove given key from settings

  OpenSLX Options:
      --base-path=s       basic path to project files
      --bin-path=s        path to binaries and scripts
      --config-path=s     path to configuration files
      --db-basepath=s     basic path to openslx database
      --db-datadir=s      data folder created under db-basepath
      --db-name=s         name of database
      --db-spec=s         full DBI-specification of database
      --db-type=s         type of database to connect to
      --export-path=s     path to root of all exported filesystems
      --locale=s          locale to use for translations
      --logfile=s         file to write logging output to
      --private-path=s    path to private data
      --public-path=s     path to public (client-accesible) data
      --share-path=s      path to sharable data
      --temp-path=s       path to temporary data
      --tftpboot-path=s   path to root of tftp-server
      --verbose-level=i   level of logging verbosity (0-3)

  General Options:
      --help              brief help message
      --man               full documentation
      --version           show version

=head1 OPTIONS

=head3 Script Options

=over 8

=item B<--noshow>

Avoids printing the resulting settings after any changes have been applied.

=item B<--quiet>

Runs the script without printing anything.

=item B<--remove=s>

Removes key B<s> from settings (apply more than once to remove several keys).

=back

=head3 OpenSLX Options

=over 8

=item B<--base-path=s>

Sets basic path to project files.

Default is $SLX_BASE_PATH (usually F</opt/openslx>).

=item B<--bin-path=s>

Sets path to binaries and scripts.

Default is $SLX_BASE_PATH/bin (usually F</opt/openslx/bin>).

=item B<--config-path=s>

Sets path to configuration files.

Default is $SLX_CONFIG_PATH (usually F</etc/opt/openslx>).

=item B<--db-basepath=s>

Sets basic path to openslx database.

Default is $SLX_DB_PATH (usually F</var/opt/openslx/db>).

=item B<--db-datadir=s>

Sets data folder created under db-basepath.

Default is $SLX_DB_DATADIR (usually empty as it depends on db-type
whether or not such a directory is required at all).

=item B<--db-name=s>

Gives the name of the database to connect to.

Default is $SLX_DB_NAME (usually C<openslx>).

=item B<--db-spec=s>

Gives the full DBI-specification of database to connect to. Content depends
on the db-type.

Default is $SLX_DB_SPEC (usually empty as it will be built automatically).

=item B<--db-type=s>

Sets the type of database to connect to (CSV, SQLite, mysql, ...).

Default $SLX_DB_TYPE (usually C<CSV>).

=item B<--export-path=s>

Sets path to root of all exported filesystems. For each type of export (NFS,
NBD, ...) a separate folder will be created in here.

Default is $SLX_EXPORT_PATH (usually F</srv/openslx/export>.

=item B<--locale=s>

Sets the locale to use for translations.

Defaults to the system's standard locale.

=item B<--logfile=s>

Specifies a file where logging output will be written to.

Default is to log to STDERR.

=item B<--private-path=s>

Sets path to private data, where the config-db, vendor_oses and configurational
extensions will be stored.

Default is $SLX_PRIVATE_PATH (usually F</var/opt/openslx>.

=item B<--public-path=s>

Sets path to public (client-accesible) data.

Default is $SLX_PUBLIC_PATH (usually F</srv/openslx>.

=item B<--share-path=s>

Sets path to sharable data, where distro-specs and functionality templates
will be stored.

Default is $SLX_SHARE_PATH (usually F</opt/openslx/share>.

=item B<--temp-path=s>

Sets path to temporary data.

Default is $SLX_TEMP_PATH (usually F</tmp>.

=item B<--tftpboot-path=s>

Sets path to root of tftp-server from which clients will access their files.

Default is $SLX_TFTPBOOT_PATH (usually F</srv/openslx/tftpboot>.

=item B<--verbose-level=i>

Sets the level of logging verbosity (0-3).

Default is $SLX_VERBOSE_LEVEL (usually 0, no logging).

=back

=head3 General Options

=over 8

=item B<--help>

Prints a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=item B<--version>

Prints the version and exits.

=back

=head1 DESCRIPTION

B<slxsetup.pl> can be used to show or change the local settings for OpenSLX.

Any cmdline-argument passed to this script will change the local OpenSLX
settings file (usually /etc/opt/openslx/settings.local).

If you invoke the script without any arguments, it will print the current
settings and exit.
