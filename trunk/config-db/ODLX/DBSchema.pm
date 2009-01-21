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
		'system' => [
			# a system describes a bootable instance of an os
			'id:pk',			# primary key
			'name:s.128',		# visible name (pxe-label)
			'descr:s.1024',		# internal description (for admins)
			'path:s.256',		# path to image
			'os_type:s.20',		# type of OS (Linux, ...)
			'os_name:s.80',		# name of OS (opensuse-10.1, Kubuntu-1, ...)
			'kernel:s.128',		# name of kernel file
			'initrd:s.128',		# name of initrd file
			'hidden:b'			# hidden systems won't be offered for booting
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

