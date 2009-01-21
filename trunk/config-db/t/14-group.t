use Test::More qw(no_plan);

use lib '/opt/openslx/lib';

# basic init
use OpenSLX::ConfigDB;

my $configDB = OpenSLX::ConfigDB->new;
$configDB->connect();

is(
	my $group = $configDB->fetchGroupByFilter, undef,
	'no group should exist (scalar context)'
);

foreach my $requiredCol (qw(name)) {
	my $wrongGroup = {
		'name'     => 'name',
		'priority' => 41,
		'comment'  => 'has column missing',
	};
	delete $wrongGroup->{$requiredCol};
	ok(
		! eval { my $groupID = $configDB->addGroup($wrongGroup); },
		"inserting a group without '$requiredCol' column should fail"
	);
}

is(
	my @groups = $configDB->fetchGroupByFilter, 0, 
	'still no group should exist (array context)'
);

my $inGroup1 = {
	'name'     => 'grp-1',
	'comment'  => '',
};
is(
	my $group1ID = $configDB->addGroup($inGroup1), 1,
	'first group has ID 1'
);

my $inGroup2 = {
	'name'       => 'grp-2.0',
	'priority'   => 30,
	'comment'    => undef,
};
my $fullGroup = {
	'name'     => 'grp-nr-3',
	'priority' => 50,
	'comment'  => 'nuff said',
};
ok(
	my ($group2ID, $group3ID) = $configDB->addGroup([
		$inGroup2, $fullGroup
	]),
	'add two more groups'
);
is($group2ID, 2, 'group 2 should have ID=2');
is($group3ID, 3, 'group 3 should have ID=3');

# fetch group 3 by id and check all values
ok(my $group3 = $configDB->fetchGroupByID(3), 'fetch group 3');
is($group3->{id},       '3',         'group 3 - id');
is($group3->{name},     'grp-nr-3',  'group 3 - name');
is($group3->{priority}, 50,          'group 3 - priority');
is($group3->{comment},  'nuff said', 'group 3 - comment');

# fetch group 2 by a filter on id and check all values
ok(
	my $group2 = $configDB->fetchGroupByFilter({ id => 2 }), 
	'fetch group 2 by filter on id'
);
is($group2->{id},       2,         'group 2 - id');
is($group2->{name},     'grp-2.0', 'group 2 - name');
is($group2->{priority}, 30,        'group 2 - priority');
is($group2->{comment},  undef,     'group 2 - comment');

# fetch group 1 by filter on name and check all values
ok(
	my $group1 = $configDB->fetchGroupByFilter({ name => 'grp-1' }), 
	'fetch group 1 by filter on name'
);
is($group1->{id},       1,       'group 1 - id');
is($group1->{name},     'grp-1', 'group 1 - name');
is($group1->{priority}, 50,      'group 1 - priority');
is($group1->{comment},  '',      'group 1 - comment');

# fetch groups 3 & 1 by id
ok(
	my @groups3And1 = $configDB->fetchGroupByID([3, 1]), 
	'fetch groups 3 & 1 by id'
);
is(@groups3And1, 2, 'should have got 2 groups');
# now sort by ID and check if we have really got 3 and 1
@groups3And1 = sort { $a->{id} cmp $b->{id} } @groups3And1;
is($groups3And1[0]->{id}, 1, 'first id should be 1');
is($groups3And1[1]->{id}, 3, 'second id should be 3');

# fetching groups by id without giving any should yield undef
is(
	$configDB->fetchGroupByID(), undef,
	'fetch groups by id without giving any'
);

# fetching groups by filter without giving any should yield all of them
ok(
	@groups = $configDB->fetchGroupByFilter(),
	'fetch groups by filter without giving any'
);
is(@groups, 3, 'should have got all three groups');

# fetch groups 1 & 2 by filter on priority
ok(
	my @groups1And3 = $configDB->fetchGroupByFilter({ priority => 50 }), 
	'fetch groups 1 & 3 by filter on priority'
);
is(@groups1And3, 2, 'should have got 2 groups');
# now sort by ID and check if we have really got 1 and 3
@groups1And3 = sort { $a->{id} cmp $b->{id} } @groups1And3;
is($groups1And3[0]->{id}, 1, 'first id should be 1');
is($groups1And3[1]->{id}, 3, 'second id should be 3');

# try to fetch with multi-column filter
ok(
	($group1, $group3)
		= $configDB->fetchGroupByFilter({ priority => '50', id => 1 }), 
	'fetching group with priority=50 and id=1 should work'
);
is($group1->{name}, 'grp-1', 'should have got grp-1');
is($group3, undef, 'should not get grp-nr-3');

# try to fetch multiple occurrences of the same group, combined with
# some unknown IDs
ok(
	@groups1And3 = $configDB->fetchGroupByID([ 1, 21, 4-1, 1, 4, 1, 1 ]), 
	'fetch a complex set of groups by ID'
);
is(@groups1And3, 2, 'should have got 2 groups');
# now sort by ID and check if we have really got 1 and 3
@groups1And3 = sort { $a->{id} cmp $b->{id} } @groups1And3;
is($groups1And3[0]->{id}, 1, 'first id should be 1');
is($groups1And3[1]->{id}, 3, 'second id should be 3');

# try to fetch a couple of non-existing groups by id
is($configDB->fetchGroupByID(-1), undef, 'group with id -1 should not exist');
is($configDB->fetchGroupByID(0), undef, 'group with id 0 should not exist');
is(
	$configDB->fetchGroupByID(1 << 31 + 1000), undef, 
	'trying to fetch another unknown group'
);

# try to fetch a couple of non-existing groups by filter
is(
	$configDB->fetchGroupByFilter({ id => 4 }), undef, 
	'fetching group with id=4 by filter should fail'
);
is(
	$configDB->fetchGroupByFilter({ name => 'grp-1.x' }), undef, 
	'fetching group with name="grp-1.x" should fail'
);
is(
	$configDB->fetchGroupByFilter({ priority => '22', id => 1 }), undef, 
	'fetching group with priority=22 and id=1 should fail'
);

# rename group 1 and then fetch it by its new name
ok($configDB->changeGroup(1, { name => q{GRP-'1'} }), 'changing group 1');
ok(
	$group1 = $configDB->fetchGroupByFilter({ name => q{GRP-'1'} }), 
	'fetching renamed group 1'
);
is($group1->{id},   1,          'really got group number 1');
is($group1->{name}, q{GRP-'1'}, q{really got group named "GRP-'1'"});

# changing a non-existing column should fail
ok(
	! eval { $configDB->changeGroup(1, { xname => "xx" }) }, 
	'changing unknown colum should fail'
);

ok(! $configDB->changeGroup(1, { id => 23 }), 'changing id should fail');

# now remove an group and check if that worked
ok($configDB->removeGroup(2), 'removing group 2 should be ok');
is($configDB->fetchGroupByID(2, 'id'), undef, 'group 2 should be gone');
is($configDB->fetchGroupByID(1)->{id}, 1, 'group 1 should still exist');
is($configDB->fetchGroupByID(3)->{id}, 3, 'group 3 should still exist');

$configDB->disconnect();

