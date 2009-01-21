#! /usr/bin/perl

# add the lib-folder and the folder this script lives in to perl's search
# path for modules:
use FindBin;
use lib "$FindBin::RealBin/../lib";
	# production path
use lib "$FindBin::RealBin";
	# development path

use OpenSLX::Basics;
use OpenSLX::ConfigDB qw(:access :manipulation);

use Getopt::Long qw(:config pass_through);
use Pod::Usage;

my (
	$clobber,
	$helpReq,
	$manReq,
	$versionReq,
);

GetOptions(
	'clobber' => \$clobber,
		# clobber causes this script to overwrite the database without asking
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

my $openslxDB = connectConfigDB();

my @systems = fetchSystemsByFilter($openslxDB);
my $systemCount = scalar(@systems)-1;
	# ignore default system
my @clients = fetchClientsByFilter($openslxDB);
my $clientCount = scalar(@clients)-1;
	# ignore default client
if ($systemCount && $clientCount && !$clobber) {
	my $yes = _tr('yes');
	my $no = _tr('no');
	print _tr(qq[This will overwrite the current OpenSLX-database with an example dataset.
All your data (%s systems and %s clients) will be lost!
Do you want to continue(%s/%s)? ], $systemCount, $clientCount, $yes, $no);
	my $answer = <>;
	if ($answer !~ m[^\s*$yes]i) {
		print "no - stopping\n";
		exit 5;
	}
	print "yes - starting...\n";
}

emptyDatabase($openslxDB);

my $vendorOs1Id = addVendorOS($openslxDB, {
		'name' => "suse-10",
		'comment' => "SuSE 10.0 Default-Installation",
		'path' => "suse-10.0",
});

my $vendorOs2Id = addVendorOS($openslxDB, {
		'name' => "suse-10.1",
		'comment' => "SuSE 10.1 Default-Installation",
		'path' => "suse-10.1",
});

my @systems;

my $system1Id = addSystem($openslxDB, {
	'name' => "suse-10.0",
	'label' => "SUSE LINUX 10.0",
	'comment' => "Testsystem für openslx",
	'vendor_os_id' => $vendorOs1Id,
	'ramfs_debug_level' => 0,
	'ramfs_use_glibc' => 0,
	'ramfs_use_busybox' => 0,
	'ramfs_nicmods' => '',
	'ramfs_fsmods' => '',
	'kernel' => "boot/vmlinuz-2.6.13-15-default",
	'kernel_params' => "",
	'export_type' => 'nfs',
	'attr_start_xdmcp' => 'kdm',
});

my $system2Id = addSystem($openslxDB, {
	'name' => "suse-10.1",
	'label' => "SUSE LINUX 10.1",
	'comment' => "Testsystem für openslx",
	'vendor_os_id' => $vendorOs2Id,
	'ramfs_debug_level' => 0,
	'ramfs_use_glibc' => 0,
	'ramfs_use_busybox' => 0,
	'ramfs_nicmods' => '',
	'ramfs_fsmods' => '',
	'kernel' => "boot/vmlinuz-2.6.16.21-0.21-default",
	'kernel_params' => "debug=0",
	'export_type' => 'nfs',
	'attr_start_xdmcp' => 'kdm',
});

my $client1Id = addClient($openslxDB, {
		'name' => "Client-1",
		'mac' => "00:50:56:0D:03:38",
		'boot_type' => 'pxe',
});

my $client2Id = addClient($openslxDB, {
		'name' => "Client-2",
		'mac' => "00:16:41:55:12:92",
		'boot_type' => 'pxe',
});

addSystemIDsToClient($openslxDB, $client1Id, [$system1Id, $system2Id]);
addSystemIDsToClient($openslxDB, $client2Id, [$system2Id]);

disconnectConfigDB($openslxDB);

__END__

=head1 NAME

slxsetup-test-data-simple.pl - Simple OpenSLX test data generator

=head1 SYNOPSIS

slxsetup-test-data-simple.pl [options]

  Script Options:
      --clobber           overwrites config-db without asking

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

=item B<--clobber>

Runs the script without asking any questions, B<any contents in the OpenSLX
config-db will be wiped!>

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

B<slxsetup-test-data-simple.pl> will generate a very simple test-dataset
useful for testing and/or trying things out.

If the OpenSLX configuration database already contains data, the script
asks for confirmation before clobbering that database.

