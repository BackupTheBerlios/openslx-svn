use Test::More qw(no_plan);

use strict;
use warnings;

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
    'attrs'     => {
        'slxgrp'     => 'slxgrp',
        'start_snmp' => 'no',
        'start_sshd' => 'yes',
    },
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
    'unbootable'    => '0',
    'boot_type'     => 'pxe',
    'attrs' => {
        'automnt_dir'       => 'a',
        'automnt_src'       => 'b',
        'country'           => 'c',
        'dm_allow_shutdown' => 'd',
        'hw_graphic'        => 'e',
        'hw_monitor'        => 'f',
        'hw_mouse'          => 'g',
        'kernel_params_client' => 'debug=3 console=ttyS1',
        'late_dm'           => 'h',
        'netbios_workgroup' => 'i',
        'nis_domain'        => 'j',
        'nis_servers'       => 'k',
        'sane_scanner'      => 'p',
        'scratch'           => 'q',
        'slxgrp'            => 'r',
        'start_alsasound'   => 's',
        'start_atd'         => 't',
        'start_cron'        => 'u',
        'start_dreshal'     => 'v',
        'start_ntp'         => 'w',
        'start_nfsv4'       => 'x',
        'start_printer'     => 'y',
        'start_samba'       => 'z',
        'start_snmp'        => 'A',
        'start_sshd'        => 'B',
        'start_syslog'      => 'C',
        'start_x'           => 'D',
        'start_xdmcp'       => 'E',
        'tex_enable'        => 'F',
        'timezone'          => 'G',
        'tvout'             => 'H',
        'vmware'            => 'I',
    },
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
is($client3->{unbootable},    '0',                     'client 3 - unbootable');
is($client3->{attrs}->{automnt_dir},       'a',              'client 3 - attr automnt_dir');
is($client3->{attrs}->{automnt_src},       'b',              'client 3 - attr automnt_src');
is($client3->{attrs}->{country},           'c',              'client 3 - attr country');
is($client3->{attrs}->{dm_allow_shutdown}, 'd',              'client 3 - attr dm_allow_shutdown');
is($client3->{attrs}->{hw_graphic},        'e',              'client 3 - attr hw_graphic');
is($client3->{attrs}->{hw_monitor},        'f',              'client 3 - attr hw_monitor');
is($client3->{attrs}->{hw_mouse},          'g',              'client 3 - attr hw_mouse');
is($client3->{attrs}->{kernel_params_client}, 'debug=3 console=ttyS1', 'client 3 - attr kernel_params_client');
is($client3->{attrs}->{late_dm},           'h',              'client 3 - attr late_dm');
is($client3->{attrs}->{netbios_workgroup}, 'i',              'client 3 - attr netbios_workgroup');
is($client3->{attrs}->{nis_domain},        'j',              'client 3 - attr nis_domain');
is($client3->{attrs}->{nis_servers},       'k',              'client 3 - attr nis_servers');
is($client3->{attrs}->{sane_scanner},      'p',              'client 3 - attr sane_scanner');
is($client3->{attrs}->{scratch},           'q',              'client 3 - attr scratch');
is($client3->{attrs}->{slxgrp},            'r',              'client 3 - attr slxgrp');
is($client3->{attrs}->{start_alsasound},   's',              'client 3 - attr start_alsasound');
is($client3->{attrs}->{start_atd},         't',              'client 3 - attr start_atd');
is($client3->{attrs}->{start_cron},        'u',              'client 3 - attr start_cron');
is($client3->{attrs}->{start_dreshal},     'v',              'client 3 - attr start_dreshal');
is($client3->{attrs}->{start_ntp},         'w',              'client 3 - attr start_ftp');
is($client3->{attrs}->{start_nfsv4},       'x',              'client 3 - attr start_nfsv4');
is($client3->{attrs}->{start_printer},     'y',              'client 3 - attr start_printer');
is($client3->{attrs}->{start_samba},       'z',              'client 3 - attr start_samba');
is($client3->{attrs}->{start_snmp},        'A',              'client 3 - attr start_snmp');
is($client3->{attrs}->{start_sshd},        'B',              'client 3 - attr start_sshd');
is($client3->{attrs}->{start_syslog},      'C',              'client 3 - attr start_syslog');
is($client3->{attrs}->{start_x},           'D',              'client 3 - attr start_x');
is($client3->{attrs}->{start_xdmcp},       'E',              'client 3 - attr start_xdmcp');
is($client3->{attrs}->{tex_enable},        'F',              'client 3 - attr tex_enable');
is($client3->{attrs}->{timezone},          'G',              'client 3 - attr timezone');
is($client3->{attrs}->{tvout},             'H',              'client 3 - attr tvout');
is($client3->{attrs}->{vmware},            'I',              'client 3 - attr vmware');
is(keys %{$client3->{attrs}},              31,               'client 3 - attribute count');

