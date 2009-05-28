use Test::More qw(no_plan);

use strict;
use warnings;

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
    'attrs'     => {
        'slxgrp'     => 'slxgrp',
        'start_snmp' => 'no',
        'start_sshd' => 'yes',
    },
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
    'attrs' => {
        'automnt_dir'       => 'a',
        'automnt_src'       => 'b',
        'country'           => 'c',
        'dm_allow_shutdown' => 'd',
        'hw_graphic'        => 'e',
        'hw_monitor'        => 'f',
        'hw_mouse'          => 'g',
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
    my ($group2ID, $group3ID) = $configDB->addGroup([
        $inGroup2, $fullGroup
    ]),
    'add two more groups'
);
is($group2ID, 2, 'group 2 should have ID=2');
is($group3ID, 3, 'group 3 should have ID=3');

# fetch group 3 by id and check all values
ok(my $group3 = $configDB->fetchGroupByID(3), 'fetch group 3');
is($group3->{id},                         '3',         'group 3 - id');
is($group3->{name},                       'grp-nr-3',  'group 3 - name');
is($group3->{priority},                   50,          'group 3 - priority');
is($group3->{comment},                    'nuff said', 'group 3 - comment');
is($group3->{attrs}->{automnt_dir},       'a',         'group 3 - attr automnt_dir');
is($group3->{attrs}->{automnt_src},       'b',         'group 3 - attr automnt_src');
is($group3->{attrs}->{country},           'c',         'group 3 - attr country');
is($group3->{attrs}->{dm_allow_shutdown}, 'd',         'group 3 - attr dm_allow_shutdown');
is($group3->{attrs}->{hw_graphic},        'e',         'group 3 - attr hw_graphic');
is($group3->{attrs}->{hw_monitor},        'f',         'group 3 - attr hw_monitor');
is($group3->{attrs}->{hw_mouse},          'g',         'group 3 - attr hw_mouse');
is($group3->{attrs}->{late_dm},           'h',         'group 3 - attr late_dm');
is($group3->{attrs}->{netbios_workgroup}, 'i',         'group 3 - attr netbios_workgroup');
is($group3->{attrs}->{nis_domain},        'j',         'group 3 - attr nis_domain');
is($group3->{attrs}->{nis_servers},       'k',         'group 3 - attr nis_servers');
is($group3->{attrs}->{sane_scanner},      'p',         'group 3 - attr sane_scanner');
is($group3->{attrs}->{scratch},           'q',         'group 3 - attr scratch');
is($group3->{attrs}->{slxgrp},            'r',         'group 3 - attr slxgrp');
is($group3->{attrs}->{start_alsasound},   's',         'group 3 - attr start_alsasound');
is($group3->{attrs}->{start_atd},         't',         'group 3 - attr start_atd');
is($group3->{attrs}->{start_cron},        'u',         'group 3 - attr start_cron');
is($group3->{attrs}->{start_dreshal},     'v',         'group 3 - attr start_dreshal');
is($group3->{attrs}->{start_ntp},         'w',         'group 3 - attr start_ftp');
is($group3->{attrs}->{start_nfsv4},       'x',         'group 3 - attr start_nfsv4');
is($group3->{attrs}->{start_printer},     'y',         'group 3 - attr start_printer');
is($group3->{attrs}->{start_samba},       'z',         'group 3 - attr start_samba');
is($group3->{attrs}->{start_snmp},        'A',         'group 3 - attr start_snmp');
is($group3->{attrs}->{start_sshd},        'B',         'group 3 - attr start_sshd');
is($group3->{attrs}->{start_syslog},      'C',         'group 3 - attr start_syslog');
is($group3->{attrs}->{start_x},           'D',         'group 3 - attr start_x');
is($group3->{attrs}->{start_xdmcp},       'E',         'group 3 - attr start_xdmcp');
is($group3->{attrs}->{tex_enable},        'F',         'group 3 - attr tex_enable');
is($group3->{attrs}->{timezone},          'G',         'group 3 - attr timezone');
is($group3->{attrs}->{tvout},             'H',         'group 3 - attr tvout');
is($group3->{attrs}->{vmware},            'I',         'group 3 - attr vmware');
is(keys %{$group3->{attrs}},              31,          'group 3 - attribute count');

# fetch group 2 by a filter on id and check all values
ok(
    my $group2 = $configDB->fetchGroupByFilter({ id => 2 }), 
    'fetch group 2 by filter on id'
);
is($group2->{id},       2,         'group 2 - id');
is($group2->{name},     'grp-2.0', 'group 2 - name');
is($group2->{priority}, 30,        'group 2 - priority');
is($group2->{comment},  undef,     'group 2 - comment');
is(keys %{$group2->{attrs}}, 0,    'group 2 - attribute count');

