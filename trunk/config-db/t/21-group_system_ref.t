use Test::More qw(no_plan);

use strict;
use warnings;

use lib '/opt/openslx/lib';

# basic init
use OpenSLX::ConfigDB;

my $configDB = OpenSLX::ConfigDB->new;
$configDB->connect();

# fetch groups & systems
my @groups = sort { $a->{id} <=> $b->{id} } $configDB->fetchGroupByFilter();
is(@groups, 2, 'should have got 2 groups (1 and 3)');
my $group1 = shift @groups;
my $group3 = shift @groups;

my @systems = sort { $a->{id} <=> $b->{id} } $configDB->fetchSystemByFilter();
is(@systems, 3, 'should have got 3 systems (default, 1 and 3)');
my $defaultSystem = shift @systems;
my $system1 = shift @systems;
my $system3 = shift @systems;

foreach my $group ($group1, $group3) {
	is(
		my @systemIDs = $configDB->fetchSystemIDsOfGroup($group->{id}),
		0, "group $group->{id} has no system-IDs yet"
	);
}

foreach my $system ($defaultSystem, $system1, $system3) {
	is(
		my @groupIDs = $configDB->fetchGroupIDsOfSystem($system->{id}),
		0, "system $system->{id} has no group-IDs yet"
	);
}

ok(
	$configDB->addSystemIDsToGroup(1, [3]),
	'system-ID 3 has been associated to group 1'
);
is(
	my @systemIDs = sort($configDB->fetchSystemIDsOfGroup(1)),
	1, "group 1 should have one system-ID"
);
is($systemIDs[0], 3, "first system of group 1 should have ID 3");
is(
	@systemIDs = sort($configDB->fetchSystemIDsOfGroup(3)),
	0, "group 3 should have no system-ID"
);
is(
	my @groupIDs = sort($configDB->fetchGroupIDsOfSystem(0)),
	0, "default system should have no group-IDs"
);
is(
	@groupIDs = sort($configDB->fetchGroupIDsOfSystem(1)),
	0, "system 1 should have no group-IDs"
);
is(
	@groupIDs = sort($configDB->fetchGroupIDsOfSystem(3)),
	1, "system 3 should have one group-ID"
);
is($groupIDs[0], 1, "first group of system 3 should have ID 1");

ok(
	$configDB->addSystemIDsToGroup(3, [1,3,3,1,3]),
	'system-IDs 1 and 3 have been associated to group 3'
);
is(
	@systemIDs = sort($configDB->fetchSystemIDsOfGroup(1)),
	1, "group 1 should have one system-ID"
);
is($systemIDs[0], 3, "first system of group 1 should have ID 3");
is(
	@systemIDs = sort($configDB->fetchSystemIDsOfGroup(3)),
	2, "group 3 should have two system-IDs"
);
is($systemIDs[0], 1, "first system of group 3 should have ID 1");
is($systemIDs[1], 3, "second system of group 3 should have ID 3");
is(
	@groupIDs = sort($configDB->fetchGroupIDsOfSystem(0)),
	0, "default system should have no group-ID"
);
is(
	@groupIDs = sort($configDB->fetchGroupIDsOfSystem(1)),
	1, "system 1 should have one group-ID"
);
is($groupIDs[0], 3, "first group of system 1 should have ID 3");
is(
	@groupIDs = sort($configDB->fetchGroupIDsOfSystem(3)),
	2, "system 3 should have two group-IDs"
);
is($groupIDs[0], 1, "first group of system 3 should have ID 1");
is($groupIDs[1], 3, "second group of system 3 should have ID 3");

ok(
	$configDB->setGroupIDsOfSystem(3, []),
	'group-IDs of system 3 have been set to empty array'
);
is(
	@groupIDs = sort($configDB->fetchGroupIDsOfSystem(3)),
	0, "system 3 should have no group-IDs"
);
is(
	@systemIDs = sort($configDB->fetchSystemIDsOfGroup(1)),
	0, "group 1 should have no more system-IDs"
);
is(
	@systemIDs = sort($configDB->fetchSystemIDsOfGroup(3)),
	1, "group 3 should have one system-ID"
);
is($systemIDs[0], 1, "first system of group 3 should have ID 1");

ok(
	$configDB->addSystemIDsToGroup(1, [0]),
	'associating the default system should have no effect'
);
is(
	@systemIDs = sort($configDB->fetchSystemIDsOfGroup(1)),
	0, "group 1 should still have no system-ID"
);

ok(
	$configDB->removeGroupIDsFromSystem(1, [1]),
	'removing an unassociated group-ID should have no effect'
);
is(
	@groupIDs = sort($configDB->fetchGroupIDsOfSystem(1)),
	1, "system 1 should have one group-ID"
);
ok(
	$configDB->removeGroupIDsFromSystem(1, [3]),
	'removing an associated group-ID should work'
);
is(
	@groupIDs = sort($configDB->fetchGroupIDsOfSystem(1)),
	0, "system 1 should have no more group-ID"
);

$configDB->addSystem({
	'name'      => 'sys-5',
	'export_id' => 1,
	'comment'   => 'shortlived',
});
ok(
	$configDB->addGroupIDsToSystem(5, [3]),
	'default group has been associated to system 5'
);
is(
	@systemIDs = sort($configDB->fetchSystemIDsOfGroup(1)),
	0, "group 1 should have no system-ID"
);
is(
	@systemIDs = sort($configDB->fetchSystemIDsOfGroup(3)),
	1, "group 3 should have no system-ID"
);
is($systemIDs[0], 5, "first system of group 3 should have ID 5");
is(
	@groupIDs = sort($configDB->fetchGroupIDsOfSystem(0)),
	0, "default system should have no group-IDs"
);
is(
	@groupIDs = sort($configDB->fetchGroupIDsOfSystem(1)),
	0, "system 1 should have no group-ID"
);
is(
	@groupIDs = sort($configDB->fetchGroupIDsOfSystem(3)),
	0, "system 3 should have no group-IDs"
);
is(
	@groupIDs = sort($configDB->fetchGroupIDsOfSystem(5)),
	1, "system 5 should have one group-ID"
);
is($groupIDs[0], 3, "first group of system 5 should have ID 3");

ok(
	$configDB->removeSystemIDsFromGroup(3, [6]),
	'removing an unassociated system-ID should have no effect'
);
is(
	@groupIDs = sort($configDB->fetchSystemIDsOfGroup(3)),
	1, "group 3 should have one system-ID"
);
ok(
	$configDB->removeSystem(5),
	'removing a system should drop group associations, too'
);
is(
	@groupIDs = sort($configDB->fetchSystemIDsOfGroup(3)),
	0, "group 3 should have no more system-ID"
);

$configDB->disconnect();
