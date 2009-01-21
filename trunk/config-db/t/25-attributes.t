use Test::More qw(no_plan);

use strict;
use warnings;

use lib '/opt/openslx/lib';

# basic init
use OpenSLX::ConfigDB qw(:support);

my $configDB = OpenSLX::ConfigDB->new;
$configDB->connect();

my $defaultAttrs = {	# mostly copied from DBSchema
	'ramfs_fsmods' => '',
	'ramfs_miscmods' => '',
	'ramfs_nicmods' => 'forcedeth e1000 e100 tg3 via-rhine r8169 pcnet32',
	'ramfs_screen' => '',

	'automnt_dir' => '',
	'automnt_src' => '',
	'country' => 'de',
	'dm_allow_shutdown' => 'user',
	'hw_graphic' => '',
	'hw_monitor' => '',
	'hw_mouse' => '',
	'late_dm' => 'no',
	'netbios_workgroup' => 'slx-network',
	'nis_domain' => '',
	'nis_servers' => '',
	'sane_scanner' => '',
	'scratch' => '',
	'slxgrp' => '',
	'start_alsasound' => 'yes',
	'start_atd' => 'no',
	'start_cron' => 'no',
	'start_dreshal' => 'yes',
	'start_ntp' => 'initial',
	'start_nfsv4' => 'no',
	'start_printer' => 'no',
	'start_samba' => 'may',
	'start_snmp' => 'no',
	'start_sshd' => 'yes',
	'start_syslog' => 'yes',
	'start_x' => 'yes',
	'start_xdmcp' => 'kdm',
	'tex_enable' => 'no',
	'timezone' => 'Europe/Berlin',
	'tvout' => 'no',
	'vmware' => 'no',
};
ok(
	$configDB->changeSystem(0, { attrs => $defaultAttrs } ),
	'attributes of default system have been set'
);
my $defaultSystem = $configDB->fetchSystemByID(0);

my $system1 = $configDB->fetchSystemByID(1);
my $sys1Attrs = {
	'ramfs_fsmods' => 'squashfs',
	'ramfs_nicmods' => 'forcedeth e1000 r8169',
	'start_x' => 'no',
	'start_xdmcp' => '',
};
ok(
	$configDB->changeSystem(1, { attrs => $sys1Attrs } ),
	'attributes of system 1 have been set'
);

my $system3 = $configDB->fetchSystemByID(3);
my $sys3Attrs = {
	'ramfs_fsmods' => '-4',
	'ramfs_miscmods' => '-3',
	'ramfs_nicmods' => '-2',
	'ramfs_screen' => '-1',

	'automnt_dir' => '1',
	'automnt_src' => '2',
	'country' => '3',
	'dm_allow_shutdown' => '4',
	'hw_graphic' => '5',
	'hw_monitor' => '6',
	'hw_mouse' => '7',
	'late_dm' => '8',
	'netbios_workgroup' => '9',
	'nis_domain' => '10',
	'nis_servers' => '11',
	'sane_scanner' => '12',
	'scratch' => '13',
	'slxgrp' => '14',
	'start_alsasound' => '15',
	'start_atd' => '16',
	'start_cron' => '17',
	'start_dreshal' => '18',
	'start_ntp' => '19',
	'start_nfsv4' => '20',
	'start_printer' => '21',
	'start_samba' => '22',
	'start_snmp' => '23',
	'start_sshd' => '24',
	'start_syslog' => '25',
	'start_x' => '26',
	'start_xdmcp' => '27',
	'tex_enable' => '28',
	'timezone' => '29',
	'tvout' => '30',
	'vmware' => '31',
};
ok(
	$configDB->changeSystem(3, { attrs => $sys3Attrs } ),
	'attributes of system 3 have been set'
);

my $defaultClient = $configDB->fetchClientByID(0);
my $defaultClientAttrs = {
	# pretend the whole computer centre has been warped to London ;-)
	'timezone' => 'Europe/London',
	# pretend we wanted to activate snmp globally (e.g. for testing)
	'start_snmp' => 'yes',
};
ok(
	$configDB->changeClient(0, { attrs => $defaultClientAttrs } ),
	'attributes of default client have been set'
);