# fetch group 1 by filter on name and check all values
ok(
    my $group1 = $configDB->fetchGroupByFilter({ name => 'grp-1' }), 
    'fetch group 1 by filter on name'
);
is($group1->{id},                 1,         'group 1 - id');
is($group1->{name},               'grp-1',   'group 1 - name');
is($group1->{priority},           50,        'group 1 - priority');
is($group1->{comment},            '',        'group 1 - comment');
is(keys %{$group1->{attrs}},       3,        'group 1 - attribute count');
is($group1->{attrs}->{slxgrp},     'slxgrp', 'group 1 - attr slxgrp');
is($group1->{attrs}->{start_snmp}, 'no',     'group 1 - attr start_snmp');
is($group1->{attrs}->{start_sshd}, 'yes',    'group 1 - attr start_sshd');

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

# fetch group 2 by filter on comment being undef'd
ok(
    my @group2Only = $configDB->fetchGroupByFilter({ comment => undef }), 
    'fetch group 2 by filter on comment being undefined'
);
is(@group2Only, 1, 'should have got 1 group');
is($group2Only[0]->{id}, 2, 'first id should be 2');

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

# filter groups by different attributes & values in combination
ok( 
    my @group1Only = $configDB->fetchGroupByFilter( {}, undef, { 
        start_snmp => 'no',
    } ),
    'fetch group 1 by filter on attribute start_snmp'
);

is(@group1Only, 1, 'should have got 1 group');
is($group1Only[0]->{id}, 1, 'first id should be 1');

ok(
    @group1Only = $configDB->fetchGroupByFilter( undef, 'id', { 
        start_snmp => 'no',
        tex_enable => undef,
    } ),
    'fetch group 1 by filter on attribute start_snmp + non-existing attr'
);
is(@group1Only, 1, 'should have got 1 group');
is($group1Only[0]->{id}, 1, 'first id should be 1');

ok(
    @group1Only = $configDB->fetchGroupByFilter( {
        name     => 'grp-1',
        priority => 50,
    }, 'id', {
        start_snmp => 'no',
        tex_enable => undef,
    } ),
    'fetch group 1 by multiple filter on values and attributes'
);
is(@group1Only, 1, 'should have got 1 group');
is($group1Only[0]->{id}, 1, 'first id should be 1');

is(
    $configDB->fetchGroupByFilter( {
        comment => 'xxx',
    }, 'id', {
        start_snmp => 'no',
        tex_enable => undef,
    } ),
    undef,
    'mismatch group 1 by filter with incorrect value'
);
is(
    $configDB->fetchGroupByFilter( {
        name => 'grp-1',
    }, 'id', {
        start_snmp => 'yes',
        tex_enable => undef,
    } ),
    undef,
    'mismatch group 1 by filter with incorrect attribute value'
);
is(
    $configDB->fetchGroupByFilter( {
        name => 'grp-1',
    }, 'id', {
        start_sshd => undef,
    } ),
    undef,
    'mismatch group 1 by filter with attribute not being empty'
);

# fetch groups 1 & 2 by filter on attribute start_samba not existing
ok(
    my @groups1And2 = $configDB->fetchGroupByFilter( {}, undef, {
        start_samba => undef,
    } ), 
    'fetch groups 1 & 2 by filter on attribute start_samba not existing'
);
is(@groups1And2, 2, 'should have got 2 groups');
# now sort by ID and check if we have really got 1 and 2
@groups1And2 = sort { $a->{id} cmp $b->{id} } @groups1And2;
is($groups1And2[0]->{id}, 1, 'first id should be 1');
is($groups1And2[1]->{id}, 2, 'second id should be 2');

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

# changing nothing at all should succeed
ok($configDB->changeGroup(1), 'changing nothing at all in group 1');

# adding attributes should work
$inGroup1->{attrs}->{slxgrp} = 'slxgrp1';
$inGroup1->{attrs}->{vmware} = 'yes';
ok($configDB->changeGroup(1, $inGroup1), 'adding attrs to group 1');
$group1 = $configDB->fetchGroupByID(1);
is($group1->{attrs}->{slxgrp}, 'slxgrp1', 'attr slxgrp has correct value');
is($group1->{attrs}->{vmware}, 'yes', 'attr vmware has correct value');

# changing an attribute should work
$inGroup1->{attrs}->{vmware} = 'no';
ok($configDB->changeGroup(1, $inGroup1), 'changing vmware in group 1');
$group1 = $configDB->fetchGroupByID(1);
is($group1->{attrs}->{slxgrp}, 'slxgrp1', 'attr slxgrp has correct value');
is($group1->{attrs}->{vmware}, 'no', 'attr vmware has correct value');

# deleting an attribute should remove it
delete $inGroup1->{attrs}->{slxgrp};
ok($configDB->changeGroup(1, $inGroup1), 'changing slxgrp in group 1');
$group1 = $configDB->fetchGroupByID(1);
ok(!exists $group1->{attrs}->{slxgrp}, 'attr slxgrp should be gone');

# undef'ing an attribute should remove it, too
$inGroup1->{attrs}->{vmware} = undef;
ok($configDB->changeGroup(1, $inGroup1), 'undefining vmware in group 1');
$group1 = $configDB->fetchGroupByID(1);
ok(!exists $group1->{attrs}->{vmware}, 'attr vmware should be gone');

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

