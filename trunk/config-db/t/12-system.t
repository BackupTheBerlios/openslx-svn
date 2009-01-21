use Test::More qw(no_plan);

use lib '/opt/openslx/lib';

# basic init
use OpenSLX::ConfigDB;

my $configDB = OpenSLX::ConfigDB->new;
$configDB->connect();

ok(
	my $system = $configDB->fetchSystemByFilter, 
	'one system [default] should exist (scalar context)'
);

foreach my $requiredCol (qw(name export_id)) {
	my $wrongSystem = {
		'name'      => 'name',
		'export_id' => 1,
		'comment'   => 'has column missing',
	};
	delete $wrongSystem->{$requiredCol};
	ok(
		! eval { my $systemID = $configDB->addSystem($wrongSystem); },
		"inserting a system without '$requiredCol' column should fail"
	);
}

is(
	my @systems = $configDB->fetchSystemByFilter, 1, 
	'still just one system [default] should exist (array context)'
);

my $inSystem1 = {
	'name'      => 'sys-1',
	'export_id' => 1,
	'comment'   => '',
};
is(
	my $system1ID = $configDB->addSystem($inSystem1), 1,
	'first system has ID 1'
);

my $inSystem2 = {
	'name'      => 'sys-2.0',
	'kernel'    => 'vmlinuz',
	'export_id' => 1,
	'comment'   => undef,
};
my $fullSystem = {
	'name'                => 'sys-nr-3',
	'kernel'              => 'vmlinuz-2.6.22.13-0.3-default',
	'export_id'           => 3,
	'comment'             => 'nuff said',
	'label'               => 'BlingBling System - really kuul!',
	'kernel_params'       => 'debug=3 console=ttyS1',
	'hidden'              => '1',
	'attr_ramfs_nicmods'  => 'e1000 forcedeth',
	'attr_ramfs_fsmods'   => 'squashfs',
	'attr_ramfs_miscmods' => 'tpm',
	'attr_ramfs_screen'   => '1024x768',
};
ok(
	my ($system2ID, $system3ID) = $configDB->addSystem([
		$inSystem2, $fullSystem
	]),
	'add two more systems'
);
is($system2ID, 2, 'system 2 should have ID=2');
is($system3ID, 3, 'system 3 should have ID=3');

# fetch system 3 by id and check all values
ok(my $system3 = $configDB->fetchSystemByID(3), 'fetch system 3');
is($system3->{id},                  '3',                     'system 3 - id');
is($system3->{name},                'sys-nr-3',              'system 3 - name');
is($system3->{kernel},              'vmlinuz-2.6.22.13-0.3-default',        'system 3 - type');
is($system3->{export_id},           '3',                     'system 3 - export_id');
is($system3->{comment},             'nuff said',             'system 3 - comment');
is($system3->{label},               'BlingBling System - really kuul!', 'system 3 - label');
is($system3->{kernel_params},       'debug=3 console=ttyS1', 'system 3 - kernel_params');
is($system3->{hidden},              '1',                     'system 3 - hidden');
is($system3->{attr_ramfs_nicmods},  'e1000 forcedeth',       'system 3 - attr_ramfs_nicmods');
is($system3->{attr_ramfs_fsmods},   'squashfs',              'system 3 - attr_ramfs_fsmods');
is($system3->{attr_ramfs_miscmods}, 'tpm',                   'system 3 - attr_ramfs_miscmods');
is($system3->{attr_ramfs_screen},   '1024x768',              'system 3 - attr_ramfs_screen');

# fetch system 2 by a filter on id and check all values
ok(
	my $system2 = $configDB->fetchSystemByFilter({ id => 2 }), 
	'fetch system 2 by filter on id'
);
is($system2->{id},        2,         'system 2 - id');
is($system2->{name},      'sys-2.0', 'system 2 - name');
is($system2->{kernel},    'vmlinuz', 'system 2 - kernel');
is($system2->{export_id}, '1',       'system 2 - export_id');
is($system2->{comment},   undef,     'system 2 - comment');

# fetch system 1 by filter on name and check all values
ok(
	my $system1 = $configDB->fetchSystemByFilter({ name => 'sys-1' }), 
	'fetch system 1 by filter on name'
);
is($system1->{id},                  1,         'system 1 - id');
is($system1->{name},                'sys-1',   'system 1 - name');
is($system1->{export_id},           '1',       'system 1 - export_id');
is($system1->{kernel},              'vmlinuz', 'system 1 - kernel');
is($system1->{comment},             '',        'system 1 - comment');
is($system1->{label},               'sys-1',   'system 1 - label');
is($system1->{kernel_params},       undef,     'system 1 - kernel_params');
is($system1->{hidden},              undef,     'system 1 - hidden');
is($system1->{attr_ramfs_nicmods},  undef,     'system 1 - attr_ramfs_nicmods');
is($system1->{attr_ramfs_fsmods},   undef,     'system 1 - attr_ramfs_fsmods');
is($system1->{attr_ramfs_miscmods}, undef,     'system 1 - attr_ramfs_miscmods');
is($system1->{attr_ramfs_screen},   undef,     'system 1 - attr_ramfs_screen');

