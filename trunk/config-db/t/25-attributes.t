use Test::More qw(no_plan);

use lib '/opt/openslx/lib';

# basic init
use OpenSLX::ConfigDB qw(:support);

my $configDB = OpenSLX::ConfigDB->new;
$configDB->connect();

my $defaultAttrs = {	# mostly copied from DBSchema
	'attr_ramfs_fsmods' => '',
	'attr_ramfs_miscmods' => '',
	'attr_ramfs_nicmods' => 'forcedeth e1000 e100 tg3 via-rhine r8169 pcnet32',
	'attr_ramfs_screen' => '',

	'attr_automnt_dir' => '',
	'attr_automnt_src' => '',
	'attr_country' => 'de',
	'attr_dm_allow_shutdown' => 'user',
	'attr_hw_graphic' => '',
	'attr_hw_monitor' => '',
	'attr_hw_mouse' => '',
	'attr_late_dm' => 'no',
	'attr_netbios_workgroup' => 'slx-network',
	'attr_nis_domain' => '',
	'attr_nis_servers' => '',
	'attr_sane_scanner' => '',
	'attr_scratch' => '',
	'attr_slxgrp' => '',
	'attr_start_alsasound' => 'yes',
	'attr_start_atd' => 'no',
	'attr_start_cron' => 'no',
	'attr_start_dreshal' => 'yes',
	'attr_start_ntp' => 'initial',
	'attr_start_nfsv4' => 'no',
	'attr_start_printer' => 'no',
	'attr_start_samba' => 'may',
	'attr_start_snmp' => 'no',
	'attr_start_sshd' => 'yes',
	'attr_start_syslog' => 'yes',
	'attr_start_x' => 'yes',
	'attr_start_xdmcp' => 'kdm',
	'attr_tex_enable' => 'no',
	'attr_timezone' => 'Europe/Berlin',
	'attr_tvout' => 'no',
	'attr_vmware' => 'no',
};
ok(
	$configDB->changeSystem(0, $defaultAttrs),
	'attributes of default system have been set'
);
my $defaultSystem = $configDB->fetchSystemByID(0);

my $system1 = $configDB->fetchSystemByID(1);
my $sys1Attrs = {
	'attr_ramfs_fsmods' => 'squashfs',
	'attr_ramfs_nicmods' => 'forcedeth e1000 r8169',
	'attr_start_x' => 'no',
	'attr_start_xdmcp' => '',
};
ok(
	$configDB->changeSystem(1, $sys1Attrs),
	'attributes of system 1 have been set'
);

my $system3 = $configDB->fetchSystemByID(3);
my $sys3Attrs = {
	'attr_ramfs_fsmods' => '-4',
	'attr_ramfs_miscmods' => '-3',
	'attr_ramfs_nicmods' => '-2',
	'attr_ramfs_screen' => '-1',

	'attr_automnt_dir' => '1',
	'attr_automnt_src' => '2',
	'attr_country' => '3',
	'attr_dm_allow_shutdown' => '4',
	'attr_hw_graphic' => '5',
	'attr_hw_monitor' => '6',
	'attr_hw_mouse' => '7',
	'attr_late_dm' => '8',
	'attr_netbios_workgroup' => '9',
	'attr_nis_domain' => '10',
	'attr_nis_servers' => '11',
	'attr_sane_scanner' => '12',
	'attr_scratch' => '13',
	'attr_slxgrp' => '14',
	'attr_start_alsasound' => '15',
	'attr_start_atd' => '16',
	'attr_start_cron' => '17',
	'attr_start_dreshal' => '18',
	'attr_start_ntp' => '19',
	'attr_start_nfsv4' => '20',
	'attr_start_printer' => '21',
	'attr_start_samba' => '22',
	'attr_start_snmp' => '23',
	'attr_start_sshd' => '24',
	'attr_start_syslog' => '25',
	'attr_start_x' => '26',
	'attr_start_xdmcp' => '27',
	'attr_tex_enable' => '28',
	'attr_timezone' => '29',
	'attr_tvout' => '30',
	'attr_vmware' => '31',
};
ok(
	$configDB->changeSystem(3, $sys3Attrs),
	'attributes of system 3 have been set'
);