# check merging of default attributes, the order should be:
# default system attributes overruled by system attributes overruled by
# default client attributes:
my $shouldBeAttrs1 = {
	'ramfs_fsmods' => 'squashfs',
	'ramfs_miscmods' => '',
	'ramfs_nicmods' => 'forcedeth e1000 r8169',
	'ramfs_screen' => '',

	'automnt_dir' => '',
	'automnt_src' => '',
	'country' => 'de',
	'dm_allow_shutdown' => 'user',
	'hw_graphic' => '',
	'hw_monitor' => '',
	'hw_mouse' => '',
	'late_dm' => 'no',
	'netbios_workgroup' => 'slx-network',
	'nis_domain' => '',
	'nis_servers' => '',
	'sane_scanner' => '',
	'scratch' => '',
	'slxgrp' => '',
	'start_alsasound' => 'yes',
	'start_atd' => 'no',
	'start_cron' => 'no',
	'start_dreshal' => 'yes',
	'start_ntp' => 'initial',
	'start_nfsv4' => 'no',
	'start_printer' => 'no',
	'start_samba' => 'may',
	'start_snmp' => 'yes',
	'start_sshd' => 'yes',
	'start_syslog' => 'yes',
	'start_x' => 'no',
	'start_xdmcp' => '',
	'tex_enable' => 'no',
	'timezone' => 'Europe/London',
	'tvout' => 'no',
	'vmware' => 'no',
};
my $mergedSystem1 = $configDB->fetchSystemByID(1);
ok(
	$configDB->mergeDefaultAttributesIntoSystem($mergedSystem1),
	'merging default attributes into system 1'
);
foreach my $key (sort keys %$shouldBeAttrs1) {
	is(
		$mergedSystem1->{attrs}->{$key}, $shouldBeAttrs1->{$key}, 
		"checking merged attribute $key for system 1"
	);
}

# check merging code for completeness (using all attributes):
my $shouldBeAttrs3 = {
	'ramfs_fsmods' => '-4',
	'ramfs_miscmods' => '-3',
	'ramfs_nicmods' => '-2',
	'ramfs_screen' => '-1',

	'automnt_dir' => '1',
	'automnt_src' => '2',
	'country' => '3',
	'dm_allow_shutdown' => '4',
	'hw_graphic' => '5',
	'hw_monitor' => '6',
	'hw_mouse' => '7',
	'late_dm' => '8',
	'netbios_workgroup' => '9',
	'nis_domain' => '10',
	'nis_servers' => '11',
	'sane_scanner' => '12',
	'scratch' => '13',
	'slxgrp' => '14',
	'start_alsasound' => '15',
	'start_atd' => '16',
	'start_cron' => '17',
	'start_dreshal' => '18',
	'start_ntp' => '19',
	'start_nfsv4' => '20',
	'start_printer' => '21',
	'start_samba' => '22',
	'start_snmp' => 'yes',
	'start_sshd' => '24',
	'start_syslog' => '25',
	'start_x' => '26',
	'start_xdmcp' => '27',
	'tex_enable' => '28',
	'timezone' => 'Europe/London',
	'tvout' => '30',
	'vmware' => '31',
};
my $mergedSystem3 = $configDB->fetchSystemByID(3);
ok(
	$configDB->mergeDefaultAttributesIntoSystem($mergedSystem3),
	'merging default attributes into system 3'
);
foreach my $key (sort keys %$shouldBeAttrs3) {
	is(
		$mergedSystem3->{attrs}->{$key}, $shouldBeAttrs3->{$key}, 
		"checking merged attribute $key for system 3"
	);
}

# setup client / group relations
my $group1 = $configDB->fetchGroupByID(1);
my $group1Attrs = {
	'priority' => '50',
	# this group of clients is connected via underwater cable ...
	'timezone' => 'America/New_York',
	# ... and use a local scratch partition
	'scratch' => '/dev/sdd1',
	# the following should be a noop (as that attribute is system-specific)
#	'ramfs_nicmods' => 'e1000',
};
ok(
	$configDB->changeGroup(1, { attrs => $group1Attrs } ),
	'attributes of group 1 have been set'
);
my $group3 = $configDB->fetchGroupByID(3);
my $group3Attrs = {
	'priority' => '30',
	# this specific client group is older and thus has a different scratch
	'scratch' => '/dev/hdd1',
	'vmware' => 'yes',
};
ok(
	$configDB->changeGroup(3, { attrs => $group3Attrs } ),
	'attributes of group 3 have been set'
);
my $client1 = $configDB->fetchClientByID(1);
my $client1Attrs = {
	# this specific client uses yet another local scratch partition
	'scratch' => '/dev/sdx3',
};
ok(
	$configDB->changeClient(1, { attrs => $client1Attrs } ),
	'attributes of client 1 have been set'
);
ok(
	$configDB->setGroupIDsOfClient(1, [1]),
	'group-IDs of client 1 have been set'
);
ok(
	$configDB->setGroupIDsOfClient(3, []),
	'group-IDs of client 3 have been set'
);

