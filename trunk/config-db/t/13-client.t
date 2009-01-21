use Test::More qw(no_plan);

use lib '/opt/openslx/lib';

# basic init
use OpenSLX::ConfigDB;

my $configDB = OpenSLX::ConfigDB->new;
$configDB->connect();

ok(
	my $client = $configDB->fetchClientByFilter, 
	'one client [default] should exist (scalar context)'
);

foreach my $requiredCol (qw(name mac)) {
	my $wrongClient = {
		'name'    => 'name',
		'mac'     => '01:02:03:04:05:06',
		'comment' => 'has column missing',
	};
	delete $wrongClient->{$requiredCol};
	ok(
		! eval { my $clientID = $configDB->addClient($wrongClient); },
		"inserting a client without '$requiredCol' column should fail"
	);
}

is(
	my @clients = $configDB->fetchClientByFilter, 1, 
	'still just one client [default] should exist (array context)'
);

my $inClient1 = {
	'name'    => 'cli-1',
	'mac'     => '01:02:03:04:05:01',
	'comment' => '',
};
is(
	my $client1ID = $configDB->addClient($inClient1), 1,
	'first client has ID 1'
);

my $inClient2 = {
	'name'       => 'cli-2.0',
	'unbootable' => 1,
	'mac'        => '01:02:03:04:05:02',
	'comment'    => undef,
	'boot_type'  => 'etherboot',
};
my $fullClient = {
	'name'          => 'cli-nr-3',
	'mac'           => '01:02:03:04:05:03',
	'comment'       => 'nuff said',
	'kernel_params' => 'debug=3 console=ttyS1',
	'unbootable'    => '0',
	'boot_type'     => 'pxe',
};
ok(
	my ($client2ID, $client3ID) = $configDB->addClient([
		$inClient2, $fullClient
	]),
	'add two more clients'
);
is($client2ID, 2, 'client 2 should have ID=2');
is($client3ID, 3, 'client 3 should have ID=3');

# fetch client 3 by id and check all values
ok(my $client3 = $configDB->fetchClientByID(3), 'fetch client 3');
is($client3->{id},            '3',                     'client 3 - id');
is($client3->{name},          'cli-nr-3',              'client 3 - name');
is($client3->{mac},           '01:02:03:04:05:03',     'client 3 - mac');
is($client3->{comment},       'nuff said',             'client 3 - comment');
is($client3->{boot_type},     'pxe',                   'client 3 - boot_type');
is($client3->{kernel_params}, 'debug=3 console=ttyS1', 'client 3 - kernel_params');
is($client3->{unbootable},    '0',                     'client 3 - unbootable');

# fetch client 2 by a filter on id and check all values
ok(
	my $client2 = $configDB->fetchClientByFilter({ id => 2 }), 
	'fetch client 2 by filter on id'
);
is($client2->{id},         2,                   'client 2 - id');
is($client2->{name},       'cli-2.0',           'client 2 - name');
is($client2->{unbootable}, '1',                 'client 2 - unbootable');
is($client2->{mac},        '01:02:03:04:05:02', 'client 2 - mac');
is($client2->{comment},    undef,               'client 2 - comment');
is($client2->{boot_type},  'etherboot',         'client 2 - boot_type');

# fetch client 1 by filter on name and check all values
ok(
	my $client1 = $configDB->fetchClientByFilter({ name => 'cli-1' }), 
	'fetch client 1 by filter on name'
);
is($client1->{id},            1,                   'client 1 - id');
is($client1->{name},          'cli-1',             'client 1 - name');
is($client1->{mac},           '01:02:03:04:05:01', 'client 1 - mac');
is($client1->{unbootable},    undef,               'client 1 - unbootable');
is($client1->{comment},       '',                  'client 1 - comment');
is($client1->{boot_type},     'pxe',               'client 1 - boot_type');
is($client1->{kernel_params}, undef,               'client 1 - kernel_params');