my $defaultClient = $configDB->fetchClientByID(0);
my $defaultClientAttrs = {
	# pretend the whole computer centre has been warped to London ;-)
	'attr_timezone' => 'Europe/London',
	# pretend we wanted to activate snmp globally (e.g. for testing)
	'attr_start_snmp' => 'yes',
};
ok(
	$configDB->changeClient(0, $defaultClientAttrs),
	'attributes of default client have been set'
);

# check merging of default attributes, the order should be:
# default system attributes overruled by system attributes overruled by
# default client attributes:
my $shouldBeAttrs1 = {
	'attr_ramfs_fsmods' => 'squashfs',
	'attr_ramfs_miscmods' => '',
	'attr_ramfs_nicmods' => 'forcedeth e1000 r8169',
	'attr_ramfs_screen' => '',

	'attr_automnt_dir' => '',
	'attr_automnt_src' => '',
	'attr_country' => 'de',
	'attr_dm_allow_shutdown' => 'user',
	'attr_hw_graphic' => '',
	'attr_hw_monitor' => '',
	'attr_hw_mouse' => '',
	'attr_late_dm' => 'no',
	'attr_netbios_workgroup' => 'slx-network',
	'attr_nis_domain' => '',
	'attr_nis_servers' => '',
	'attr_sane_scanner' => '',
	'attr_scratch' => '',
	'attr_slxgrp' => '',
	'attr_start_alsasound' => 'yes',
	'attr_start_atd' => 'no',
	'attr_start_cron' => 'no',
	'attr_start_dreshal' => 'yes',
	'attr_start_ntp' => 'initial',
	'attr_start_nfsv4' => 'no',
	'attr_start_printer' => 'no',
	'attr_start_samba' => 'may',
	'attr_start_snmp' => 'yes',
	'attr_start_sshd' => 'yes',
	'attr_start_syslog' => 'yes',
	'attr_start_x' => 'no',
	'attr_start_xdmcp' => '',
	'attr_tex_enable' => 'no',
	'attr_timezone' => 'Europe/London',
	'attr_tvout' => 'no',
	'attr_vmware' => 'no',
};
my $mergedSystem1 = $configDB->fetchSystemByID(1);
ok(
	$configDB->mergeDefaultAttributesIntoSystem($mergedSystem1),
	'merging default attributes into system 1'
);
foreach my $key (sort keys %$shouldBeAttrs1) {
	is(
		$mergedSystem1->{$key} || '', $shouldBeAttrs1->{$key} || '', 
		"checking merged attribute $key for system 1"
	);
}

# check merging code for completeness (using all attributes):
my $shouldBeAttrs3 = {
	'attr_ramfs_fsmods' => '-4',
	'attr_ramfs_miscmods' => '-3',
	'attr_ramfs_nicmods' => '-2',
	'attr_ramfs_screen' => '-1',

	'attr_automnt_dir' => '1',
	'attr_automnt_src' => '2',
	'attr_country' => '3',
	'attr_dm_allow_shutdown' => '4',
	'attr_hw_graphic' => '5',
	'attr_hw_monitor' => '6',
	'attr_hw_mouse' => '7',
	'attr_late_dm' => '8',
	'attr_netbios_workgroup' => '9',
	'attr_nis_domain' => '10',
	'attr_nis_servers' => '11',
	'attr_sane_scanner' => '12',
	'attr_scratch' => '13',
	'attr_slxgrp' => '14',
	'attr_start_alsasound' => '15',
	'attr_start_atd' => '16',
	'attr_start_cron' => '17',
	'attr_start_dreshal' => '18',
	'attr_start_ntp' => '19',
	'attr_start_nfsv4' => '20',
	'attr_start_printer' => '21',
	'attr_start_samba' => '22',
	'attr_start_snmp' => 'yes',
	'attr_start_sshd' => '24',
	'attr_start_syslog' => '25',
	'attr_start_x' => '26',
	'attr_start_xdmcp' => '27',
	'attr_tex_enable' => '28',
	'attr_timezone' => 'Europe/London',
	'attr_tvout' => '30',
	'attr_vmware' => '31',
};
my $mergedSystem3 = $configDB->fetchSystemByID(3);
ok(
	$configDB->mergeDefaultAttributesIntoSystem($mergedSystem3),
	'merging default attributes into system 3'
);
foreach my $key (sort keys %$shouldBeAttrs3) {
	is(
		$mergedSystem3->{$key}, $shouldBeAttrs3->{$key}, 
		"checking merged attribute $key for system 3"
	);
}

