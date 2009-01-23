use Test::More qw(no_plan);

use strict;
use warnings;

use lib '/opt/openslx/lib';

# basic init
use OpenSLX::ConfigDB;

my $configDB = OpenSLX::ConfigDB->new;
$configDB->connect();

is(
	my $vendorOS = $configDB->fetchVendorOSByFilter, undef, 
	'no vendor-OS yet (scalar context)'
);

my $wrongVendorOS = {
	'comment' => 'test',
};
ok(
	! eval { my $vendorOSID = $configDB->addVendorOS($wrongVendorOS); },
	'trying to insert an unnamed vendor-OS should fail'
);

is(
	my @vendorOSes = $configDB->fetchVendorOSByFilter, 0, 
	'no vendor-OS yet (array context)'
);

my $inVendorOS1 = {
	'name'    => 'vos-1',
	'comment' => '',
};
is(
	my $vendorOS1ID = $configDB->addVendorOS($inVendorOS1), 1,
	'first vendor-OS has ID 1'
);

my $inVendorOS2 = {
	'name'    => 'vos-2.0',
	'comment' => 'batch 2',
};
my $inVendorOS3 = {
	'name'    => 'vos-3.0',
	'comment' => 'batch 2',
	'clone_source' => 'kiwi::test-vos',
};
ok(
	my ($vendorOS2ID, $vendorOS3ID) = $configDB->addVendorOS([
		$inVendorOS2, $inVendorOS3
	]),
	'add two more vendor-OSes'
);
is($vendorOS2ID, 2, 'vendor-OS 2 should have ID=2');
is($vendorOS3ID, 3, 'vendor-OS 3 should have ID=3');

# fetch vendor-OS 3 by id and check all values
ok(my $vendorOS3 = $configDB->fetchVendorOSByID(3), 'fetch vendor-OS 3');
is($vendorOS3->{id},           3,                'vendor-OS 3 - id');
is($vendorOS3->{name},         'vos-3.0',        'vendor-OS 3 - name');
is($vendorOS3->{comment},      'batch 2',        'vendor-OS 3 - comment');
is($vendorOS3->{clone_source}, 'kiwi::test-vos', 'vendor-OS 3 - clone_source');

# fetch vendor-OS 2 by a filter on id and check all values
ok(
	my $vendorOS2 = $configDB->fetchVendorOSByFilter({ id => 2 }), 
	'fetch vendor-OS 2 by filter on id'
);
is($vendorOS2->{id},           2,         'vendor-OS 2 - id');
is($vendorOS2->{name},         'vos-2.0', 'vendor-OS 2 - name');
is($vendorOS2->{comment},      'batch 2', 'vendor-OS 2 - comment');
is($vendorOS2->{clone_source}, undef,     'vendor-OS 2 - clone_source');

# fetch vendor-OS 1 by filter on name and check all values
ok(
	my $vendorOS1 = $configDB->fetchVendorOSByFilter({ name => 'vos-1' }), 
	'fetch vendor-OS 1 by filter on name'
);
is($vendorOS1->{id},           1,        'vendor-OS 1 - id');
is($vendorOS1->{name},         'vos-1',  'vendor-OS 1 - name');
is($vendorOS1->{comment},      '',       'vendor-OS 1 - comment');
is($vendorOS1->{clone_source}, undef,    'vendor-OS 1 - clone_source');

# fetch vendor-OSes 3 & 1 by id
ok(
	my @vendorOSes3And1
		= $configDB->fetchVendorOSByID([3, 1]), 
	'fetch vendor-OSes 3 & 1 by id'
);
is(@vendorOSes3And1, 2, 'should have got 2 vendor-OSes');
# now sort by ID and check if we have really got 3 and 1
@vendorOSes3And1 = sort { $a->{id} cmp $b->{id} } @vendorOSes3And1;
is($vendorOSes3And1[0]->{id}, 1, 'first id should be 1');
is($vendorOSes3And1[1]->{id}, 3, 'second id should be 3');

# fetching vendor-OSes by id without giving any should yield undef
is(
	$configDB->fetchVendorOSByID(), undef,
	'fetch vendor-OSes by id without giving any'
);

# fetching vendor-OSes by filter without giving any should yield all of them
ok(
	@vendorOSes = $configDB->fetchVendorOSByFilter(),
	'fetch vendor-OSes by filter without giving any'
);
is(@vendorOSes, 3, 'should have got all three vendor-OSes');

# fetch vendor-OSes 2 & 3 by filter on comment
ok(
	my @vendorOSes2And3
		= $configDB->fetchVendorOSByFilter({ comment => 'batch 2' }), 
	'fetch vendor-OSes 2 & 3 by filter on comment'
);
is(@vendorOSes2And3, 2, 'should have got 2 vendor-OSes');
# now sort by ID and check if we have really got 2 and 3
@vendorOSes2And3 = sort { $a->{id} cmp $b->{id} } @vendorOSes2And3;
is($vendorOSes2And3[0]->{id}, 2, 'first id should be 2');
is($vendorOSes2And3[1]->{id}, 3, 'second id should be 3');

# try to fetch with multi-column filter
ok(
	($vendorOS2, $vendorOS3)
		= $configDB->fetchVendorOSByFilter({ comment => 'batch 2', id => 2 }), 
	'fetching vendor-OS with comment="batch 2" and id=2 should work'
);
is($vendorOS2->{name}, 'vos-2.0', 'should have got vos-2.0');
is($vendorOS3, undef, 'should not get vos-3.0');

