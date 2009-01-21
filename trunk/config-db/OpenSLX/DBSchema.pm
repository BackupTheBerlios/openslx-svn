# Copyright (c) 2006, 2007 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your suggestions, praise, or complaints to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org/
# -----------------------------------------------------------------------------
# DBSchema.pm
#	- provides database schema of the OpenSLX config-db.
# -----------------------------------------------------------------------------
package OpenSLX::DBSchema;

use strict;
use warnings;

use OpenSLX::Basics;

################################################################################
### DB-schema definition
### 	This hash-ref describes the current OpenSLX configuration database 
###		schema.
###		Each table is defined by a list of column descriptions (and optionally
###		a list of default values).
### 	A column description is simply the name of the column followed by ':'
### 	followed by the data type description. The following data types are
### 	currently supported:
### 		b		=> boolean (providing the values 1 and 0 only)
### 		i		=> integer (32-bit, signed)
### 		s.20	=> string, followed by length argument (in this case: 20)
### 		pk		=> primary key (integer)
### 		fk		=> foreign key (integer)
################################################################################

use POSIX qw(locale_h);
my $lang = setlocale(LC_MESSAGES);
my $country = $lang =~ m[^\w\w_(\w\w)] ? lc($1) : 'us';

my $VERSION = 0.2;

