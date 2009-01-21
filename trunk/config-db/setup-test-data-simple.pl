#! /usr/bin/perl

# add the folder this script lives in to perl's search path for modules:
use FindBin;
use lib $FindBin::Bin;

use OpenSLX::Basics;
use OpenSLX::ConfigDB qw(:access :manipulation);

use Getopt::Long qw(:config pass_through);
my $clobber;
GetOptions(
	'clobber' => \$clobber
		# clobber causes this script to overwrite the database without asking
);

openslxInit();

my $openslxDB = connectConfigDB();

if (!$clobber) {
	my $yes = _tr('yes');
	my $no = _tr('no');
	my @systems = fetchSystemsByFilter($openslxDB);
	my @clients = fetchClientsByFilter($openslxDB);
	print _tr(qq[This will overwrite the current OpenSLX-database with an example dataset.
All your data (%s systems and %s clients) will be lost!
Do you want to continue(%s/%s)? ], scalar(@systems), scalar(@clients), $yes, $no);
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
	'kernel_params' => "debug=3",
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
