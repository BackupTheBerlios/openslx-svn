use Test::More qw(no_plan);

use strict;
use warnings;

use lib '/opt/openslx/lib';

# basic init
use OpenSLX::ConfigDB;

my $configDB = OpenSLX::ConfigDB->new;
$configDB->connect();

is(
	my $export = $configDB->fetchExportByFilter, undef, 
	'no export yet (scalar context)'
);

foreach my $requiredCol (qw(name vendor_os_id type)) {
	my $wrongExport = {
		'name'         => 'name',
		'vendor_os_id' => 1,
		'type        ' => 'nfs',
		'comment'      => 'has column missing',
	};
	delete $wrongExport->{$requiredCol};
	ok(
		! eval { my $exportID = $configDB->addExport($wrongExport); },
		"inserting an export without '$requiredCol' column should fail"
	);
}

is(
	my @exports = $configDB->fetchExportByFilter, 0, 
	'no export yet (array context)'
);

is(
	my @exportIDs = $configDB->fetchExportIDsOfVendorOS(1), 0, 
	'vendor-OS 1 has no export IDs yet'
);

is(
	@exportIDs = $configDB->fetchExportIDsOfVendorOS(2), 0, 
	'vendor-OS 2 has no export IDs yet'
);

my $inExport1 = {
	'name'         => 'exp-1',
	'type'         => 'nfs',
	'vendor_os_id' => 1,
	'comment'      => '',
};
is(
	my $export1ID = $configDB->addExport($inExport1), 1,
	'first export has ID 1'
);

my $inExport2 = {
	'name'         => 'exp-2.0',
	'type'         => 'sqfs-nbd',
	'vendor_os_id' => 1,
	'comment'      => undef,
};
my $fullExport = {
	'name'         => 'exp-nr-3',
	'type'         => 'sqfs-nbd',
	'vendor_os_id' => 2,
	'comment'      => 'nuff said',
	'server_ip'    => '192.168.212.243',
	'port'         => '65432',
	'uri'          => 'sqfs-nbd://somehost/somepath?param=val&yes=1',
};
ok(
	my ($export2ID, $export3ID) = $configDB->addExport([
		$inExport2, $fullExport
	]),
	'add two more exports'
);
is($export2ID, 2, 'export 2 should have ID=2');
is($export3ID, 3, 'export 3 should have ID=3');

# fetch export 3 by id and check all values
ok(my $export3 = $configDB->fetchExportByID(3), 'fetch export 3');
is($export3->{id},           3,                 'export 3 - id');
is($export3->{name},         'exp-nr-3',        'export 3 - name');
is($export3->{type},         'sqfs-nbd',        'export 3 - type');
is($export3->{vendor_os_id}, '2',               'export 3 - vendor_os_id');
is($export3->{comment},      'nuff said',       'export 3 - comment');
is($export3->{server_ip},    '192.168.212.243', 'export 3 - server_ip');
is($export3->{port},         '65432',           'export 3 - port');
is(
	$export3->{uri}, 
	'sqfs-nbd://somehost/somepath?param=val&yes=1', 
	'export 3 - uri'
);

# fetch export 2 by a filter on id and check all values
ok(
	my $export2 = $configDB->fetchExportByFilter({ id => 2 }), 
	'fetch export 2 by filter on id'
);
is($export2->{id},           2,          'export 2 - id');
is($export2->{name},         'exp-2.0',  'export 2 - name');
is($export2->{type},         'sqfs-nbd', 'export 2 - type');
is($export2->{vendor_os_id}, '1',        'export 2 - vendor_os_id');
is($export2->{comment},      undef,      'export 2 - comment');

# fetch export 1 by filter on name and check all values
ok(
	my $export1 = $configDB->fetchExportByFilter({ name => 'exp-1' }), 
	'fetch export 1 by filter on name'
);
is($export1->{id},           1,        'export 1 - id');
is($export1->{name},         'exp-1',  'export 1 - name');
is($export1->{vendor_os_id}, '1',      'export 1 - vendor_os_id');
is($export1->{type},         'nfs',    'export 1 - type');
is($export1->{comment},      '',       'export 1 - comment');
is($export1->{port},         undef,    'export 1 - port');
is($export1->{server_ip},    undef,    'export 1 - server_ip');
is($export1->{uri},          undef,    'export 1 - uri');

is(
	@exportIDs = sort( { $a <=> $b } $configDB->fetchExportIDsOfVendorOS(1)), 
	2, 'vendor-OS 1 has two export IDs'
);
is($exportIDs[0], 1, 'first export ID of vendor-OS 1 (1)');
is($exportIDs[1], 2, 'second export ID of vendor-OS 1 (2)');

