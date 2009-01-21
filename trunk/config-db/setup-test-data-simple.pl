#! /usr/bin/perl

# add the folder this script lives in to perl's search path for modules:
use FindBin;
use lib $FindBin::Bin;

use OpenSLX::Basics;
use OpenSLX::ConfigDB qw(:access :manipulation);

openslxInit();

my $openslxDB = connectConfigDB();

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
