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
	'attr_domain_name:s.64',
	'attr_domain_name_servers:s.128',
	'attr_font_servers:s.128',
	'attr_hw_graphic:s.64',
	'attr_hw_monitor:s.64',
	'attr_hw_mouse:s.64',
	'attr_language:s.64',
	'attr_lpr_servers:s.128',
	'attr_netbios_workgroup:s.64',
	'attr_nis_domain:s.64',
	'attr_nis_servers:s.128',
	'attr_ntp_servers:s.128',
	'attr_start_rwhod:b',
	'attr_start_snmp:b',
	'attr_start_x:s.64',
	'attr_start_xdmcp:s.64',
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
			# a vendor os describes a folder containing an operating system as provided by the
			# vendor (a.k.a. unchanged and thus updatable)
			'id:pk',			# primary key
			'name:s.48',		# structured name of OS installation (e.g. suse-9.3-minimal,
								# suse-9.3-kde, debian-3.1-ppc)
			'comment:s.1024',	# internal comment (optional, for admins)
			'path:s.256',		# path to os filesystem root
		],
		'system' => [
			# a system describes one bootable instance of a vendor os
			'id:pk',				# primary key
			'vendor_os_id:fk',		# foreign key
			'name:s.48',			# name used in filesystem and passed to kernel via cmdline arg
									# (e.g.: suse-9.3-minimal, suse-9.3-minimal-nbd, ...)
			'label:s.128',			# name visible to user (pxe-label)
			'comment:s.1024',		# internal comment (optional, for admins)
			'export_type:s.10',		# 'nbd', 'nbd-squash', 'nfs', ...
			'export_uri:s.256',		# path to export (NDB-image or NFS-path)
			'kernel:s.128',			# path to kernel file, relative to OS root
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
		'system_variant' => [
			# a system_variant describes an alternative boot setup for a system
			# which will always be offered if the systems itself is offered by
			# a client
			'id:pk',				# primary key
			'name_addition:s.48',	# string added to system name in order to
									# get a unique system name
			'system_id:fk',			# foreign key
			'label_addition:s.64',	# visible name part (added to pxe-label)
			'comment:s.1024',		# internal comment (optional, for admins)
			'kernel:s.128',			# name of kernel file
			'kernel_params:s.512',	# kernel-param string for pxe
			'ramfs_debug_level:i',	# debug level for initramfs-generator-script
			'ramfs_use_glibc:b',	# use glibc in ramfs
			'ramfs_use_busybox:b',	# use busybox in ramfs
			'ramfs_nicmods:s.128',	# list of network interface card modules
			'ramfs_fsmods:s.128',	# list of filesystem modules
			'ramfs_screen:s.10',	# screen size for splash
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
### 			'cols' => contains a list of column descriptions
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
			'table' => 'system_variant',
			'cols' => $DbSchema->{'tables'}->{'system_variant'},
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
	],
);