# check merging of attributes into client, the order should be:
# default client attributes overruled by group attributes (ordererd by priority) 
# overruled by specific client attributes:
$shouldBeAttrs1 = {
	'ramfs_fsmods' => '',
	'ramfs_miscmods' => '',
	'ramfs_nicmods' => '',
	'ramfs_screen' => '',

	'automnt_dir' => '',
	'automnt_src' => '',
	'country' => '',
	'dm_allow_shutdown' => '',
	'hw_graphic' => '',
	'hw_monitor' => '',
	'hw_mouse' => '',
	'late_dm' => '',
	'netbios_workgroup' => '',
	'nis_domain' => '',
	'nis_servers' => '',
	'sane_scanner' => '',
	'scratch' => '/dev/sdx3',
	'slxgrp' => '',
	'start_alsasound' => '',
	'start_atd' => '',
	'start_cron' => '',
	'start_dreshal' => '',
	'start_ntp' => '',
	'start_nfsv4' => '',
	'start_printer' => '',
	'start_samba' => '',
	'start_snmp' => 'yes',
	'start_sshd' => '',
	'start_syslog' => '',
	'start_x' => '',
	'start_xdmcp' => '',
	'tex_enable' => '',
	'timezone' => 'America/New_York',
	'tvout' => '',
	'vmware' => '',
};
my $mergedClient1 = $configDB->fetchClientByID(1);
ok(
	$configDB->mergeDefaultAndGroupAttributesIntoClient($mergedClient1),
	'merging default and group attributes into client 1'
);
foreach my $key (sort keys %$shouldBeAttrs1) {
	is(
		$mergedClient1->{attrs}->{$key} || '', $shouldBeAttrs1->{$key} || '', 
		"checking merged attribute $key for client 1"
	);
}

$shouldBeAttrs3 = {
	'ramfs_fsmods' => '',
	'ramfs_miscmods' => '',
	'ramfs_nicmods' => '',
	'ramfs_screen' => '',

	'automnt_dir' => '',
	'automnt_src' => '',
	'country' => '',
	'dm_allow_shutdown' => '',
	'hw_graphic' => '',
	'hw_monitor' => '',
	'hw_mouse' => '',
	'late_dm' => '',
	'netbios_workgroup' => '',
	'nis_domain' => '',
	'nis_servers' => '',
	'sane_scanner' => '',
	'scratch' => '',
	'slxgrp' => '',
	'start_alsasound' => '',
	'start_atd' => '',
	'start_cron' => '',
	'start_dreshal' => '',
	'start_ntp' => '',
	'start_nfsv4' => '',
	'start_printer' => '',
	'start_samba' => '',
	'start_snmp' => 'yes',
	'start_sshd' => '',
	'start_syslog' => '',
	'start_x' => '',
	'start_xdmcp' => '',
	'tex_enable' => '',
	'timezone' => 'Europe/London',
	'tvout' => '',
	'vmware' => '',
};

# remove all attributes from client 3
$configDB->changeClient(3, { attrs => {} } );

my $mergedClient3 = $configDB->fetchClientByID(3);
ok(
	$configDB->mergeDefaultAndGroupAttributesIntoClient($mergedClient3),
	'merging default and group attributes into client 3'
);
foreach my $key (sort keys %$shouldBeAttrs1) {
	is(
		$mergedClient3->{attrs}->{$key} || '', $shouldBeAttrs3->{$key} || '', 
		"checking merged attribute $key for client 3"
	);
}

# now associate default client with group 3 and try again
ok(
	$configDB->setGroupIDsOfClient(0, [3]),
	'group-IDs of default client have been set'
);
$shouldBeAttrs1 = {
	'ramfs_fsmods' => '',
	'ramfs_miscmods' => '',
	'ramfs_nicmods' => '',
	'ramfs_screen' => '',

	'automnt_dir' => '',
	'automnt_src' => '',
	'country' => '',
	'dm_allow_shutdown' => '',
	'hw_graphic' => '',
	'hw_monitor' => '',
	'hw_mouse' => '',
	'late_dm' => '',
	'netbios_workgroup' => '',
	'nis_domain' => '',
	'nis_servers' => '',
	'sane_scanner' => '',
	'scratch' => '/dev/sdx3',
	'slxgrp' => '',
	'start_alsasound' => '',
	'start_atd' => '',
	'start_cron' => '',
	'start_dreshal' => '',
	'start_ntp' => '',
	'start_nfsv4' => '',
	'start_printer' => '',
	'start_samba' => '',
	'start_snmp' => 'yes',
	'start_sshd' => '',
	'start_syslog' => '',
	'start_x' => '',
	'start_xdmcp' => '',
	'tex_enable' => '',
	'timezone' => 'America/New_York',
	'tvout' => '',
	'vmware' => 'yes',
};
$mergedClient1 = $configDB->fetchClientByID(1);
ok(
	$configDB->mergeDefaultAndGroupAttributesIntoClient($mergedClient1),
	'merging default and group attributes into client 1'
);
foreach my $key (sort keys %$shouldBeAttrs1) {
	is(
		$mergedClient1->{attrs}->{$key} || '', $shouldBeAttrs1->{$key} || '', 
		"checking merged attribute $key for client 1"
	);
}

