#! /usr/bin/perl

# add the folder this script lives in to perl's search path for modules:
use FindBin;
use lib $FindBin::Bin;

use OpenSLX::Basics;
use OpenSLX::ConfigDB qw(:access :manipulation);

openslxInit();

my $openslxDB = connectConfigDB();

addVendorOS($openslxDB, {
		'name' => "suse-10-minimal",
		'comment' => "SuSE 9.3 minimale Installation",
		'path' => "suse-10.0",
			# relative to /var/lib/openslx/stage1
});

addVendorOS($openslxDB, {
		'name' => "suse-10-KDE",
		'comment' => "SuSE 9.3 grafische Installation mit KDE",
		'path' => "suse-10.0",
});

addVendorOS($openslxDB, {
		'name' => "debian-31",
		'comment' => "Debian 3.1 Default-Installation",
});

my @systems;
foreach my $id (1..10) {
	push @systems, {
		'name' => "name of $id",
		'label' => "label of $id",
		'comment' => "comment of $id",
		'vendor_os_id' => 1 + $id % 3,
		'ramfs_flags' => $id,
		'ramfs_nicmods' => ($id % 3) ? 'forcedeth e1000 e100 tg3 via-rhine r8169 pcnet32' : '',
		'ramfs_fsmods' => ($id % 3)==2 ? 'nbd ext3 nfs reiserfs xfs' : '',
		'kernel' => "boot/vmlinuz-2.6.13-15-default",
		'kernel_params' => "splash=silent",
	};
}
addSystem($openslxDB, \@systems);

removeSystem($openslxDB, [1,3,5,7,9,11,13,15,17,19] );

changeSystem($openslxDB, [ 2 ], [ { 'name' => 'new name of 2'} ] );

changeSystem($openslxDB, [ 0 ], [ { 'attr_start_x' => 'kde,gnome'} ] );
changeSystem($openslxDB, [ 1,2,3 ], [ { 'attr_hw_monitor' => '1280x1024'} ] );
changeSystem($openslxDB, [ 4 ], [ { 'attr_hw_monitor' => '800x600'} ] );


changeSystem($openslxDB, 4, { 'id' => 114, 'name' => 'id should still be 4'} );

my $metaDB = $openslxDB->{'meta-db'};
my $colDescrs = [
	'id:pk',
	'name:s.30',
	'comment:s.1024',
	'counter:i',
	'hidden:b',
	'dropped1:b',
	'dropped2:b',
];
my $initialVals = [
	{
		'name' => '123456789012345678901234567890xxx',
		'comment' => 'comment-value-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
		'counter' => 34567,
		'hidden' => 1,
		'dropped1' => 0,
		'dropped2' => 1,
	},
	{
		'name' => 'name',
		'comment' => q[from_äöüß#'"$...\to_here],
		'counter' => -1,
		'hidden' => 0,
		'dropped1' => 1,
		'dropped2' => 0,
	},
];


$metaDB->schemaAddTable('test', $colDescrs, $initialVals);

$metaDB->schemaRenameTable('test', 'test2', $colDescrs);

push @$colDescrs, 'added:s.20';
push @$colDescrs, 'added2:s.20';
$metaDB->schemaAddColumns('test2',
						  ['added:s.20', 'added2:b'],
						  [{'added' => 'added'}, {'added2' => '1'}],
						  $colDescrs);

my @rows = $metaDB->_doSelect("SELECT * FROM test2");
foreach my $row (@rows) {
	foreach my $r (keys %$row) {
		print "$r = $row->{$r}\n";
	}
}

$colDescrs = [grep {$_ !~ m[dropped]} @$colDescrs];
$metaDB->schemaDropColumns('test2', ['dropped1', 'dropped2'], $colDescrs);


$colDescrs = [
	map {
		if ($_ =~ m[counter]) {
			"count:i";
		} elsif ($_ =~ m[comment]) {
			"description:s.30";
		} else {
			$_
		}
	} @$colDescrs
];
$metaDB->schemaChangeColumns('test2',
							 { 'counter' => 'count:i',
							   'comment' => 'description:s.30' },
							 $colDescrs);

my @rows = $metaDB->_doSelect("SELECT * FROM test2");
foreach my $row (@rows) {
	foreach my $r (keys %$row) {
		print "$r = $row->{$r}\n";
	}
}

$metaDB->schemaDropTable('test2');

my $clientG01ID = addClient($openslxDB, {
		'name' => "PC-G-01",
		'mac' => "00:50:56:0D:03:35",
		'boot_type' => 'pxe',
});

my $clientG02ID = addClient($openslxDB, {
		'name' => "PC-G-02",
		'mac' => "00:50:56:0D:03:36",
		'boot_type' => 'pxe',
});

my $clientG03ID = addClient($openslxDB, {
		'name' => "PC-G-03",
		'mac' => "00:50:56:0D:03:37",
		'boot_type' => 'pxe',
});

my $clientG04ID = addClient($openslxDB, {
		'name' => "PC-G-04",
		'mac' => "00:50:56:0D:03:38",
		'boot_type' => 'pxe',
		'unbootable' => 1,
});

my $clientF01ID = addClient($openslxDB, {
		'name' => "PC-F-01",
		'mac' => "00:50:56:0D:03:31",
		'boot_type' => 'other',
});

my $clientF02ID = addClient($openslxDB, {
		'name' => "PC-F-02",
		'mac' => "00:50:56:0D:03:32",
		'boot_type' => 'pxe',
});

my $clientF03ID = addClient($openslxDB, {
		'name' => "PC-F-03",
		'mac' => "00:50:56:0D:03:33",
		'boot_type' => 'pxe',
});

addClientIDsToSystem($openslxDB, 6, [$clientG01ID, $clientG02ID, $clientG03ID,	$clientG04ID, $clientF01ID, $clientF02ID, $clientF03ID]);

my $group1ID = addGroup($openslxDB, {
		'name' => "Gell-PCs",
		'comment' => "Gell-Threemansion PCs from 2002",
		'attr_hw_mouse' => 'serial',
});
addClientIDsToGroup($openslxDB, $group1ID, [$clientG01ID, $clientF02ID, $clientG03ID]);

my $group2ID = addGroup($openslxDB, {
		'name' => "Teacher-PCs",
		'comment' => "all PCs sitting on teacher's desks",
		'attr_hw_monitor' => '1600x1200',
});
addClientIDsToGroup($openslxDB, $group2ID, [$clientG01ID, $clientF01ID]);
addSystemIDsToGroup($openslxDB, $group2ID, [2, 3]);

my $group3ID = addGroup($openslxDB, {
		'name' => "PCs in room G",
		'comment' => "all PCs of room 234",
});
addClientIDsToGroup($openslxDB, $group3ID, [$clientG01ID, $clientG02ID, $clientG03ID, $clientG04ID]);

disconnectConfigDB($openslxDB);