my $DbSchema = {
	'version' => $VERSION,
	'tables' => {
		'client' => {
			# a client is a PC booting via network
			'cols' => [
				'id:pk',			# primary key
				'name:s.128',		# official name of PC (e.g. as given by sticker
									# on case)
				'mac:s.20',			# MAC of NIC used for booting
				'boot_type:s.20',	# type of remote boot procedure (PXE, ...)
				'unbootable:b',		# unbootable clients simply won't boot
				'kernel_params:s.128',	# client-specific kernel-args (e.g. console)
				'comment:s.1024',	# internal comment (optional, for admins)
			],
			'vals' => [
				{	# add default client
					'id'         => 0,
					'name'       => '<<<default>>>',
					'comment'    => 'internal client that holds default values',
					'unbootable' => 0,
				},
			],
		},
		'client_attr' => {
			# attributes of clients
			'cols' => [
				'id:pk',			# primary key
				'client_id:fk',		# foreign key to client
				'name:s.128',		# attribute name
				'value:s.255',		# attribute value
			],
		},
		'client_system_ref' => {
			# clients referring to the systems they should offer for booting
			'cols' => [
				'client_id:fk',		# foreign key
				'system_id:fk',		# foreign key
			],
		},
		'export' => {
			# an export describes a vendor-OS "wrapped" in some kind of exporting
			# format (NFS or NBD-squash). This represents the rootfs that the
			# clients will see.
			'cols' => [
				'id:pk',			# primary key
				'name:s.64',		# unique name of export, is automatically
									# constructed like this:
									#   <vendor-os-name>-<export-type>
				'vendor_os_id:fk',	# foreign key
				'comment:s.1024',	# internal comment (optional, for admins)
				'type:s.10',		# 'nbd', 'nfs', ...
				'server_ip:s.16',	# IP of exporting server, if empty the
									# boot server will be used
				'port:i',			# some export types need to use a specific
									# port for each incarnation, if that's the
									# case you can specify it here
				'uri:s.255',		# path to export (squashfs or NFS-path), if
									# empty it will be auto-generated by
									# config-demuxer
			],
		},
		'global_info' => {
			# a home for global counters and other info
			'cols' => [
				'id:s.32',			# key
				'value:s.128',		# value
			],
			'vals' => [
				{	# add nbd-server-port
					'id' => 'next-nbd-server-port',
					'value' => '5000',
				},
			],
		},
		'groups' => {
			# a group encapsulates a set of clients as one entity, managing
			# a group-specific attribute set. All the different attribute
			# sets a client inherits via group membership are folded into
			# one resulting attribute set with respect to each group's priority.
			'cols' => [
				'id:pk',			# primary key
				'name:s.128',		# name of group
				'priority:i',		# priority, used for order in group-list
									# (from 0-highest to 99-lowest)
				'comment:s.1024',	# internal comment (optional, for admins)
			],
		},
		'group_attr' => {
			# attributes of groups
			'cols' => [
				'id:pk',			# primary key
				'group_id:fk',		# foreign key to group
				'name:s.128',		# attribute name
				'value:s.255',		# attribute value
			],
		},
		'group_client_ref' => {
			# groups referring to their clients
			'cols' => [
				'group_id:fk',		# foreign key
				'client_id:fk',		# foreign key
			],
		},
		'group_system_ref' => {
			# groups referring to the systems each of their clients should
			# offer for booting
			'cols' => [
				'group_id:fk',		# foreign key
				'system_id:fk',		# foreign key
			],
		},
		'meta' => {
			# information about the database as such
			'cols' => [
				'schema_version:s.5',	# schema-version currently implemented by DB
			],
			'vals' => [
				{
					'schema_version' => $VERSION,
				},
			],
		},
		'system' => {
			# a system describes one bootable instance of an export, it
			# represents a selectable line in the PXE boot menu of all the
			# clients associated with this system
			'cols' => [
				'id:pk',			# primary key
				'export_id:fk',		# foreign key
				'name:s.64',		# unique name of system, is automatically
									# constructed like this:
									#   <vendor-os-name>-<export-type>-<kernel>
				'label:s.64',		# name visible to user (pxe-label)
									# if empty, this will be autocreated from
									# the name
				'kernel:s.128',		# path to kernel file, relative to /boot
				'kernel_params:s.512',	# kernel-param string for pxe
				'hidden:b',				# hidden systems won't be offered for booting
				'comment:s.1024',	# internal comment (optional, for admins)
			],
			'vals' => [
				{	# add default system
					'id' => 0,
					'name' => '<<<default>>>',
					'hidden' => 1,
					'comment' => 'internal system that holds default values',
				},
			],
		},
		'system_attr' => {
			# attributes of systems
			'cols' => [
				'id:pk',			# primary key
				'system_id:fk',		# foreign key to system
				'name:s.128',		# attribute name
				'value:s.255',		# attribute value
			],
			'vals' => [
				# attributes of default system
				{
					'system_id' => 0,
					'name' => 'country',
					'value' => "$country",
				},
				{
					'system_id' => 0,
					'name' => 'dm_allow_shutdown',
					'value' => 'user',
				},
				{
					'system_id' => 0,
					'name' => 'late_dm',
					'value' => 'no',
				},
				{
					'system_id' => 0,
					'name' => 'netbios_workgroup',
					'value' => 'slx-network',
				},
				{
					'system_id' => 0,
					'name' => 'ramfs_nicmods',
					'value' 
						=> 'forcedeth e1000 e100 tg3 via-rhine r8169 pcnet32',
				},
				{
					'system_id' => 0,
					'name' => 'start_alsasound',
					'value' => 'yes',
				},
				{
					'system_id' => 0,
					'name' => 'start_atd',
					'value' => 'no',
				},
				{
					'system_id' => 0,
					'name' => 'start_cron',
					'value' => 'no',
				},
				{
					'system_id' => 0,
					'name' => 'start_dreshal',
					'value' => 'yes',
				},
				{
					'system_id' => 0,
					'name' => 'start_ntp',
					'value' => 'initial',
				},
				{
					'system_id' => 0,
					'name' => 'start_nfsv4',
					'value' => 'no',
				},
				{
					'system_id' => 0,
					'name' => 'start_printer',
					'value' => 'no',
				},
				{
					'system_id' => 0,
					'name' => 'start_samba',
					'value' => 'may',
				},
				{
					'system_id' => 0,
					'name' => 'start_snmp',
					'value' => 'no',
				},
				{
					'system_id' => 0,
					'name' => 'start_sshd',
					'value' => 'yes',
				},
				{
					'system_id' => 0,
					'name' => 'start_syslog',
					'value' => 'yes',
				},
				{
					'system_id' => 0,
					'name' => 'start_x',
					'value' => 'yes',
				},
				{
					'system_id' => 0,
					'name' => 'start_xdmcp',
					'value' => 'kdm',
				},
				{
					'system_id' => 0,
					'name' => 'tex_enable',
					'value' => 'no',
				},
				{
					'system_id' => 0,
					'name' => 'timezone',
					'value' => 'Europe/Berlin',
				},
				{
					'system_id' => 0,
					'name' => 'tvout',
					'value' => 'no',
				},
				{
					'system_id' => 0,
					'name' => 'vmware',
					'value' => 'no',
				},
			],
		},
		'vendor_os' => {
			# a vendor-OS describes a folder containing an operating system as
			# provided by the vendor (a.k.a. unchanged and thus updatable)
			'cols' => [
				'id:pk',			# primary key
				'name:s.48',		# structured name of OS installation
									# (e.g. suse-9.3-kde, debian-3.1-ppc,
									# suse-10.2-cloned-from-kiwi).
									# This is used as the folder name for the
									# corresponding stage1, too.
				'comment:s.1024',	# internal comment (optional, for admins)
				'clone_source:s.255',	# if vendor-OS was cloned, this contains
										# the rsync-URI pointing to the original
			],
		},
	},
};