$shouldBeAttrs3 = {
	'ramfs_fsmods' => '',
	'ramfs_miscmods' => '',
	'ramfs_nicmods' => '',
	'ramfs_screen' => '',

	'automnt_dir' => '',
	'automnt_src' => '',
	'country' => '',
	'dm_allow_shutdown' => '',
	'hw_graphic' => '',
	'hw_monitor' => '',
	'hw_mouse' => '',
	'late_dm' => '',
	'netbios_workgroup' => '',
	'nis_domain' => '',
	'nis_servers' => '',
	'sane_scanner' => '',
	'scratch' => '/dev/hdd1',
	'slxgrp' => '',
	'start_alsasound' => '',
	'start_atd' => '',
	'start_cron' => '',
	'start_dreshal' => '',
	'start_ntp' => '',
	'start_nfsv4' => '',
	'start_printer' => '',
	'start_samba' => '',
	'start_snmp' => 'yes',
	'start_sshd' => '',
	'start_syslog' => '',
	'start_x' => '',
	'start_xdmcp' => '',
	'tex_enable' => '',
	'timezone' => 'Europe/London',
	'tvout' => '',
	'vmware' => 'yes',
};
$mergedClient3 = $configDB->fetchClientByID(3);
ok(
	$configDB->mergeDefaultAndGroupAttributesIntoClient($mergedClient3),
	'merging default and group attributes into client 3'
);
foreach my $key (sort keys %$shouldBeAttrs1) {
	is(
		$mergedClient3->{attrs}->{$key} || '', $shouldBeAttrs3->{$key} || '', 
		"checking merged attribute $key for client 3"
	);
}

# finally we merge systems into clients and check the outcome of that
my $fullMerge11 = { %$mergedClient1 };
ok(
	mergeAttributes($fullMerge11, $mergedSystem1),
	'merging system 1 into client 1'
);
my $shouldBeAttrs11 = {
	'ramfs_fsmods' => 'squashfs',
	'ramfs_miscmods' => '',
	'ramfs_nicmods' => 'forcedeth e1000 r8169',
	'ramfs_screen' => '',

	'automnt_dir' => '',
	'automnt_src' => '',
	'country' => 'de',
	'dm_allow_shutdown' => 'user',
	'hw_graphic' => '',
	'hw_monitor' => '',
	'hw_mouse' => '',
	'late_dm' => 'no',
	'netbios_workgroup' => 'slx-network',
	'nis_domain' => '',
	'nis_servers' => '',
	'sane_scanner' => '',
	'scratch' => '/dev/sdx3',
	'slxgrp' => '',
	'start_alsasound' => 'yes',
	'start_atd' => 'no',
	'start_cron' => 'no',
	'start_dreshal' => 'yes',
	'start_ntp' => 'initial',
	'start_nfsv4' => 'no',
	'start_printer' => 'no',
	'start_samba' => 'may',
	'start_snmp' => 'yes',
	'start_sshd' => 'yes',
	'start_syslog' => 'yes',
	'start_x' => 'no',
	'start_xdmcp' => '',
	'tex_enable' => 'no',
	'timezone' => 'America/New_York',
	'tvout' => 'no',
	'vmware' => 'yes',
};
foreach my $key (sort keys %$shouldBeAttrs11) {
	is(
		$fullMerge11->{attrs}->{$key} || '', $shouldBeAttrs11->{$key} || '', 
		"checking merged attribute $key for client 1 / system 1"
	);
}

