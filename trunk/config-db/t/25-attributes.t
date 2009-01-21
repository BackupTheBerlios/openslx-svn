use Test::More qw(no_plan);

use lib '/opt/openslx/lib';

# basic init
use OpenSLX::ConfigDB;

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
my $changedSystem1 = $configDB->fetchSystemByID(1);
foreach my $key (keys %$changedSystem1) {
	is(
		$changedSystem1->{$key},
		exists $sys1Attrs->{$key} ? $sys1Attrs->{$key} : $system1->{$key},
		"checking value for $key of system 1"
	);
}

my $system3 = $configDB->fetchSystemByID(3);
my $sys3Attrs = {
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
my $changedSystem3 = $configDB->fetchSystemByID(3);
foreach my $key (keys %$changedSystem3) {
	is(
		$changedSystem3->{$key},
		exists $sys3Attrs->{$key} ? $sys3Attrs->{$key} : $system3->{$key},
		"checking value for $key of system 3"
	);
}

my $defaultClient = $configDB->fetchClientByID(0);
my $defaultClientAttrs = {
	# pretend the whole computer centre has been warped to London ;-)
	'attr_timezone' => 'Europe/London',
};
ok(
	$configDB->changeClient(0, $defaultClientAttrs),
	'attributes of default client have been set'
);
my $changedDefaultClient = $configDB->fetchClientByID(0);
foreach my $key (keys %$changedDefaultClient) {
	is(
		$changedDefaultClient->{$key},
		exists $defaultClientAttrs->{$key} 
			? $defaultClientAttrs->{$key} 
			: $defaultClient->{$key},
		"checking value for $key of default client"
	);
}

# check merging of default attributes, the order should be:
# default system attributes overruled by system attributes overruled by
# default client attributes
$system1 = $changedSystem1;
$system3 = $changedSystem3;
$defaultClient = $changedDefaultClient;
my $shouldBeAttrs1 = { %$defaultSystem };
foreach my $key (keys %$system1) {
	next if !$configDB->isAttribute($key);
	if (defined $system1->{$key} && length($system1->{$key})) {
		$shouldBeAttrs1->{$key} = $system1->{$key};
	}
}
foreach my $key (keys %$defaultClient) {
	next if !$configDB->isAttribute($key);
	if (defined $defaultClient->{$key} && length($defaultClient->{$key})) {
		$shouldBeAttrs1->{$key} = $defaultClient->{$key};
	}
}

my $mergedSystem1 =  $configDB->fetchSystemByID(1);
ok(
	$configDB->mergeAttributes($mergedSystem1), 
	'merging default attributes for system 1'
);
is_deeply(
	$mergedSystem1, $shouldBeAttrs1, 
	'checking merged attributes for system 1'
);

$configDB->disconnect();