# setup client / group relations
my $group1 = $configDB->fetchGroupByID(1);
my $group1Attrs = {
	'priority' => '50',
	# this group of clients is connected via underwater cable ...
	'attr_timezone' => 'America/New_York',
	# ... and use a local scratch partition
	'attr_scratch' => '/dev/sdd1',
	# the following should be a noop (as that attribute is system-specific)
#	'attr_ramfs_nicmods' => 'e1000',
};
ok(
	$configDB->changeGroup(1, $group1Attrs),
	'attributes of group 1 have been set'
);
my $group3 = $configDB->fetchGroupByID(3);
my $group3Attrs = {
	'priority' => '30',
	# this specific client group is older and thus has a different scratch
	'attr_scratch' => '/dev/hdd1',
	'attr_vmware' => 'yes',
};
ok(
	$configDB->changeGroup(3, $group3Attrs),
	'attributes of group 3 have been set'
);
my $client1 = $configDB->fetchClientByID(1);
my $client1Attrs = {
	# this specific client uses yet another local scratch partition
	'attr_scratch' => '/dev/sdx3',
};
ok(
	$configDB->changeClient(1, $client1Attrs),
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
	'attr_ramfs_fsmods' => '',
	'attr_ramfs_miscmods' => '',
	'attr_ramfs_nicmods' => '',
	'attr_ramfs_screen' => '',

	'attr_automnt_dir' => '',
	'attr_automnt_src' => '',
	'attr_country' => '',
	'attr_dm_allow_shutdown' => '',
	'attr_hw_graphic' => '',
	'attr_hw_monitor' => '',
	'attr_hw_mouse' => '',
	'attr_late_dm' => '',
	'attr_netbios_workgroup' => '',
	'attr_nis_domain' => '',
	'attr_nis_servers' => '',
	'attr_sane_scanner' => '',
	'attr_scratch' => '/dev/sdx3',
	'attr_slxgrp' => '',
	'attr_start_alsasound' => '',
	'attr_start_atd' => '',
	'attr_start_cron' => '',
	'attr_start_dreshal' => '',
	'attr_start_ntp' => '',
	'attr_start_nfsv4' => '',
	'attr_start_printer' => '',
	'attr_start_samba' => '',
	'attr_start_snmp' => 'yes',
	'attr_start_sshd' => '',
	'attr_start_syslog' => '',
	'attr_start_x' => '',
	'attr_start_xdmcp' => '',
	'attr_tex_enable' => '',
	'attr_timezone' => 'America/New_York',
	'attr_tvout' => '',
	'attr_vmware' => '',
};
my $mergedClient1 = $configDB->fetchClientByID(1);
ok(
	$configDB->mergeDefaultAndGroupAttributesIntoClient($mergedClient1),
	'merging default and group attributes into client 1'
);
foreach my $key (sort keys %$shouldBeAttrs1) {
	is(
		$mergedClient1->{$key} || '', $shouldBeAttrs1->{$key} || '', 
		"checking merged attribute $key for client 1"
	);
}