################################################################################
###
### standard methods
###
################################################################################
sub new
{
	my $class = shift;

	my $self = {
	};

	return bless $self, $class;
}

sub checkAndUpgradeDBSchemaIfNecessary
{
	my $self   = shift;
	my $metaDB = shift;

	vlog(2, "trying to determine schema version...");
	my $currVersion = $metaDB->schemaFetchDBVersion();
	if (!defined $currVersion) {
		# that's bad, someone has messed with our DB: there is a
		# database, but the 'meta'-table is empty. 
		# There might still be data in the other tables, but we have no way to 
		# find out which schema version they're in. So it's safer to give up.
		croak _tr('Could not determine schema version of database');
	}

	if ($currVersion == 0) {
		vlog(1, _tr('Creating DB (schema version: %s)', $DbSchema->{version}));
		foreach my $tableName (keys %{$DbSchema->{tables}}) {
			# create table (optionally inserting default values, too)
			$metaDB->schemaAddTable(
				$tableName,
				$DbSchema->{tables}->{$tableName}->{cols},
				$DbSchema->{tables}->{$tableName}->{vals}
			);
		}
		$metaDB->schemaSetDBVersion($DbSchema->{version});
		vlog(1, _tr('DB has been created successfully'));
	} elsif ($currVersion < $DbSchema->{version}) {
		vlog(
			1,
			_tr(
				'Our schema-version is %s, DB is %s, upgrading DB...',
				$DbSchema->{version}, $currVersion
			)
		);
		$self->_schemaUpgradeDBFrom($metaDB, $currVersion);
		$metaDB->schemaSetDBVersion($DbSchema->{version});
		vlog(1, _tr('upgrade done'));
	} else {
		vlog(1, _tr('DB matches current schema version (%s)', $currVersion));
	}

	return 1;
}

sub getColumnsOfTable
{
	my $self      = shift;
	my $tableName = shift;

	return	
		map { (/^(\w+)\W/) ? $1 : $_; } 
		@{$DbSchema->{tables}->{$tableName}->{cols}};
}

################################################################################
###
### methods for upgrading the DB schema
###
################################################################################
sub _schemaUpgradeDBFrom
{
	my $self        = shift;
	my $metaDB      = shift;
	my $currVersion = shift;

	$self->_upgradeDBTo0_2($metaDB) if $currVersion < 0.2;

	return 1;
}