is(
	@exportIDs = sort( { $a <=> $b } $configDB->fetchExportIDsOfVendorOS(2)), 
	1, 'vendor-OS 2 has one export IDs'
);
is($exportIDs[0], 3, 'first export ID of vendor-OS 2 (3)');

# fetch exports 3 & 1 by id
ok(
	my @exports3And1 = $configDB->fetchExportByID([3, 1]), 
	'fetch exports 3 & 1 by id'
);
is(@exports3And1, 2, 'should have got 2 exports');
# now sort by ID and check if we have really got 3 and 1
@exports3And1 = sort { $a->{id} cmp $b->{id} } @exports3And1;
is($exports3And1[0]->{id}, 1, 'first id should be 1');
is($exports3And1[1]->{id}, 3, 'second id should be 3');

# fetching exports by id without giving any should yield undef
is(
	$configDB->fetchExportByID(), undef,
	'fetch exports by id without giving any'
);

# fetching exports by filter without giving any should yield all of them
ok(
	@exports = $configDB->fetchExportByFilter(),
	'fetch exports by filter without giving any'
);
is(@exports, 3, 'should have got all three exports');

# fetch exports 1 & 2 by filter on vendor_os_id
ok(
	my @exports1And2 = $configDB->fetchExportByFilter({ vendor_os_id => '1' }), 
	'fetch exports 1 & 2 by filter on vendor_os_id'
);
is(@exports1And2, 2, 'should have got 2 exports');
# now sort by ID and check if we have really got 1 and 2
@exports1And2 = sort { $a->{id} cmp $b->{id} } @exports1And2;
is($exports1And2[0]->{id}, 1, 'first id should be 1');
is($exports1And2[1]->{id}, 2, 'second id should be 2');

# try to fetch with multi-column filter
ok(
	($export2, $export3)
		= $configDB->fetchExportByFilter({ vendor_os_id => '1', id => 2 }), 
	'fetching export with vendor_os_id=1 and id=2 should work'
);
is($export2->{name}, 'exp-2.0', 'should have got exp-2.0');
is($export3, undef, 'should not get exp-nr-3');

# try to fetch multiple occurrences of the same export, combined with
# some unknown IDs
ok(
	my @exports1And3 = $configDB->fetchExportByID([ 1, 21, 4-1, 1, 0, 1, 1 ]), 
	'fetch a complex set of exports by ID'
);
is(@exports1And3, 2, 'should have got 2 exports');
# now sort by ID and check if we have really got 1 and 3
@exports1And3 = sort { $a->{id} cmp $b->{id} } @exports1And3;
is($exports1And3[0]->{id}, 1, 'first id should be 1');
is($exports1And3[1]->{id}, 3, 'second id should be 3');

# try to fetch a couple of non-existing exports by id
is(
	$configDB->fetchExportByID(-1), undef, 
	'export with id -1 should not exist'
);
is(
	$configDB->fetchExportByID(0), undef, 
	'export with id 0 should not exist'
);
is(
	$configDB->fetchExportByID(1 << 31 + 1000), undef, 
	'trying to fetch another unknown export'
);

# try to fetch a couple of non-existing exports by filter
is(
	$configDB->fetchExportByFilter({ id => 0 }), undef, 
	'fetching export with id=0 by filter should fail'
);
is(
	$configDB->fetchExportByFilter({ name => 'exp-1.x' }), undef, 
	'fetching export with name="exp-1.x" should fail'
);
is(
	$configDB->fetchExportByFilter({ vendor_os_id => '2', id => 1 }), undef, 
	'fetching export with vendor_os_id=2 and id=1 should fail'
);

# rename export 1 and then fetch it by its new name
ok($configDB->changeExport(1, { name => q{EXP-'1'} }), 'changing export 1');
ok(
	$export1 = $configDB->fetchExportByFilter({ name => q{EXP-'1'} }), 
	'fetching renamed export 1'
);
is($export1->{id},   1,          'really got export number 1');
is($export1->{name}, q{EXP-'1'}, q{really got export named "EXP-'1'"});

# changing nothing at all should succeed
ok($configDB->changeExport(1), 'changing nothing at all in export 1');

# changing a non-existing column should fail
ok(
	! eval { $configDB->changeExport(1, { xname => "xx" }) }, 
	'changing unknown colum should fail'
);

ok(! $configDB->changeExport(1, { id => 23 }), 'changing id should fail');

# now remove an export and check if that worked
ok($configDB->removeExport(2), 'removing export 2 should be ok');
is($configDB->fetchExportByID(2, 'id'), undef, 'export 2 should be gone');
is($configDB->fetchExportByID(1)->{id}, 1, 'export 1 should still exist');
is($configDB->fetchExportByID(3)->{id}, 3, 'export 3 should still exist');

$configDB->disconnect();