# fetch client 2 by a filter on id and check all values
ok(
    my $client2 = $configDB->fetchClientByFilter({ id => 2 }), 
    'fetch client 2 by filter on id'
);
is($client2->{id},            2,                   'client 2 - id');
is($client2->{name},          'cli-2.0',           'client 2 - name');
is($client2->{unbootable},    '1',                 'client 2 - unbootable');
is($client2->{mac},           '01:02:03:04:05:02', 'client 2 - mac');
is($client2->{comment},       undef,               'client 2 - comment');
is($client2->{boot_type},     'etherboot',         'client 2 - boot_type');
is(keys %{$client2->{attrs}}, 0,                   'client 2 - attribute count');

# fetch client 1 by filter on name and check all values
ok(
    my $client1 = $configDB->fetchClientByFilter({ name => 'cli-1' }), 
    'fetch client 1 by filter on name'
);
is($client1->{id},            1,                   'client 1 - id');
is($client1->{name},          'cli-1',             'client 1 - name');
is($client1->{mac},           '01:02:03:04:05:01', 'client 1 - mac');
is($client1->{comment},       '',                  'client 1 - comment');
is(keys %{$client1->{attrs}}, 3,                   'client 1 - attribute count');
is($client1->{attrs}->{slxgrp},     'slxgrp',      'client 1 - attr slxgrp');
is($client1->{attrs}->{start_snmp}, 'no',          'client 1 - attr start_snmp');
is($client1->{attrs}->{start_sshd}, 'yes',         'client 1 - attr start_sshd');

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
@clients1And3 = sort { $a->{id} cmp $b->{id} } @clients1And3;
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

# fetch client 1 by filter on unbootable being undef'd
ok(
    my @client1Only = $configDB->fetchClientByFilter({ unbootable => undef }), 
    'fetch client 1 by filter on unbootable being undefined'
);
is(@client1Only, 1, 'should have got 1 client');
is($client1Only[0]->{id}, 1, 'first id should be 1');

# try to fetch multiple occurrences of the same client, combined with
# some unknown IDs
ok(
    @clients1And3 = $configDB->fetchClientByID([ 1, 21, 4-1, 1, 4, 1, 1 ]), 
    'fetch a complex set of clients by ID'
);
is(@clients1And3, 2, 'should have got 2 clients');
# now sort by ID and check if we have really got 1 and 3
@clients1And3 = sort { $a->{id} cmp $b->{id} } @clients1And3;
is($clients1And3[0]->{id}, 1, 'first id should be 1');
is($clients1And3[1]->{id}, 3, 'second id should be 3');

# filter clients by different attributes & values in combination
ok( 
    @client1Only = $configDB->fetchClientByFilter( {}, undef, { 
        start_snmp => 'no',
    } ),
    'fetch client 1 by filter on attribute start_snmp'
);

is(@client1Only, 1, 'should have got 1 client');
is($client1Only[0]->{id}, 1, 'first id should be 1');