sub _upgradeDBTo0_2
{
	my $self   = shift;
	my $metaDB = shift;

	# move attributes into separate tables ...
	#
	# ... system attributes ...
	$metaDB->schemaAddTable(
		'system_attr', 
		[
			'id:pk',
			'system_id:fk',
			'name:s.128',
			'value:s.255',
		]
	);
	foreach my $system ($metaDB->fetchSystemByFilter()) {
		my %attrs;
		foreach my $key (keys %$system) {
			next if substr($key, 0, 5) ne 'attr_';
			my $attrValue = $system->{$key} || '';
			next if $system->{id} > 0 && !length($attrValue);
			my $newAttrName = substr($key, 5);
			$attrs{$newAttrName} = $attrValue;
		}
		$metaDB->setSystemAttrs($system->{id}, \%attrs);
	}
	$metaDB->schemaDropColumns(
		'system',
		[
			'attr_automnt_dir',
			'attr_automnt_src',
			'attr_country',
			'attr_dm_allow_shutdown',
			'attr_hw_graphic',
			'attr_hw_monitor',
			'attr_hw_mouse',
			'attr_late_dm',
			'attr_netbios_workgroup',
			'attr_nis_domain',
			'attr_nis_servers',
			'attr_ramfs_fsmods',
			'attr_ramfs_miscmods',
			'attr_ramfs_nicmods',
			'attr_ramfs_screen',
			'attr_sane_scanner',
			'attr_scratch',
			'attr_slxgrp',
			'attr_start_alsasound',
			'attr_start_atd',
			'attr_start_cron',
			'attr_start_dreshal',
			'attr_start_ntp',
			'attr_start_nfsv4',
			'attr_start_printer',
			'attr_start_samba',
			'attr_start_snmp',
			'attr_start_sshd',
			'attr_start_syslog',
			'attr_start_x',
			'attr_start_xdmcp',
			'attr_tex_enable',
			'attr_timezone',
			'attr_tvout',
			'attr_vmware',
		],
		[
			'id:pk',
			'export_id:fk',
			'name:s.64',
			'label:s.64',
			'kernel:s.128',
			'kernel_params:s.512',
			'hidden:b',
			'comment:s.1024',
		]
	);
	#
	# ... client attributes ...
	$metaDB->schemaAddTable(
		'client_attr',
		[
			'id:pk',
			'client_id:fk',
			'name:s.128',
			'value:s.255',
		]
	);
	foreach my $client ($metaDB->fetchClientByFilter()) {
		my %attrs;
		foreach my $key (keys %$client) {
			next if substr($key, 0, 5) ne 'attr_';
			my $attrValue = $client->{$key} || '';
			next if !length($attrValue);
			my $newAttrName = substr($key, 5);
			$attrs{$newAttrName} = $attrValue;
		}
		$metaDB->setClientAttrs($client->{id}, \%attrs);
	}
	$metaDB->schemaDropColumns(
		'client',
		[
			'attr_automnt_dir',
			'attr_automnt_src',
			'attr_country',
			'attr_dm_allow_shutdown',
			'attr_hw_graphic',
			'attr_hw_monitor',
			'attr_hw_mouse',
			'attr_late_dm',
			'attr_netbios_workgroup',
			'attr_nis_domain',
			'attr_nis_servers',
			'attr_sane_scanner',
			'attr_scratch',
			'attr_slxgrp',
			'attr_start_alsasound',
			'attr_start_atd',
			'attr_start_cron',
			'attr_start_dreshal',
			'attr_start_ntp',
			'attr_start_nfsv4',
			'attr_start_printer',
			'attr_start_samba',
			'attr_start_snmp',
			'attr_start_sshd',
			'attr_start_syslog',
			'attr_start_x',
			'attr_start_xdmcp',
			'attr_tex_enable',
			'attr_timezone',
			'attr_tvout',
			'attr_vmware',
		],
		[
			'id:pk',
			'name:s.128',
			'mac:s.20',
			'boot_type:s.20',
			'unbootable:b',
			'kernel_params:s.128',
			'comment:s.1024',
		]
	);
	#
	# ... group attributes ...
	$metaDB->schemaAddTable(
		'group_attr',
		[
			'id:pk',
			'group_id:fk',
			'name:s.128',
			'value:s.255',
		]
	);
	foreach my $group ($metaDB->fetchGroupByFilter()) {
		my %attrs;
		foreach my $key (keys %$group) {
			next if substr($key, 0, 5) ne 'attr_';
			my $attrValue = $group->{$key} || '';
			next if !length($attrValue);
			my $newAttrName = substr($key, 5);
			$attrs{$newAttrName} = $attrValue;
		}
		$metaDB->setGroupAttrs($group->{id}, \%attrs);
	}
	$metaDB->schemaDropColumns(
		'groups',
		[
			'attr_automnt_dir',
			'attr_automnt_src',
			'attr_country',
			'attr_dm_allow_shutdown',
			'attr_hw_graphic',
			'attr_hw_monitor',
			'attr_hw_mouse',
			'attr_late_dm',
			'attr_netbios_workgroup',
			'attr_nis_domain',
			'attr_nis_servers',
			'attr_sane_scanner',
			'attr_scratch',
			'attr_slxgrp',
			'attr_start_alsasound',
			'attr_start_atd',
			'attr_start_cron',
			'attr_start_dreshal',
			'attr_start_ntp',
			'attr_start_nfsv4',
			'attr_start_printer',
			'attr_start_samba',
			'attr_start_snmp',
			'attr_start_sshd',
			'attr_start_syslog',
			'attr_start_x',
			'attr_start_xdmcp',
			'attr_tex_enable',
			'attr_timezone',
			'attr_tvout',
			'attr_vmware',
		],
		[
			'id:pk',
			'name:s.128',
			'priority:i',
			'comment:s.1024',
		]
	);

	return 1;
}

1;
