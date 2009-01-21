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
use vars qw(@ISA @EXPORT $VERSION);

use Exporter;
$VERSION = 0.01;
@ISA = qw(Exporter);

@EXPORT = qw(
	$DbSchema %DbSchemaHistory
);

use vars qw($DbSchema %DbSchemaHistory);

# configurable attributes for system, client and group:
my @sharedAttributes = (
	'attr_desktop_session:s.128',
	'attr_hw_graphic:s.64',
	'attr_hw_monitor:s.64',
	'attr_hw_mouse:s.64',
	'attr_language:s.64',
	'attr_netbios_workgroup:s.64',
	'attr_start_rwhod:b',
	'attr_start_snmp:b',
	'attr_start_x:s.64',
	'attr_start_xdmcp:s.64',
	'attr_auth_type:s.64',
	'attr_home_type:s.64',
	'attr_tex_enable:b',
	'attr_vmware:b',
);

################################################################################
### DB-schema definition
### 	This hash-ref describes the current OpenSLX configuration database schema.
### 	Each table is defined by a list of column descriptions.
### 	A column description is simply the name of the column followed by ':'
### 	followed by the data type description. The following data types are
### 	currently supported:
### 		b		=> boolean (providing the values 1 and 0 only)
### 		i		=> integer (32-bit, signed)
### 		s.20	=> string, followed by length argument (in this case: 20)
### 		pk		=> primary key (integer)
### 		fk		=> foreign key (integer)
################################################################################

$DbSchema = {
	'version' => $VERSION,
	'tables' => {
		'meta' => [
			# information about the database as such
			'schema_version:s.5',	# schema-version currently implemented by DB
		],
		'vendor_os' => [
			# a vendor-OS describes a folder containing an operating system as
			# provided by the vendor (a.k.a. unchanged and thus updatable)
			'id:pk',				# primary key
			'name:s.48',			# structured name of OS installation
									# (e.g. suse-9.3-kde, debian-3.1-ppc,
									# suse-10.2-cloned-from-kiwi).
									# This is used as the folder name for the
									# corresponding stage1, too.
			'comment:s.1024',		# internal comment (optional, for admins)
			'clone_source:s.256',	# if vendor-OS was cloned, this contains
									# the rsync-URI pointing to the original
			'export_counter:i',		# counter used for export names
		],
		'export' => [
			# an export describes a vendor-OS "wrapped" in some kind of exporting
			# format (NFS or NBD-squash). This represents the rootfs that the
			# clients will see.
			'id:pk',				# primary key
			'name:s.64',			# unique name of export, is automatically
									# constructed like this:
									#   <vendor-os-name>-<export-type>
			'vendor_os_id:fk',		# foreign key
			'comment:s.1024',		# internal comment (optional, for admins)
			'type:s.10',			# 'nbd-squash', 'nfs', ...
			'uri:s.256',			# path to export (squashfs or NFS-path), if
									# empty it will be auto-generated by
									# config-demuxer
		],
		'system' => [
			# a system describes one bootable instance of an export, it
			# represents a selectable line in the PXE boot menu of all the
			# clients associated with this system
			'id:pk',				# primary key
			'export_id:fk',			# foreign key
			'name:s.64',			# unique name of system, is automatically
									# constructed like this:
									#   <vendor-os-name>-<export-type>-<kernel>
			'label:s.64',			# name visible to user (pxe-label)
									# if empty, this will be autocreated from
									# the name
			'comment:s.1024',		# internal comment (optional, for admins)
			'kernel:s.128',			# path to kernel file, relative to /boot
			'kernel_params:s.512',	# kernel-param string for pxe
			'ramfs_debug_level:i',	# debug level for initramfs-generator-script
			'ramfs_use_glibc:b',	# use glibc in ramfs
			'ramfs_use_busybox:b',	# use busybox in ramfs
			'ramfs_nicmods:s.128',	# list of network interface card modules
			'ramfs_fsmods:s.128',	# list of filesystem modules
			'ramfs_screen:s.10',	# screen size for splash
			'hidden:b',				# hidden systems won't be offered for booting
			@sharedAttributes,
		],
		'client' => [
			# a client is a PC booting via network
			'id:pk',			# primary key
			'name:s.128',		# official name of PC (e.g. as given by sticker
								# on case)
			'mac:s.20',			# MAC of NIC used for booting
			'comment:s.1024',	# internal comment (optional, for admins)
			'boot_type:s.20',	# type of remote boot procedure (PXE, ...)
			'unbootable:b',		# unbootable clients simply won't boot
			'kernel_params:s.128',	# client-specific kernel-args (e.g. console)
			@sharedAttributes,
		],
		'client_system_ref' => [
			# clients referring to the systems they should offer for booting
			'client_id:fk',		# foreign key
			'system_id:fk',		# foreign key
		],
		'groups' => [
			# a group encapsulates a set of clients as one entity, managing
			# a group-specific attribute set. All the different attribute
			# sets a client inherits via group membership are folded into
			# one resulting attribute set with respect to each group's priority.
			'id:pk',			# primary key
			'name:s.128',		# name of group
			'comment:s.1024',	# internal comment (optional, for admins)
			'priority:i',		# priority, used for order in group-list
								# (from 0-lowest to 10-highest)
			@sharedAttributes,
		],
		'group_client_ref' => [
			# groups referring to their clients
			'group_id:fk',		# foreign key
			'client_id:fk',		# foreign key
		],
		'group_system_ref' => [
			# groups referring to the systems each of their clients should
			# offer for booting
			'group_id:fk',		# foreign key
			'system_id:fk',		# foreign key
		],
		'settings' => [
			# system-wide settings
			'default_nicmods:s.256',
								# list of default network modules
		],
	},
};

