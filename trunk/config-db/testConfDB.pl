#! /usr/bin/perl

# add the folder this script lives in to perl's search path for modules:
use FindBin;
use lib $FindBin::Bin;

use ODLX::Basics;
use ODLX::ConfigDB qw(:access :manipulation);

odlxInit();

my $odlxDB = connectConfigDB();

addVendorOS($odlxDB, {
		'name' => "suse-93-minimal",
		'descr' => "SuSE 9.3 minimale Installation",
});

addVendorOS($odlxDB, {
		'name' => "suse-93-KDE",
		'descr' => "SuSE 9.3 grafische Installation mit KDE",
});

addVendorOS($odlxDB, {
		'name' => "debian-31",
		'descr' => "Debian 3.1 Default-Installation",
});

my @systems;
foreach my $id (1..10) {
	push @systems, {
		'name' => "name of $id",
		'descr' => "descr of $id",
		'vendor_os_id' => 1 + $id % 3,
	};
}
addSystem($odlxDB, \@systems);

removeSystem($odlxDB, [1,3,5,7,9,11,13,15,17,19] );

changeSystem($odlxDB, [ 2 ], [ { 'name' => 'new name of 2'} ] );

changeSystem($odlxDB, 4, { 'id' => 114, 'name' => 'id should still be 4'} );

my $metaDB = $odlxDB->{'meta-db'};
my $colDescrs = [
	'id:pk',
	'name:s.30',
	'descr:s.1024',
	'counter:i',
	'hidden:b',
	'dropped1:b',
	'dropped2:b',
];
my $initialVals = [
	{
		'name' => '123456789012345678901234567890xxx',
		'descr' => 'descr-value-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
		'counter' => 34567,
		'hidden' => 1,
		'dropped1' => 0,
		'dropped2' => 1,
	},
	{
		'name' => 'name',
		'descr' => q[from_äöüß#'"$...\to_here],
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
		} elsif ($_ =~ m[descr]) {
			"description:s.30";
		} else {
			$_
		}
	} @$colDescrs
];
$metaDB->schemaChangeColumns('test2',
							 { 'counter' => 'count:i',
							   'descr' => 'description:s.30' },
							 $colDescrs);

my @rows = $metaDB->_doSelect("SELECT * FROM test2");
foreach my $row (@rows) {
	foreach my $r (keys %$row) {
		print "$r = $row->{$r}\n";
	}
}

$metaDB->schemaDropTable('test2');

addGroup($odlxDB, {
		'name' => "Fell-PCs",
		'descr' => "Fell-Threemansion PCs from 2002",
});

addGroup($odlxDB, {
		'name' => "Teacher-PCs",
		'descr' => "all PCs sitting on teacher's desks",
});

addGroup($odlxDB, {
		'name' => "PCs in 234",
		'descr' => "all PCs of room 234",
});

disconnectConfigDB($odlxDB);