ok(
    @client1Only = $configDB->fetchClientByFilter( undef, 'id', { 
        start_snmp => 'no',
        tex_enable => undef,
    } ),
    'fetch client 1 by filter on attribute start_snmp + non-existing attr'
);
is(@client1Only, 1, 'should have got 1 client');
is($client1Only[0]->{id}, 1, 'first id should be 1');

ok(
    @client1Only = $configDB->fetchClientByFilter( {
        name       => 'cli-1',
        unbootable => undef,
    }, 'id', {
        start_snmp => 'no',
        tex_enable => undef,
    } ),
    'fetch client 1 by multiple filter on values and attributes'
);
is(@client1Only, 1, 'should have got 1 client');
is($client1Only[0]->{id}, 1, 'first id should be 1');

is(
    $configDB->fetchClientByFilter( {
        comment => 'xxx',
    }, 'id', {
        start_snmp => 'no',
        tex_enable => undef,
    } ),
    undef,
    'mismatch client 1 by filter with incorrect value'
);
is(
    $configDB->fetchClientByFilter( {
        name => 'cli-1',
    }, 'id', {
        start_snmp => 'yes',
        tex_enable => undef,
    } ),
    undef,
    'mismatch client 1 by filter with incorrect attribute value'
);
is(
    $configDB->fetchClientByFilter( {
        name => 'cli-1',
    }, 'id', {
        start_sshd => undef,
    } ),
    undef,
    'mismatch client 1 by filter with attribute not being empty'
);

# fetch clients 0, 1 & 2 by filter on attribute start_samba not existing
ok(
    my @clients01And2 = $configDB->fetchClientByFilter( {}, undef, {
        start_samba => undef,
    } ), 
    'fetch clients 0,1 & 2 by filter on attribute start_samba not existing'
);
is(@clients01And2, 3, 'should have got 3 clients');
# now sort by ID and check if we have really got 0, 1 and 2
@clients01And2 = sort { $a->{id} cmp $b->{id} } @clients01And2;
is($clients01And2[0]->{id}, 0, 'first id should be 0');
is($clients01And2[1]->{id}, 1, 'second id should be 1');
is($clients01And2[2]->{id}, 2, 'third id should be 2');

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

# changing nothing at all should succeed
ok($configDB->changeClient(1), 'changing nothing at all in client 1');

# adding attributes should work
$inClient1->{attrs}->{slxgrp} = 'slxgrp1';
$inClient1->{attrs}->{vmware} = 'yes';
ok($configDB->changeClient(1, $inClient1), 'adding attrs to client 1');
$client1 = $configDB->fetchClientByID(1);
is($client1->{attrs}->{slxgrp}, 'slxgrp1', 'attr slxgrp has correct value');
is($client1->{attrs}->{vmware}, 'yes', 'attr vmware has correct value');

# changing an attribute should work
$inClient1->{attrs}->{vmware} = 'no';
ok($configDB->changeClient(1, $inClient1), 'changing vmware in client 1');
$client1 = $configDB->fetchClientByID(1);
is($client1->{attrs}->{slxgrp}, 'slxgrp1', 'attr slxgrp has correct value');
is($client1->{attrs}->{vmware}, 'no', 'attr vmware has correct value');

# deleting an attribute should remove it
delete $inClient1->{attrs}->{slxgrp};
ok($configDB->changeClient(1, $inClient1), 'changing slxgrp in client 1');
$client1 = $configDB->fetchClientByID(1);
ok(!exists $client1->{attrs}->{slxgrp}, 'attr slxgrp should be gone');

# undef'ing an attribute should remove it, too
$inClient1->{attrs}->{vmware} = undef;
ok($configDB->changeClient(1, $inClient1), 'undefining vmware in client 1');
$client1 = $configDB->fetchClientByID(1);
ok(!exists $client1->{attrs}->{vmware}, 'attr vmware should be gone');

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