my $fullMerge31 = { %$mergedClient3 };
ok(
	mergeAttributes($fullMerge31, $mergedSystem1),
	'merging system 1 into client 3'
);
my $shouldBeAttrs31 = {
	'ramfs_fsmods' => 'squashfs',
	'ramfs_miscmods' => '',
	'ramfs_nicmods' => 'forcedeth e1000 r8169',
	'ramfs_screen' => '',

	'automnt_dir' => '',
	'automnt_src' => '',
	'country' => 'de',
	'dm_allow_shutdown' => 'user',
	'hw_graphic' => '',
	'hw_monitor' => '',
	'hw_mouse' => '',
	'late_dm' => 'no',
	'netbios_workgroup' => 'slx-network',
	'nis_domain' => '',
	'nis_servers' => '',
	'sane_scanner' => '',
	'scratch' => '/dev/hdd1',
	'slxgrp' => '',
	'start_alsasound' => 'yes',
	'start_atd' => 'no',
	'start_cron' => 'no',
	'start_dreshal' => 'yes',
	'start_ntp' => 'initial',
	'start_nfsv4' => 'no',
	'start_printer' => 'no',
	'start_samba' => 'may',
	'start_snmp' => 'yes',
	'start_sshd' => 'yes',
	'start_syslog' => 'yes',
	'start_x' => 'no',
	'start_xdmcp' => '',
	'tex_enable' => 'no',
	'timezone' => 'Europe/London',
	'tvout' => 'no',
	'vmware' => 'yes',
};
foreach my $key (sort keys %$shouldBeAttrs31) {
	is(
		$fullMerge31->{attrs}->{$key} || '', $shouldBeAttrs31->{$key} || '', 
		"checking merged attribute $key for client 3 / system 1"
	);
}

my $fullMerge13 = { %$mergedClient1 };
ok(
	mergeAttributes($fullMerge13, $mergedSystem3),
	'merging system 3 into client 1'
);
my $shouldBeAttrs13 = {
	'ramfs_fsmods' => '-4',
	'ramfs_miscmods' => '-3',
	'ramfs_nicmods' => '-2',
	'ramfs_screen' => '-1',

	'automnt_dir' => '1',
	'automnt_src' => '2',
	'country' => '3',
	'dm_allow_shutdown' => '4',
	'hw_graphic' => '5',
	'hw_monitor' => '6',
	'hw_mouse' => '7',
	'late_dm' => '8',
	'netbios_workgroup' => '9',
	'nis_domain' => '10',
	'nis_servers' => '11',
	'sane_scanner' => '12',
	'scratch' => '/dev/sdx3',
	'slxgrp' => '14',
	'start_alsasound' => '15',
	'start_atd' => '16',
	'start_cron' => '17',
	'start_dreshal' => '18',
	'start_ntp' => '19',
	'start_nfsv4' => '20',
	'start_printer' => '21',
	'start_samba' => '22',
	'start_snmp' => 'yes',
	'start_sshd' => '24',
	'start_syslog' => '25',
	'start_x' => '26',
	'start_xdmcp' => '27',
	'tex_enable' => '28',
	'timezone' => 'America/New_York',
	'tvout' => '30',
	'vmware' => 'yes',
};
foreach my $key (sort keys %$shouldBeAttrs13) {
	is(
		$fullMerge13->{attrs}->{$key} || '', $shouldBeAttrs13->{$key} || '', 
		"checking merged attribute $key for client 1 / system 3"
	);
}

my $fullMerge33 = { %$mergedClient3 };
ok(
	mergeAttributes($fullMerge33, $mergedSystem3),
	'merging system 3 into client 3'
);
my $shouldBeAttrs33 = {
	'ramfs_fsmods' => '-4',
	'ramfs_miscmods' => '-3',
	'ramfs_nicmods' => '-2',
	'ramfs_screen' => '-1',

	'automnt_dir' => '1',
	'automnt_src' => '2',
	'country' => '3',
	'dm_allow_shutdown' => '4',
	'hw_graphic' => '5',
	'hw_monitor' => '6',
	'hw_mouse' => '7',
	'late_dm' => '8',
	'netbios_workgroup' => '9',
	'nis_domain' => '10',
	'nis_servers' => '11',
	'sane_scanner' => '12',
	'scratch' => '/dev/hdd1',
	'slxgrp' => '14',
	'start_alsasound' => '15',
	'start_atd' => '16',
	'start_cron' => '17',
	'start_dreshal' => '18',
	'start_ntp' => '19',
	'start_nfsv4' => '20',
	'start_printer' => '21',
	'start_samba' => '22',
	'start_snmp' => 'yes',
	'start_sshd' => '24',
	'start_syslog' => '25',
	'start_x' => '26',
	'start_xdmcp' => '27',
	'tex_enable' => '28',
	'timezone' => 'Europe/London',
	'tvout' => '30',
	'vmware' => 'yes',
};
foreach my $key (sort keys %$shouldBeAttrs33) {
	is(
		$fullMerge33->{attrs}->{$key} || '', $shouldBeAttrs33->{$key} || '', 
		"checking merged attribute $key for client 3 / system 3"
	);
}

$configDB->disconnect();
