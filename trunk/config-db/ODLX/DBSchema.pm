package ODLX::DBSchema;

use strict;
use vars qw(@ISA @EXPORT $VERSION);

use Exporter;
$VERSION = 0.01;
@ISA = qw(Exporter);

@EXPORT = qw(
	$DbSchema %DbSchemaHistory
);

use vars qw($DbSchema %DbSchemaHistory);

# TODO: copy attributes from installer/default_files/dhcp.conf

################################################################################
### DB-schema definition
### 	This hash-ref describes the current ODLX configuration database schema.
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
			'name:s.32',		# structured name of OS installation (e.g. suse-9.3-minimal,
								# suse-9.3-kde, debian-3.1-ppc)
			'descr:s.1024',		# internal description (optional, for admins)
			'path:s.256',		# path to os filesystem root
		],
		'system' => [
			# a system describes one bootable instance of a vendor os
			'id:pk',				# primary key
			'vendor_os:fk',			# foreign key
			'name:s.32',			# name used in filesystem and passed to kernel via cmdline arg
									# (e.g.: suse-9.3-minimal, suse-9.3-minimal-nbd, ...)
			'label:s.128',			# visible name (pxe-label)
			'descr:s.1024',			# internal description (optional, for admins)
			'export_uri:s.256',		# path to export (NDB-image or NFS-path)
			'tftp_uri:s.256',		# path to tftp export directory
			'kernel:s.128',			# name of kernel file
			'kernel_params:s.512',	# kernel-param string for pxe
			'initramfs:s.128',		# name of initrd file
			'hidden:b',				# hidden systems won't be offered for booting
		],
		'client' => [
			# a client is a PC booting via net
			'id:pk',			# primary key
			'name:s.128',		# official name of PC (e.g. as given by sticker
								# on case)
			'mac:s.20',			# MAC of NIC used for booting
			'descr:s.1024',		# internal description (for admins)
			'boot_type:s.20',	# type of remote boot procedure (PXE, ...)
		],
		'client_system_ref' => [
			# clients referring to the systems they should offer for booting
			'client_id:fk',		# foreign key
			'system_id:fk',		# foreign key
		],
		'group' => [
			# a group encapsulates a set of clients as one entity
			'id:pk',			# primary key
			'name:s.128',		# name of group
			'descr:s.1024',		# internal description (for admins)
		],
		'group_client_ref' => [
			# groups referring to their clients
			'group_id:fk',		# foreign key
			'client_id:fk',		# foreign key
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
					'descr' => 'internal system that holds default values',
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
					'descr' => 'internal client that holds default values',
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
			'table' => 'group',
			'cols' => $DbSchema->{'tables'}->{'group'},
		},
		{
			'cmd' => 'add-table',
			'table' => 'group_client_ref',
			'cols' => $DbSchema->{'tables'}->{'group_client_ref'},
		},
	],
);