# fetch clients 3 & 1 by id
ok(
	my @clients3And1 = $configDB->fetchClientByID([3, 1]), 
	'fetch clients 3 & 1 by id'
);
is(@clients3And1, 2, 'should have got 2 clients');
# now sort by ID and check if we have really got 3 and 1
@clients3And1 = sort { $a->{id} cmp $b->{id} } @clients3And1;
is($clients3And1[0]->{id}, 1, 'first id should be 1');
is($clients3And1[1]->{id}, 3, 'second id should be 3');

# fetching clients by id without giving any should yield undef
is(
	$configDB->fetchClientByID(), undef,
	'fetch clients by id without giving any'
);

# fetching clients by filter without giving any should yield all of them
ok(
	@clients = $configDB->fetchClientByFilter(),
	'fetch clients by filter without giving any'
);
is(@clients, 4, 'should have got all four clients');

# fetch clients 1 & 2 by filter on boot_type
ok(
	my @clients1And3 = $configDB->fetchClientByFilter({ boot_type => 'pxe' }), 
	'fetch clients 1 & 3 by filter on boot_type'
);
is(@clients1And3, 2, 'should have got 2 clients');
# now sort by ID and check if we have really got 1 and 3
@clients1And2 = sort { $a->{id} cmp $b->{id} } @clients1And3;
is($clients1And3[0]->{id}, 1, 'first id should be 1');
is($clients1And3[1]->{id}, 3, 'second id should be 3');

# try to fetch with multi-column filter
ok(
	($client1, $client3)
		= $configDB->fetchClientByFilter({ boot_type => 'pxe', id => 1 }), 
	'fetching client with boot_type=pxe and id=1 should work'
);
is($client1->{name}, 'cli-1', 'should have got cli-1');
is($client3, undef, 'should not get cli-nr-3');

# try to fetch multiple occurrences of the same client, combined with
# some unknown IDs
ok(
	my @clients1And3 = $configDB->fetchClientByID([ 1, 21, 4-1, 1, 4, 1, 1 ]), 
	'fetch a complex set of clients by ID'
);
is(@clients1And3, 2, 'should have got 2 clients');
# now sort by ID and check if we have really got 1 and 3
@clients1And3 = sort { $a->{id} cmp $b->{id} } @clients1And3;
is($clients1And3[0]->{id}, 1, 'first id should be 1');
is($clients1And3[1]->{id}, 3, 'second id should be 3');

# try to fetch a couple of non-existing clients by id
is(
	$configDB->fetchClientByID(-1), undef, 
	'client with id -1 should not exist'
);
ok($configDB->fetchClientByID(0), 'client with id 0 should exist');
is(
	$configDB->fetchClientByID(1 << 31 + 1000), undef, 
	'trying to fetch another unknown client'
);

# try to fetch a couple of non-existing clients by filter
is(
	$configDB->fetchClientByFilter({ id => 4 }), undef, 
	'fetching client with id=4 by filter should fail'
);
is(
	$configDB->fetchClientByFilter({ name => 'cli-1.x' }), undef, 
	'fetching client with name="cli-1.x" should fail'
);
is(
	$configDB->fetchClientByFilter({ mac => '01:01:01:01:01:01', id => 1 }), undef, 
	'fetching client with mac=01:01:01:01:01:01 and id=1 should fail'
);

# rename client 1 and then fetch it by its new name
ok($configDB->changeClient(1, { name => q{CLI-'1'} }), 'changing client 1');
ok(
	$client1 = $configDB->fetchClientByFilter({ name => q{CLI-'1'} }), 
	'fetching renamed client 1'
);
is($client1->{id},   1,          'really got client number 1');
is($client1->{name}, q{CLI-'1'}, q{really got client named "CLI-'1'"});

# changing a non-existing column should fail
ok(
	! eval { $configDB->changeClient(1, { xname => "xx" }) }, 
	'changing unknown colum should fail'
);

ok(! $configDB->changeClient(1, { id => 23 }), 'changing id should fail');

# now remove an client and check if that worked
ok($configDB->removeClient(2), 'removing client 2 should be ok');
is($configDB->fetchClientByID(2, 'id'), undef, 'client 2 should be gone');
is($configDB->fetchClientByID(1)->{id}, 1, 'client 1 should still exist');
is($configDB->fetchClientByID(3)->{id}, 3, 'client 3 should still exist');

$configDB->disconnect();