$shouldBeAttrs3 = {
	'attr_ramfs_fsmods' => '',
	'attr_ramfs_miscmods' => '',
	'attr_ramfs_nicmods' => '',
	'attr_ramfs_screen' => '',

	'attr_automnt_dir' => '',
	'attr_automnt_src' => '',
	'attr_country' => '',
	'attr_dm_allow_shutdown' => '',
	'attr_hw_graphic' => '',
	'attr_hw_monitor' => '',
	'attr_hw_mouse' => '',
	'attr_late_dm' => '',
	'attr_netbios_workgroup' => '',
	'attr_nis_domain' => '',
	'attr_nis_servers' => '',
	'attr_sane_scanner' => '',
	'attr_scratch' => '',
	'attr_slxgrp' => '',
	'attr_start_alsasound' => '',
	'attr_start_atd' => '',
	'attr_start_cron' => '',
	'attr_start_dreshal' => '',
	'attr_start_ntp' => '',
	'attr_start_nfsv4' => '',
	'attr_start_printer' => '',
	'attr_start_samba' => '',
	'attr_start_snmp' => 'yes',
	'attr_start_sshd' => '',
	'attr_start_syslog' => '',
	'attr_start_x' => '',
	'attr_start_xdmcp' => '',
	'attr_tex_enable' => '',
	'attr_timezone' => 'Europe/London',
	'attr_tvout' => '',
	'attr_vmware' => '',
};
my $mergedClient3 = $configDB->fetchClientByID(3);
ok(
	$configDB->mergeDefaultAndGroupAttributesIntoClient($mergedClient3),
	'merging default and group attributes into client 3'
);
foreach my $key (sort keys %$shouldBeAttrs1) {
	is(
		$mergedClient3->{$key} || '', $shouldBeAttrs3->{$key} || '', 
		"checking merged attribute $key for client 3"
	);
}

# now associate default client with group 3 and try again
ok(
	$configDB->setGroupIDsOfClient(0, [3]),
	'group-IDs of default client have been set'
);
$shouldBeAttrs1 = {
	'attr_ramfs_fsmods' => '',
	'attr_ramfs_miscmods' => '',
	'attr_ramfs_nicmods' => '',
	'attr_ramfs_screen' => '',

	'attr_automnt_dir' => '',
	'attr_automnt_src' => '',
	'attr_country' => '',
	'attr_dm_allow_shutdown' => '',
	'attr_hw_graphic' => '',
	'attr_hw_monitor' => '',
	'attr_hw_mouse' => '',
	'attr_late_dm' => '',
	'attr_netbios_workgroup' => '',
	'attr_nis_domain' => '',
	'attr_nis_servers' => '',
	'attr_sane_scanner' => '',
	'attr_scratch' => '/dev/sdx3',
	'attr_slxgrp' => '',
	'attr_start_alsasound' => '',
	'attr_start_atd' => '',
	'attr_start_cron' => '',
	'attr_start_dreshal' => '',
	'attr_start_ntp' => '',
	'attr_start_nfsv4' => '',
	'attr_start_printer' => '',
	'attr_start_samba' => '',
	'attr_start_snmp' => 'yes',
	'attr_start_sshd' => '',
	'attr_start_syslog' => '',
	'attr_start_x' => '',
	'attr_start_xdmcp' => '',
	'attr_tex_enable' => '',
	'attr_timezone' => 'America/New_York',
	'attr_tvout' => '',
	'attr_vmware' => 'yes',
};
$mergedClient1 = $configDB->fetchClientByID(1);
ok(
	$configDB->mergeDefaultAndGroupAttributesIntoClient($mergedClient1),
	'merging default and group attributes into client 1'
);
foreach my $key (sort keys %$shouldBeAttrs1) {
	is(
		$mergedClient1->{$key} || '', $shouldBeAttrs1->{$key} || '', 
		"checking merged attribute $key for client 1"
	);
}