################################################################################
### DB-schema history
### 	This hash contains a description of all the different changes that have
### 	taken place on the schema. Each version contains a changeset (array)
### 	with the commands that take the schema from the last version to the
### 	current.
### 	The following 'cmd'-types are supported:
### 		add-table => creates a new table
### 			'table' => contains the name of the new table
### 			'cols'	=> contains a list of column descriptions
### 			'vals'	=> optional, contains list of data hashes to be inserted
### 					   into new table
### 		drop-table => drops an existing table
### 			'table	=> contains the name of the table to be dropped
### 		rename-table => renames a table
### 			'old-table' => contains the old name of the table
### 			'new-table' => contains the new name of the table
### 		add-columns => adds columns to a table
### 			'table' => the name of the table the columns should be added to
### 			'new-cols' => contains a list of new column descriptions
### 			'new-default-vals' => optional, a list of data hashes to be used
###							 		  as default values for the new columns
### 			'cols' => contains a full list of resulting column descriptions
### 		drop-columns => drops columns from a table
### 			'table' => the name of the table the columns should be dropped from
### 			'col-changes' => a hash with changed column descriptions
### 			'cols'	=> contains a full list of resulting column descriptions
################################################################################

%DbSchemaHistory = (
	'0.01' => [
		# the initial schema version simply adds a couple of tables:
		{
			'cmd' => 'add-table',
			'table' => 'meta',
			'cols' => $DbSchema->{'tables'}->{'meta'},
			'vals' => [
				{	# add initial meta info
					'schema_version' => $DbSchema->{'version'},
				},
			],
		},
		{
			'cmd' => 'add-table',
			'table' => 'vendor_os',
			'cols' => $DbSchema->{'tables'}->{'vendor_os'},
		},
		{
			'cmd' => 'add-table',
			'table' => 'export',
			'cols' => $DbSchema->{'tables'}->{'export'},
		},
		{
			'cmd' => 'add-table',
			'table' => 'system',
			'cols' => $DbSchema->{'tables'}->{'system'},
			'vals' => [
				{	# add default system
					'id' => 0,
					'name' => '<<<default>>>',
					'comment' => 'internal system that holds default values',
				},
			],
		},
		{
			'cmd' => 'add-table',
			'table' => 'client',
			'cols' => $DbSchema->{'tables'}->{'client'},
			'vals' => [
				{	# add default client
					'id' => 0,
					'name' => '<<<default>>>',
					'comment' => 'internal client that holds default values',
				},
			],
		},
		{
			'cmd' => 'add-table',
			'table' => 'client_system_ref',
			'cols' => $DbSchema->{'tables'}->{'client_system_ref'},
		},
		{
			'cmd' => 'add-table',
			'table' => 'groups',
			'cols' => $DbSchema->{'tables'}->{'groups'},
		},
		{
			'cmd' => 'add-table',
			'table' => 'group_client_ref',
			'cols' => $DbSchema->{'tables'}->{'group_client_ref'},
		},
		{
			'cmd' => 'add-table',
			'table' => 'group_system_ref',
			'cols' => $DbSchema->{'tables'}->{'group_system_ref'},
		},
		{
			'cmd' => 'add-table',
			'table' => 'settings',
			'cols' => $DbSchema->{'tables'}->{'settings'},
			'vals' => [
				{	# add default configuration
					'default_nicmods'
						=> 'forcedeth e1000 e100 tg3 via-rhine r8169 pcnet32',
				},
			],
		},
	],
);

