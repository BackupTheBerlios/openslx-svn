use Test::More qw(no_plan);

use strict;
use warnings;

use lib '/opt/openslx/lib';

# basic init
use OpenSLX::ConfigDB;

my $configDB = OpenSLX::ConfigDB->new;
$configDB->connect();

# fetch groups & clients
my @groups = sort { $a->{id} <=> $b->{id} } $configDB->fetchGroupByFilter();
is(@groups, 2, 'should have got 2 groups (1 and 3)');
my $group1 = shift @groups;
my $group3 = shift @groups;

my @clients = sort { $a->{id} <=> $b->{id} } $configDB->fetchClientByFilter();
is(@clients, 3, 'should have got 3 clients (default, 1 and 3)');
my $defaultClient = shift @clients;
my $client1 = shift @clients;
my $client3 = shift @clients;

foreach my $group ($group1, $group3) {
	is(
		my @clientIDs = $configDB->fetchClientIDsOfGroup($group->{id}),
		0, "group $group->{id} has no client-IDs yet"
	);
}

foreach my $client ($defaultClient, $client1, $client3) {
	is(
		my @groupIDs = $configDB->fetchGroupIDsOfClient($client->{id}),
		0, "client $client->{id} has no group-IDs yet"
	);
}

ok(
	$configDB->addClientIDsToGroup(1, [3]),
	'client-ID 3 has been associated to group 1'
);
is(
	my @clientIDs = sort($configDB->fetchClientIDsOfGroup(1)),
	1, "group 1 should have one client-ID"
);
is($clientIDs[0], 3, "first client of group 1 should have ID 3");
is(
	@clientIDs = sort($configDB->fetchClientIDsOfGroup(3)),
	0, "group 3 should have no client-ID"
);
is(
	my @groupIDs = sort($configDB->fetchGroupIDsOfClient(0)),
	0, "default client should have no group-IDs"
);
is(
	@groupIDs = sort($configDB->fetchGroupIDsOfClient(1)),
	0, "client 1 should have no group-IDs"
);
is(
	@groupIDs = sort($configDB->fetchGroupIDsOfClient(3)),
	1, "client 3 should have one group-ID"
);
is($groupIDs[0], 1, "first group of client 3 should have ID 1");

ok(
	$configDB->addClientIDsToGroup(3, [1,3,3,1,3]),
	'client-IDs 1 and 3 have been associated to group 3'
);
is(
	@clientIDs = sort($configDB->fetchClientIDsOfGroup(1)),
	1, "group 1 should have one client-ID"
);
is($clientIDs[0], 3, "first client of group 1 should have ID 3");
is(
	@clientIDs = sort($configDB->fetchClientIDsOfGroup(3)),
	2, "group 3 should have two client-IDs"
);
is($clientIDs[0], 1, "first client of group 3 should have ID 1");
is($clientIDs[1], 3, "second client of group 3 should have ID 3");
is(
	@groupIDs = sort($configDB->fetchGroupIDsOfClient(0)),
	0, "default client should have no group-ID"
);
is(
	@groupIDs = sort($configDB->fetchGroupIDsOfClient(1)),
	1, "client 1 should have one group-ID"
);
is($groupIDs[0], 3, "first group of client 1 should have ID 3");
is(
	@groupIDs = sort($configDB->fetchGroupIDsOfClient(3)),
	2, "client 3 should have two group-IDs"
);
is($groupIDs[0], 1, "first group of client 3 should have ID 1");
is($groupIDs[1], 3, "second group of client 3 should have ID 3");

ok(
	$configDB->setGroupIDsOfClient(3, []),
	'group-IDs of client 3 have been set to empty array'
);
is(
	@groupIDs = sort($configDB->fetchGroupIDsOfClient(3)),
	0, "client 3 should have no group-IDs"
);
is(
	@clientIDs = sort($configDB->fetchClientIDsOfGroup(1)),
	0, "group 1 should have no more client-IDs"
);
is(
	@clientIDs = sort($configDB->fetchClientIDsOfGroup(3)),
	1, "group 3 should have one client-ID"
);
is($clientIDs[0], 1, "first client of group 3 should have ID 1");

ok(
	$configDB->removeGroupIDsFromClient(1, [1]),
	'removing an unassociated group-ID should have no effect'
);
is(
	@groupIDs = sort($configDB->fetchGroupIDsOfClient(1)),
	1, "client 1 should have one group-ID"
);
ok(
	$configDB->removeGroupIDsFromClient(1, [3]),
	'removing an associated group-ID should work'
);
is(
	@groupIDs = sort($configDB->fetchGroupIDsOfClient(1)),
	0, "client 1 should have no more group-ID"
);

$configDB->addClient({
	'name'      => 'cli-4',
	'mac'       => '01:01:01:02:02:02',
	'comment'   => 'shortlived',
});
ok(
	$configDB->addGroupIDsToClient(4, [3]),
	'default group has been associated to client 4'
);
is(
	@clientIDs = sort($configDB->fetchClientIDsOfGroup(1)),
	0, "group 1 should have no client-ID"
);
is(
	@clientIDs = sort($configDB->fetchClientIDsOfGroup(3)),
	1, "group 3 should have one client-ID"
);
is($clientIDs[0], 4, "first client of group 3 should have ID 1");
is(
	@groupIDs = sort($configDB->fetchGroupIDsOfClient(0)),
	0, "default client should have no group-IDs"
);
is(
	@groupIDs = sort($configDB->fetchGroupIDsOfClient(1)),
	0, "client 1 should have no group-ID"
);
is(
	@groupIDs = sort($configDB->fetchGroupIDsOfClient(3)),
	0, "client 3 should have no group-IDs"
);
is(
	@groupIDs = sort($configDB->fetchGroupIDsOfClient(4)),
	1, "client 4 should have one group-ID"
);
is($groupIDs[0], 3, "first group of client 4 should have ID 3");

ok(
	$configDB->removeClientIDsFromGroup(3, [6]),
	'removing an unassociated client-ID should have no effect'
);
is(
	@groupIDs = sort($configDB->fetchClientIDsOfGroup(3)),
	1, "group 3 should have one client-ID"
);
ok(
	$configDB->removeClient(4),
	'removing a client should drop group associations, too'
);
is(
	@groupIDs = sort($configDB->fetchClientIDsOfGroup(3)),
	0, "group 3 should have no more client-ID"
);

$configDB->disconnect();
