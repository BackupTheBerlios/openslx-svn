#! /usr/bin/perl
#
# create-simple-db.pl - Simple OpenSLX test data generator
#
# (c) 2006 - OpenSLX.com
#
# Oliver Tappe <ot@openslx.com>
#
use strict;

my $abstract = q[
create-simple-db.pl
    This script will generate a very simple OpenSLX test-dataset, useful for
    testing and/or trying things out.

    If the OpenSLX configuration database already contains data, the script
    will ask for confirmation before clobbering that database.
];

use Getopt::Long qw(:config pass_through);
use Pod::Usage;

# add the lib-folder and the config-db folder to perl's search
# path for modules:
use FindBin;
use lib "$FindBin::RealBin/../../lib";
use lib "$FindBin::RealBin/..";
	# development path to config-db stuff

use OpenSLX::Basics;
use OpenSLX::ConfigDB qw(:access :manipulation);

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
pod2usage(-msg => $abstract, -verbose => 0, -exitval => 1) if $helpReq;
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
	'kernel' => "boot/vmlinuz",
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
	'kernel' => "boot/vmlinuz",
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

if ($openslxConfig{'db-type'} =~ m[^\s*csv\s*$]i) {
	my $csvFolder = "$openslxConfig{'db-basepath'}/$openslxConfig{'db-name'}-csv";
	print "The test-database with the CSV-files has been created in\n";
	print "\t$csvFolder\n";
	print "You can change the dataset with a simple editor or using\n";
	print "a spreadsheet software like 'OpenOffice Calc' or 'Gnumeric'.\n";
}

__END__

=head1 NAME

create-simple-db.pl - Simple OpenSLX test data generator

=head1 SYNOPSIS

create-simple-db.pl [options]

  Script Options:
      --clobber                  overwrites config-db without asking

  OpenSLX Options:
      --base-path=<string>       basic path to project files
      --bin-path=<string>        path to binaries and scripts
      --config-path=<string>     path to configuration files
      --db-basepath=<string>     basic path to openslx database
      --db-datadir=<string>      data folder created under db-basepath
      --db-name=<string>         name of database
      --db-spec=<string>         full DBI-specification of database
      --db-type=<string>         type of database to connect to
      --export-path=<string>     path to root of all exported filesystems
      --locale=<string>          locale to use for translations
      --logfile=<string>         file to write logging output to
      --private-path=<string>    path to private data
      --public-path=<string>     path to public (client-accesible) data
      --share-path=<string>      path to sharable data
      --temp-path=<string>       path to temporary data
      --tftpboot-path=<string>   path to root of tftp-server
      --verbose-level=<int>      level of logging verbosity (0-3)

  General Options:
      --help                     brief help message
      --man                      full documentation
      --version                  show version

=head1 OPTIONS

=head3 Script Options

=over 8

=item B<--clobber>

Runs the script without asking any questions, B<any contents in the OpenSLX
config-db will be wiped!>

=back

=head3 OpenSLX Options

=over 8

=item B<--base-path=<string>>

Sets basic path to project files.

Default is $SLX_BASE_PATH (usually F</opt/openslx>).

=item B<--bin-path=<string>>

Sets path to binaries and scripts.

Default is $SLX_BASE_PATH/bin (usually F</opt/openslx/bin>).

=item B<--config-path=<string>>

Sets path to configuration files.

Default is $SLX_CONFIG_PATH (usually F</etc/opt/openslx>).

=item B<--db-basepath=<string>>

Sets basic path to openslx database.

Default is $SLX_DB_PATH (usually F</var/opt/openslx/db>).

=item B<--db-datadir=<string>>

Sets data folder created under db-basepath.

Default is $SLX_DB_DATADIR (usually empty as it depends on db-type
whether or not such a directory is required at all).

=item B<--db-name=<string>>

Gives the name of the database to connect to.

Default is $SLX_DB_NAME (usually C<openslx>).

=item B<--db-spec=<string>>

Gives the full DBI-specification of database to connect to. Content depends
on the db-type.

Default is $SLX_DB_SPEC (usually empty as it will be built automatically).

=item B<--db-type=<string>>

Sets the type of database to connect to (CSV, SQLite, mysql, ...).

Default $SLX_DB_TYPE (usually C<CSV>).

=item B<--export-path=<string>>

Sets path to root of all exported filesystems. For each type of export (NFS,
NBD, ...) a separate folder will be created in here.

Default is $SLX_EXPORT_PATH (usually F</srv/openslx/export>.

=item B<--locale=<string>>

Sets the locale to use for translations.

Defaults to the system's standard locale.

=item B<--logfile=<string>>

Specifies a file where logging output will be written to.

Default is to log to STDERR.

=item B<--private-path=<string>>

Sets path to private data, where the config-db, vendor_oses and configurational
extensions will be stored.

Default is $SLX_PRIVATE_PATH (usually F</var/opt/openslx>.

=item B<--public-path=<string>>

Sets path to public (client-accesible) data.

Default is $SLX_PUBLIC_PATH (usually F</srv/openslx>.

=item B<--share-path=<string>>

Sets path to sharable data, where distro-specs and functionality templates
will be stored.

Default is $SLX_SHARE_PATH (usually F</opt/openslx/share>.

=item B<--temp-path=<string>>

Sets path to temporary data.

Default is $SLX_TEMP_PATH (usually F</tmp>.

=item B<--tftpboot-path=<string>>

Sets path to root of tftp-server from which clients will access their files.

Default is $SLX_TFTPBOOT_PATH (usually F</srv/openslx/tftpboot>.

=item B<--verbose-level=<int>>

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
will ask for confirmation before clobbering that database.

=cut