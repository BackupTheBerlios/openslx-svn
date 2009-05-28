use Test::More qw(no_plan);

use strict;
use warnings;

use lib '/opt/openslx/lib';

# basic init
use OpenSLX::ConfigDB;

my $configDB = OpenSLX::ConfigDB->new;
$configDB->connect();

# fetch clients & systems
my @clients = sort { $a->{id} <=> $b->{id} } $configDB->fetchClientByFilter();
is(@clients, 3, 'should have got 3 clients (default, 1 and 3)');
my $defaultClient = shift @clients;
my $client1 = shift @clients;
my $client3 = shift @clients;

my @systems = sort { $a->{id} <=> $b->{id} } $configDB->fetchSystemByFilter();
is(@systems, 3, 'should have got 3 systems (default, 1 and 3)');
my $defaultSystem = shift @systems;
my $system1 = shift @systems;
my $system3 = shift @systems;

foreach my $client ($defaultClient, $client1, $client3) {
    is(
        my @systemIDs = $configDB->fetchSystemIDsOfClient($client->{id}),
        0, "client $client->{id} has no system-IDs yet"
    );
}

foreach my $system ($defaultSystem, $system1, $system3) {
    is(
        my @clientIDs = $configDB->fetchClientIDsOfSystem($system->{id}),
        0, "system $system->{id} has no client-IDs yet"
    );
}

ok(
    $configDB->addSystemIDsToClient(1, [3]),
    'system-ID 3 has been associated to client 1'
);
is(
    my @systemIDs = sort($configDB->fetchSystemIDsOfClient(0)),
    0, "default client should have no system-ID"
);
is(
    @systemIDs = sort($configDB->fetchSystemIDsOfClient(1)),
    1, "client 1 should have one system-ID"
);
is($systemIDs[0], 3, "first system of client 1 should have ID 3");
is(
    @systemIDs = sort($configDB->fetchSystemIDsOfClient(3)),
    0, "client 3 should have no system-ID"
);
is(
    my @clientIDs = sort($configDB->fetchClientIDsOfSystem(0)),
    0, "default system should have no client-IDs"
);
is(
    @clientIDs = sort($configDB->fetchClientIDsOfSystem(1)),
    0, "system 1 should have no client-IDs"
);
is(
    @clientIDs = sort($configDB->fetchClientIDsOfSystem(3)),
    1, "system 3 should have one client-ID"
);
is($clientIDs[0], 1, "first client of system 3 should have ID 1");

ok(
    $configDB->addSystemIDsToClient(3, [1,3,3,1,3]),
    'system-IDs 1 and 3 have been associated to client 3'
);
is(
    @systemIDs = sort($configDB->fetchSystemIDsOfClient(0)),
    0, "default client should have no system-IDs"
);
is(
    @systemIDs = sort($configDB->fetchSystemIDsOfClient(1)),
    1, "client 1 should have one system-ID"
);
is($systemIDs[0], 3, "first system of client 1 should have ID 3");
is(
    @systemIDs = sort($configDB->fetchSystemIDsOfClient(3)),
    2, "client 3 should have two system-IDs"
);
is($systemIDs[0], 1, "first system of client 3 should have ID 1");
is($systemIDs[1], 3, "second system of client 3 should have ID 3");
is(
    @clientIDs = sort($configDB->fetchClientIDsOfSystem(0)),
    0, "default system should have no client-ID"
);
is(
    @clientIDs = sort($configDB->fetchClientIDsOfSystem(1)),
    1, "system 1 should have one client-ID"
);
is($clientIDs[0], 3, "first client of system 1 should have ID 3");
is(
    @clientIDs = sort($configDB->fetchClientIDsOfSystem(3)),
    2, "system 3 should have two client-IDs"
);
is($clientIDs[0], 1, "first client of system 3 should have ID 1");
is($clientIDs[1], 3, "second client of system 3 should have ID 3");

ok(
    $configDB->setClientIDsOfSystem(3, []),
    'client-IDs of system 3 have been set to empty array'
);
is(
    @clientIDs = sort($configDB->fetchClientIDsOfSystem(3)),
    0, "system 3 should have no client-IDs"
);
is(
    @systemIDs = sort($configDB->fetchSystemIDsOfClient(1)),
    0, "client 1 should have no system-IDs"
);
is(
    @systemIDs = sort($configDB->fetchSystemIDsOfClient(3)),
    1, "client 3 should have one system-ID"
);
is($systemIDs[0], 1, "first system of client 3 should have ID 1");

ok(
    $configDB->addSystemIDsToClient(1, [0]),
    'associating the default system should have no effect'
);
is(
    @systemIDs = sort($configDB->fetchSystemIDsOfClient(1)),
    0, "client 1 should still have no system-ID"
);

ok(
    $configDB->removeClientIDsFromSystem(1, [1]),
    'removing an unassociated client-ID should have no effect'
);
is(
    @clientIDs = sort($configDB->fetchClientIDsOfSystem(1)),
    1, "system 1 should have one client-ID"
);
ok(
    $configDB->removeClientIDsFromSystem(1, [3]),
    'removing an associated client-ID should work'
);
is(
    @clientIDs = sort($configDB->fetchClientIDsOfSystem(1)),
    0, "system 1 should have no more client-ID"
);

$configDB->addSystem({
    'name'      => 'sys-4',
    'export_id' => 1,
    'comment'   => 'shortlived',
});
ok(
    $configDB->addClientIDsToSystem(4, [0]),
    'default client has been associated to system 4'
);
is(
    @systemIDs = sort($configDB->fetchSystemIDsOfClient(0)),
    1, "default client should have one system-ID"
);
is($systemIDs[0], 4, "first system of default client should have ID 4");
is(
    @systemIDs = sort($configDB->fetchSystemIDsOfClient(1)),
    0, "client 1 should have no system-ID"
);
is(
    @systemIDs = sort($configDB->fetchSystemIDsOfClient(3)),
    0, "client 3 should have no system-ID"
);
is(
    @clientIDs = sort($configDB->fetchClientIDsOfSystem(0)),
    0, "default system should have no client-IDs"
);
is(
    @clientIDs = sort($configDB->fetchClientIDsOfSystem(1)),
    0, "system 1 should have no client-ID"
);
is(
    @clientIDs = sort($configDB->fetchClientIDsOfSystem(3)),
    0, "system 3 should have no client-IDs"
);
is(
    @clientIDs = sort($configDB->fetchClientIDsOfSystem(4)),
    1, "system 4 should have one client-ID"
);
is($clientIDs[0], 0, "first client of system 4 should have ID 0");

ok(
    $configDB->removeSystemIDsFromClient(0, [6]),
    'removing an unassociated system-ID should have no effect'
);
is(
    @clientIDs = sort($configDB->fetchSystemIDsOfClient(0)),
    1, "default client should have one system-ID"
);
ok(
    $configDB->removeSystem(4),
    'removing a system should drop client associations, too'
);
is(
    @clientIDs = sort($configDB->fetchSystemIDsOfClient(0)),
    0, "default client should have no more system-ID"
);

$configDB->disconnect();