# fetch systems 3 & 1 by id
ok(
	my @systems3And1 = $configDB->fetchSystemByID([3, 1]), 
	'fetch systems 3 & 1 by id'
);
is(@systems3And1, 2, 'should have got 2 systems');
# now sort by ID and check if we have really got 3 and 1
@systems3And1 = sort { $a->{id} cmp $b->{id} } @systems3And1;
is($systems3And1[0]->{id}, 1, 'first id should be 1');
is($systems3And1[1]->{id}, 3, 'second id should be 3');

# fetching systems by id without giving any should yield undef
is(
	$configDB->fetchSystemByID(), undef,
	'fetch systems by id without giving any'
);

# fetching systems by filter without giving any should yield all of them
ok(
	@systems = $configDB->fetchSystemByFilter(),
	'fetch systems by filter without giving any'
);
is(@systems, 4, 'should have got all four systems');

# fetch systems 1 & 2 by filter on export_id
ok(
	my @systems1And2 = $configDB->fetchSystemByFilter({ export_id => '1' }), 
	'fetch systems 1 & 2 by filter on export_id'
);
is(@systems1And2, 2, 'should have got 2 systems');
# now sort by ID and check if we have really got 1 and 2
@systems1And2 = sort { $a->{id} cmp $b->{id} } @systems1And2;
is($systems1And2[0]->{id}, 1, 'first id should be 1');
is($systems1And2[1]->{id}, 2, 'second id should be 2');

# try to fetch with multi-column filter
ok(
	($system2, $system3)
		= $configDB->fetchSystemByFilter({ export_id => '1', id => 2 }), 
	'fetching system with export_id=1 and id=2 should work'
);
is($system2->{name}, 'sys-2.0', 'should have got sys-2.0');
is($system3, undef, 'should not get sys-nr-3');

# try to fetch multiple occurrences of the same system, combined with
# some unknown IDs
ok(
	my @systems1And3 = $configDB->fetchSystemByID([ 1, 21, 4-1, 1, 3, 1, 1 ]), 
	'fetch a complex set of systems by ID'
);
is(@systems1And3, 2, 'should have got 2 systems');
# now sort by ID and check if we have really got 1 and 3
@systems1And3 = sort { $a->{id} cmp $b->{id} } @systems1And3;
is($systems1And3[0]->{id}, 1, 'first id should be 1');
is($systems1And3[1]->{id}, 3, 'second id should be 3');

# try to fetch a couple of non-existing systems by id
is(
	$configDB->fetchSystemByID(-1), undef, 
	'system with id -1 should not exist'
);
ok($configDB->fetchSystemByID(0), 'system with id 0 should exist');
is(
	$configDB->fetchSystemByID(1 << 31 + 1000), undef, 
	'trying to fetch another unknown system'
);

# try to fetch a couple of non-existing systems by filter
is(
	$configDB->fetchSystemByFilter({ id => 4 }), undef, 
	'fetching system with id=4 by filter should fail'
);
is(
	$configDB->fetchSystemByFilter({ name => 'sys-1.x' }), undef, 
	'fetching system with name="sys-1.x" should fail'
);
is(
	$configDB->fetchSystemByFilter({ export_id => '2', id => 1 }), undef, 
	'fetching system with export_id=2 and id=1 should fail'
);

# rename system 1 and then fetch it by its new name
ok($configDB->changeSystem(1, { name => q{SYS-'1'} }), 'changing system 1');
ok(
	$system1 = $configDB->fetchSystemByFilter({ name => q{SYS-'1'} }), 
	'fetching renamed system 1'
);
is($system1->{id},   1,          'really got system number 1');
is($system1->{name}, q{SYS-'1'}, q{really got system named "SYS-'1'"});

# changing a non-existing column should fail
ok(
	! eval { $configDB->changeSystem(1, { xname => "xx" }) }, 
	'changing unknown colum should fail'
);

ok(! $configDB->changeSystem(1, { id => 23 }), 'changing id should fail');

# now remove an system and check if that worked
ok($configDB->removeSystem(2), 'removing system 2 should be ok');
is($configDB->fetchSystemByID(2, 'id'), undef, 'system 2 should be gone');
is($configDB->fetchSystemByID(1)->{id}, 1, 'system 1 should still exist');
is($configDB->fetchSystemByID(3)->{id}, 3, 'system 3 should still exist');

$configDB->disconnect();