$shouldBeAttrs3 = {
	'attr_ramfs_fsmods' => '',
	'attr_ramfs_miscmods' => '',
	'attr_ramfs_nicmods' => '',
	'attr_ramfs_screen' => '',

	'attr_automnt_dir' => '',
	'attr_automnt_src' => '',
	'attr_country' => '',
	'attr_dm_allow_shutdown' => '',
	'attr_hw_graphic' => '',
	'attr_hw_monitor' => '',
	'attr_hw_mouse' => '',
	'attr_late_dm' => '',
	'attr_netbios_workgroup' => '',
	'attr_nis_domain' => '',
	'attr_nis_servers' => '',
	'attr_sane_scanner' => '',
	'attr_scratch' => '/dev/hdd1',
	'attr_slxgrp' => '',
	'attr_start_alsasound' => '',
	'attr_start_atd' => '',
	'attr_start_cron' => '',
	'attr_start_dreshal' => '',
	'attr_start_ntp' => '',
	'attr_start_nfsv4' => '',
	'attr_start_printer' => '',
	'attr_start_samba' => '',
	'attr_start_snmp' => 'yes',
	'attr_start_sshd' => '',
	'attr_start_syslog' => '',
	'attr_start_x' => '',
	'attr_start_xdmcp' => '',
	'attr_tex_enable' => '',
	'attr_timezone' => 'Europe/London',
	'attr_tvout' => '',
	'attr_vmware' => 'yes',
};
$mergedClient3 = $configDB->fetchClientByID(3);
ok(
	$configDB->mergeDefaultAndGroupAttributesIntoClient($mergedClient3),
	'merging default and group attributes into client 3'
);
foreach my $key (sort keys %$shouldBeAttrs1) {
	is(
		$mergedClient3->{$key} || '', $shouldBeAttrs3->{$key} || '', 
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
	'attr_ramfs_fsmods' => 'squashfs',
	'attr_ramfs_miscmods' => '',
	'attr_ramfs_nicmods' => 'forcedeth e1000 r8169',
	'attr_ramfs_screen' => '',

	'attr_automnt_dir' => '',
	'attr_automnt_src' => '',
	'attr_country' => 'de',
	'attr_dm_allow_shutdown' => 'user',
	'attr_hw_graphic' => '',
	'attr_hw_monitor' => '',
	'attr_hw_mouse' => '',
	'attr_late_dm' => 'no',
	'attr_netbios_workgroup' => 'slx-network',
	'attr_nis_domain' => '',
	'attr_nis_servers' => '',
	'attr_sane_scanner' => '',
	'attr_scratch' => '/dev/sdx3',
	'attr_slxgrp' => '',
	'attr_start_alsasound' => 'yes',
	'attr_start_atd' => 'no',
	'attr_start_cron' => 'no',
	'attr_start_dreshal' => 'yes',
	'attr_start_ntp' => 'initial',
	'attr_start_nfsv4' => 'no',
	'attr_start_printer' => 'no',
	'attr_start_samba' => 'may',
	'attr_start_snmp' => 'yes',
	'attr_start_sshd' => 'yes',
	'attr_start_syslog' => 'yes',
	'attr_start_x' => 'no',
	'attr_start_xdmcp' => '',
	'attr_tex_enable' => 'no',
	'attr_timezone' => 'America/New_York',
	'attr_tvout' => 'no',
	'attr_vmware' => 'yes',
};
foreach my $key (sort keys %$shouldBeAttrs11) {
	is(
		$fullMerge11->{$key} || '', $shouldBeAttrs11->{$key} || '', 
		"checking merged attribute $key for client 1 / system 1"
	);
}

my $fullMerge31 = { %$mergedClient3 };
ok(
	mergeAttributes($fullMerge31, $mergedSystem1),
	'merging system 1 into client 3'
);
my $shouldBeAttrs31 = {
	'attr_ramfs_fsmods' => 'squashfs',
	'attr_ramfs_miscmods' => '',
	'attr_ramfs_nicmods' => 'forcedeth e1000 r8169',
	'attr_ramfs_screen' => '',

	'attr_automnt_dir' => '',
	'attr_automnt_src' => '',
	'attr_country' => 'de',
	'attr_dm_allow_shutdown' => 'user',
	'attr_hw_graphic' => '',
	'attr_hw_monitor' => '',
	'attr_hw_mouse' => '',
	'attr_late_dm' => 'no',
	'attr_netbios_workgroup' => 'slx-network',
	'attr_nis_domain' => '',
	'attr_nis_servers' => '',
	'attr_sane_scanner' => '',
	'attr_scratch' => '/dev/hdd1',
	'attr_slxgrp' => '',
	'attr_start_alsasound' => 'yes',
	'attr_start_atd' => 'no',
	'attr_start_cron' => 'no',
	'attr_start_dreshal' => 'yes',
	'attr_start_ntp' => 'initial',
	'attr_start_nfsv4' => 'no',
	'attr_start_printer' => 'no',
	'attr_start_samba' => 'may',
	'attr_start_snmp' => 'yes',
	'attr_start_sshd' => 'yes',
	'attr_start_syslog' => 'yes',
	'attr_start_x' => 'no',
	'attr_start_xdmcp' => '',
	'attr_tex_enable' => 'no',
	'attr_timezone' => 'Europe/London',
	'attr_tvout' => 'no',
	'attr_vmware' => 'yes',
};
foreach my $key (sort keys %$shouldBeAttrs31) {
	is(
		$fullMerge31->{$key} || '', $shouldBeAttrs31->{$key} || '', 
		"checking merged attribute $key for client 3 / system 1"
	);
}

my $fullMerge13 = { %$mergedClient1 };
ok(
	mergeAttributes($fullMerge13, $mergedSystem3),
	'merging system 3 into client 1'
);
my $shouldBeAttrs13 = {
	'attr_ramfs_fsmods' => '-4',
	'attr_ramfs_miscmods' => '-3',
	'attr_ramfs_nicmods' => '-2',
	'attr_ramfs_screen' => '-1',

	'attr_automnt_dir' => '1',
	'attr_automnt_src' => '2',
	'attr_country' => '3',
	'attr_dm_allow_shutdown' => '4',
	'attr_hw_graphic' => '5',
	'attr_hw_monitor' => '6',
	'attr_hw_mouse' => '7',
	'attr_late_dm' => '8',
	'attr_netbios_workgroup' => '9',
	'attr_nis_domain' => '10',
	'attr_nis_servers' => '11',
	'attr_sane_scanner' => '12',
	'attr_scratch' => '/dev/sdx3',
	'attr_slxgrp' => '14',
	'attr_start_alsasound' => '15',
	'attr_start_atd' => '16',
	'attr_start_cron' => '17',
	'attr_start_dreshal' => '18',
	'attr_start_ntp' => '19',
	'attr_start_nfsv4' => '20',
	'attr_start_printer' => '21',
	'attr_start_samba' => '22',
	'attr_start_snmp' => 'yes',
	'attr_start_sshd' => '24',
	'attr_start_syslog' => '25',
	'attr_start_x' => '26',
	'attr_start_xdmcp' => '27',
	'attr_tex_enable' => '28',
	'attr_timezone' => 'America/New_York',
	'attr_tvout' => '30',
	'attr_vmware' => 'yes',
};
foreach my $key (sort keys %$shouldBeAttrs13) {
	is(
		$fullMerge13->{$key} || '', $shouldBeAttrs13->{$key} || '', 
		"checking merged attribute $key for client 1 / system 3"
	);
}

my $fullMerge33 = { %$mergedClient3 };
ok(
	mergeAttributes($fullMerge33, $mergedSystem3),
	'merging system 3 into client 3'
);
my $shouldBeAttrs33 = {
	'attr_ramfs_fsmods' => '-4',
	'attr_ramfs_miscmods' => '-3',
	'attr_ramfs_nicmods' => '-2',
	'attr_ramfs_screen' => '-1',

	'attr_automnt_dir' => '1',
	'attr_automnt_src' => '2',
	'attr_country' => '3',
	'attr_dm_allow_shutdown' => '4',
	'attr_hw_graphic' => '5',
	'attr_hw_monitor' => '6',
	'attr_hw_mouse' => '7',
	'attr_late_dm' => '8',
	'attr_netbios_workgroup' => '9',
	'attr_nis_domain' => '10',
	'attr_nis_servers' => '11',
	'attr_sane_scanner' => '12',
	'attr_scratch' => '/dev/hdd1',
	'attr_slxgrp' => '14',
	'attr_start_alsasound' => '15',
	'attr_start_atd' => '16',
	'attr_start_cron' => '17',
	'attr_start_dreshal' => '18',
	'attr_start_ntp' => '19',
	'attr_start_nfsv4' => '20',
	'attr_start_printer' => '21',
	'attr_start_samba' => '22',
	'attr_start_snmp' => 'yes',
	'attr_start_sshd' => '24',
	'attr_start_syslog' => '25',
	'attr_start_x' => '26',
	'attr_start_xdmcp' => '27',
	'attr_tex_enable' => '28',
	'attr_timezone' => 'Europe/London',
	'attr_tvout' => '30',
	'attr_vmware' => 'yes',
};
foreach my $key (sort keys %$shouldBeAttrs33) {
	is(
		$fullMerge33->{$key} || '', $shouldBeAttrs33->{$key} || '', 
		"checking merged attribute $key for client 3 / system 3"
	);
}

$configDB->disconnect();