# try to fetch multiple occurrences of the same vendor-OS, combined with
# some unknown IDs
ok(
	my @vendorOSes1And3
		= $configDB->fetchVendorOSByID([ 1, 21, 4-1, 1, 0, 1, 1 ]), 
	'fetch a complex set of vendor-OSes by ID'
);
is(@vendorOSes1And3, 2, 'should have got 2 vendor-OSes');
# now sort by ID and check if we have really got 1 and 3
@vendorOSes1And3 = sort { $a->{id} cmp $b->{id} } @vendorOSes1And3;
is($vendorOSes1And3[0]->{id}, 1, 'first id should be 1');
is($vendorOSes1And3[1]->{id}, 3, 'second id should be 3');

# try to fetch a couple of non-existing vendor-OSes by id
is(
	$configDB->fetchVendorOSByID(-1), undef, 
	'vendor-OS with id -1 should not exist'
);
is(
	$configDB->fetchVendorOSByID(0), undef, 
	'vendor-OS with id 0 should not exist'
);
is(
	$configDB->fetchVendorOSByID(1 << 31 + 1000), undef, 
	'trying to fetch another unknown vendor-OS'
);

# try to fetch a couple of non-existing vendor-OSes by filter
is(
	$configDB->fetchVendorOSByFilter({ id => 0 }), undef, 
	'fetching vendor-OS with id=0 by filter should fail'
);
is(
	$configDB->fetchVendorOSByFilter({ name => 'vos-1.x' }), undef, 
	'fetching vendor-OS with name="vos-1.x" should fail'
);
is(
	$configDB->fetchVendorOSByFilter({ comment => 'batch 2', id => 1 }), undef, 
	'fetching vendor-OS with comment="batch 2" and id=1 should fail'
);

# rename vendor-OS 1 and then fetch it by its new name
ok($configDB->changeVendorOS(1, { name => q{VOS-'1'} }), 'changing vendor-OS 1');
ok(
	$vendorOS1 = $configDB->fetchVendorOSByFilter({ name => q{VOS-'1'} }), 
	'fetching renamed vendor-OS 1'
);
is($vendorOS1->{id},   1,          'really got vendor-OS number 1');
is($vendorOS1->{name}, q{VOS-'1'}, q{really got vendor-OS named "VOS-'1'"});

# changing nothing at all should succeed
ok($configDB->changeVendorOS(1), 'changing nothing at all in vendor-OS 1');

# changing a non-existing column should fail
ok(
	! eval { $configDB->changeVendorOS(1, { xname => "xx" }) }, 
	'changing unknown colum should fail'
);

ok(! $configDB->changeVendorOS(1, { id => 23 }), 'changing id should fail');

# test adding & removing of installed plugins
is(
	my @plugins = $configDB->fetchInstalledPlugins(3), 
	0, 'there should be no installed plugins'
);
ok($configDB->addInstalledPlugin(3, 'Example'), 'adding installed plugin');
is(
	@plugins = $configDB->fetchInstalledPlugins(3), 
	1,
	'should have 1 installed plugin'
);
is(
	$configDB->addInstalledPlugin(3, 'Example'), 1, 
	'adding plugin again should work (but do not harm, just update the attrs)'
);
is(
	@plugins = $configDB->fetchInstalledPlugins(3), 
	1,
	'should still have 1 installed plugin'
);
is($plugins[0]->{plugin_name}, 'Example', 'should have got plugin "Example"');
ok($configDB->addInstalledPlugin(3, 'Test'), 'adding a second plugin');
is(
	@plugins = $configDB->fetchInstalledPlugins(3), 
	2,
	'should have 2 installed plugin'
);
ok(
	!$configDB->removeInstalledPlugin(3, 'xxx'), 
	'removing unknown plugin should fail'
);
ok(
	@plugins = $configDB->fetchInstalledPlugins(3, 'Example'), 
	'fetching specific plugin'
);
is($plugins[0]->{plugin_name}, 'Example', 'should have got plugin "Example"');
ok(
	@plugins = $configDB->fetchInstalledPlugins(3, 'Test'), 
	'fetching another specific plugin'
);
is($plugins[0]->{plugin_name}, 'Test', 'should have got plugin "Test"');
is(
	@plugins = $configDB->fetchInstalledPlugins(3, 'xxx'), 0,
	'fetching unknown specific plugin'
);
ok($configDB->removeInstalledPlugin(3, 'Example'), 'removing installed plugin');
is(
	@plugins = $configDB->fetchInstalledPlugins(3), 
	1,
	'should have 1 installed plugin'
);
ok($configDB->removeInstalledPlugin(3, 'Test'), 'removing second plugin');
is(
	@plugins = $configDB->fetchInstalledPlugins(3), 
	0,
	'should have no installed plugins'
);

# now remove a vendor-OS and check if that worked
ok($configDB->removeVendorOS(3), 'removing vendor-OS 3 should be ok');
is($configDB->fetchVendorOSByID(3, 'id'), undef, 'vendor-OS 3 should be gone');
is($configDB->fetchVendorOSByID(1)->{id}, 1, 'vendor-OS 1 should still exist');
is($configDB->fetchVendorOSByID(2)->{id}, 2, 'vendor-OS 2 should still exist');

$configDB->disconnect();

