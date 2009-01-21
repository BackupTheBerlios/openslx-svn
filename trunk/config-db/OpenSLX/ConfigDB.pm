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
package OpenSLX::ConfigDB;

use strict;
use warnings;

our (@ISA, @EXPORT_OK, %EXPORT_TAGS, $VERSION);
$VERSION = 1;    # API-version

use Exporter;
@ISA = qw(Exporter);

=pod

=head1 NAME

OpenSLX::ConfigDB - the configuration database API class for OpenSLX

=head1 SYNOPSIS

  use OpenSLX::ConfigDB;

  openslxInit();

  my $openslxDB = OpenSLX::ConfigDB->new();
  $openslxDB->connect();

  # fetch a client by name:
  my $defaultClient = $openslxDB->fetchClientByFilter({'name' => '<<<default>>>'})

  # fetch all systems:
  my @systems = $openslxDB->fetchSystemByFilter();

=head1 DESCRIPTION

This class defines the OpenSLX API to the config database (the data layer to
the outside world).

The ConfigDB interface contains of five different parts:

=over

=item - L<basic methods> (connection handling)

=item - L<data access methods> (getting data)

=item - L<data manipulation methods> (adding, removing and changing data)

=item - L<data aggregation methods> (getting info about the resulting
configurations after mixing individual client-, group- and system-
configurations).

=item - L<suppport functions> (useful helpers)

=back

=head1 Special Concepts

=over

=item C<Filters>

A filter is a hash-ref defining the filter criteria to be applied to a database
query. Each key of the filter corresponds to a DB column and the (hash-)value
contains the respective column value.

[At a later stage, this will be improved to support a more structured approach
to filtering (with boolean operators and hierarchical expressions)].

=back

=cut

my @supportExports = qw(
  isAttribute mergeAttributes pushAttributes
  externalIDForSystem externalIDForClient externalConfigNameForClient
  externalAttrName generatePlaceholderFor
);

@EXPORT_OK   = (@supportExports);
%EXPORT_TAGS = ('support' => [@supportExports],);

use OpenSLX::Basics;
use OpenSLX::DBSchema;
use OpenSLX::Utils;

=head1 Methods

=head2 Basic Methods

=over

=cut

=item C<new()>

Returns an object representing a database handle to the config database.
N.B. this class is implemented as a singleton, so several successive calls to
new will return the *same* object

=cut

sub new
{
	my $class = shift;

	my $self = {
	};

	return bless $self, $class;
}

=item C<connect()>

Tries to establish a connection to the database specified via the db-...
settings.
The global configuration hash C<%openslxConfig> contains further info about the
requested connection. When implementing this method, you may have to look at
the following entries in order to find out which database to connect to:

=over

=item C<$openslxConfig{'db-spec'}>

Full specification of database, a special string defining the
precise database to connect to (this allows connecting to a database
that requires specifications which aren't cared for by the existing
C<%config>-entries).

=item C<$openslxConfig{'db-name'}>

The precise name of the database that should be connected (defaults to 'openslx').

=back

=cut

sub connect		## no critic (ProhibitBuiltinHomonyms)
{
	my $self     = shift;
	my $dbParams = shift;
	# hash-ref with any additional info that might be required by
	# specific metadb-module (not used yet)

	my $dbType = $openslxConfig{'db-type'};
		# name of underlying database module...

	my $dbModuleName = "OpenSLX/MetaDB/$dbType.pm";
	my $dbModule = "OpenSLX::MetaDB::$dbType";
	unless (eval { require $dbModuleName } ) {
		if ($! == 2) {
			die _tr(
				"Unable to load DB-module <%s>\nthat database type is not supported (yet?)\n",
				$dbModuleName
			);
		} else {
			die _tr("Unable to load DB-module <%s> (%s)\n", $dbModuleName, $@);
		}
	}
	my $metaDB = $dbModule->new();
	if (!$metaDB->connect($dbParams)) {
		warn _tr("Unable to connect to DB-module <%s>\n%s", $dbModuleName, $@);
		warn _tr("These DB-modules seem to work ok:");
		foreach my $dbMod ('mysql', 'SQLite') {
			my $fullDbModName = "DBD/$dbMod.pm";
			if (eval { require $fullDbModName }) {
				vlog(0, "\t$dbMod\n");
			}
		}
		die _tr(
			'Please use slxsettings if you want to switch to another db-type.'
		);
	}

	$self->{'db-type'} = $dbType;
	$self->{'meta-db'} = $metaDB;
	foreach my $tk (keys %{$DbSchema->{tables}}) {
		$metaDB->schemaDeclareTable($tk, $DbSchema->{tables}->{$tk});
	}

	_checkAndUpgradeDBSchemaIfNecessary($metaDB);

	return 1;
}

=item C<disconnect()>

Tears down the connection to the database and cleans up.

=cut

sub disconnect
{
	my $self = shift;

	$self->{'meta-db'}->disconnect();

	return 1;
}

=item C<startTransaction()>

Opens a database transaction - most useful if you want to make sure a couple of 
changes apply as a whole or not at all.

=cut

sub startTransaction
{
	my $self = shift;

	$self->{'meta-db'}->startTransaction();

	return 1;
}

=item C<commitTransaction()>

Commits a database transaction - so all changes done inside of this transaction 
will be applied to the database.

=cut

sub commitTransaction
{
	my $self = shift;

	$self->{'meta-db'}->commitTransaction();

	return 1;
}

=item C<rollbackTransaction()>

Revokes a database transaction - so all changes done inside of this transaction 
will be undone.

=cut

sub rollbackTransaction
{
	my $self = shift;

	$self->{'meta-db'}->rollbackTransaction();

	return 1;
}

=back

=head2 Data Access Methods

=over

=cut

=item C<getColumnsOfTable($tableName)>

Returns the names of the columns of the given table.

=over

=item Param C<tableName>

The name of the DB-table whose columns you'd like to retrieve.

=item Return Value

An array of column names.

=back

=cut

sub getColumnsOfTable
{
	my $self      = shift;
	my $tableName = shift;

	return map { (/^(\w+)\W/) ? $1 : $_; } @{$DbSchema->{tables}->{$tableName}};
}

=item C<fetchVendorOSByFilter([%$filter], [$resultCols])>

Fetches and returns information about all vendor-OSes that match the given
filter.

=over

=item Param C<filter>

A hash-ref containing the filter criteria that shall be applied - default
is no filtering. See L</"Filters"> for more info.

=item Param C<resultCols>

A string listing the columns that shall be returned - default is all columns.

=item Return Value

An array of hash-refs containing the resulting data rows.

=back

=cut

sub fetchVendorOSByFilter
{
	my $self       = shift;
	my $filter     = shift;
	my $resultCols = shift;

	my @vendorOS =
	  $self->{'meta-db'}->fetchVendorOSByFilter($filter, $resultCols);

	return wantarray() ? @vendorOS : shift @vendorOS;
}

=item C<fetchVendorOSByID(@$ids, [$resultCols])>

Fetches and returns information the vendor-OSes with the given IDs.

=over

=item Param C<ids>

An array of the vendor-OS-IDs you are interested in.

=item Param C<resultCols>

A string listing the columns that shall be returned - default is all columns.

=item Return Value

An array of hash-refs containing the resulting data rows.

=back

=cut

sub fetchVendorOSByID
{
	my $self       = shift;
	my $ids        = _aref(shift);
	my $resultCols = shift;

	my @vendorOS = $self->{'meta-db'}->fetchVendorOSByID($ids, $resultCols);

	return wantarray() ? @vendorOS : shift @vendorOS;
}

=item C<fetchExportByFilter([%$filter], [$resultCols])>

Fetches and returns information about all exports that match the given
filter.

=over

=item Param C<filter>

A hash-ref containing the filter criteria that shall be applied - default
is no filtering. See L</"Filters"> for more info.

=item Param C<resultCols>

A string listing the columns that shall be returned - default is all columns.

=item Return Value

An array of hash-refs containing the resulting data rows.

=back

=cut

sub fetchExportByFilter
{
	my $self       = shift;
	my $filter     = shift;
	my $resultCols = shift;

	my @exports = $self->{'meta-db'}->fetchExportByFilter($filter, $resultCols);

	return wantarray() ? @exports : shift @exports;
}

=item C<fetchExportByID(@$ids, [$resultCols])>

Fetches and returns information the exports with the given IDs.

=over

=item Param C<ids>

An array of the export-IDs you are interested in.

=item Param C<resultCols>

A string listing the columns that shall be returned - default is all columns.

=item Return Value

An array of hash-refs containing the resulting data rows.

=back

=cut

sub fetchExportByID
{
	my $self       = shift;
	my $ids        = _aref(shift);
	my $resultCols = shift;

	my @exports = $self->{'meta-db'}->fetchExportByID($ids, $resultCols);

	return wantarray() ? @exports : shift @exports;
}

=item C<fetchExportIDsOfVendorOS($id)>

Fetches the IDs of all exports that make use of the vendor-OS with the given ID.

=over

=item Param C<id>

ID of the vendor-OS whose exports shall be returned.

=item Return Value

An array of system-IDs.

=back

=cut

sub fetchExportIDsOfVendorOS
{
	my $self       = shift;
	my $vendorOSID = shift;

	return $self->{'meta-db'}->fetchExportIDsOfVendorOS($vendorOSID);
}

=item C<fetchGlobalInfo($id)>

Fetches the global info element specified by the given ID.

=over

=item Param C<id>

The name of the global info value you are interested in.

=item Return Value

The value of the requested global info.

=back

=cut

sub fetchGlobalInfo
{
	my $self = shift;
	my $id   = shift;

	return $self->{'meta-db'}->fetchGlobalInfo($id);
}

=item C<fetchSystemByFilter([%$filter], [$resultCols])>

Fetches and returns information about all systems that match the given filter.

=over

=item Param C<$filter>

A hash-ref containing the filter criteria that shall be applied - default
is no filtering. See L</"Filters"> for more info.

=item Param C<$resultCols> [Optional]

A comma-separated list of colunm names that shall be returned. If not defined,
all available data must be returned.

=item Return Value

An array of hash-refs containing the resulting data rows.

=back

=cut

sub fetchSystemByFilter
{
	my $self       = shift;
	my $filter     = shift;
	my $resultCols = shift;

	my @systems = $self->{'meta-db'}->fetchSystemByFilter($filter, $resultCols);

	return wantarray() ? @systems : shift @systems;
}

=item C<fetchSystemByID(@$ids, [$resultCols])>

Fetches and returns information the systems with the given IDs.

=over

=item Param C<ids>

An array of the system-IDs you are interested in.

=item Param C<resultCols>

A string listing the columns that shall be returned - default is all columns.

=item Return Value

An array of hash-refs containing the resulting data rows.

=back

=cut

sub fetchSystemByID
{
	my $self       = shift;
	my $ids        = _aref(shift);
	my $resultCols = shift;

	my @systems = $self->{'meta-db'}->fetchSystemByID($ids, $resultCols);

	return wantarray() ? @systems : shift @systems;
}

=item C<fetchSystemIDsOfExport($id)>

Fetches the IDs of all systems that make use of the export with the given ID.

=over

=item Param C<id>

ID of the export whose systems shall be returned.

=item Return Value

An array of system-IDs.

=back

=cut

sub fetchSystemIDsOfExport
{
	my $self     = shift;
	my $exportID = shift;

	return $self->{'meta-db'}->fetchSystemIDsOfExport($exportID);
}

=item C<fetchSystemIDsOfClient($id)>

Fetches the IDs of all systems that are used by the client with the given
ID.

=over

=item Param C<id>

ID of the client whose systems shall be returned.

=item Return Value

An array of system-IDs.

=back

=cut

sub fetchSystemIDsOfClient
{
	my $self     = shift;
	my $clientID = shift;

	return $self->{'meta-db'}->fetchSystemIDsOfClient($clientID);
}

=item C<fetchSystemIDsOfGroup($id)>

Fetches the IDs of all systems that are part of the group with the given
ID.

=over

=item Param C<id>

ID of the group whose systems shall be returned.

=item Return Value

An array of system-IDs.

=back

=cut

sub fetchSystemIDsOfGroup
{
	my $self    = shift;
	my $groupID = shift;

	return $self->{'meta-db'}->fetchSystemIDsOfGroup($groupID);
}

=item C<fetchClientByFilter([%$filter], [$resultCols])>

Fetches and returns information about all clients that match the given filter.

=over

=item Param C<$filter>

A hash-ref containing the filter criteria that shall be applied - default
is no filtering. See L</"Filters"> for more info.

=item Param C<$resultCols> [Optional]

A comma-separated list of colunm names that shall be returned. If not defined,
all available data must be returned.

=item Return Value

An array of hash-refs containing the resulting data rows.

=back

=cut

sub fetchClientByFilter
{
	my $self   = shift;
	my $filter = shift;

	my @clients = $self->{'meta-db'}->fetchClientByFilter($filter);

	return wantarray() ? @clients : shift @clients;
}

=item C<fetchClientByID(@$ids, [$resultCols])>

Fetches and returns information the clients with the given IDs.

=over

=item Param C<ids>

An array of the client-IDs you are interested in.

=item Param C<resultCols>

A string listing the columns that shall be returned - default is all columns.

=item Return Value

An array of hash-refs containing the resulting data rows.

=back

=cut

sub fetchClientByID
{
	my $self       = shift;
	my $ids        = _aref(shift);
	my $resultCols = shift;

	my @clients = $self->{'meta-db'}->fetchClientByID($ids, $resultCols);

	return wantarray() ? @clients : shift @clients;
}

=item C<fetchClientIDsOfSystem($id)>

Fetches the IDs of all clients that make use of the system with the given
ID.

=over

=item Param C<id>

ID of the system whose clients shall be returned.

=item Return Value

An array of client-IDs.

=back

=cut

sub fetchClientIDsOfSystem
{
	my $self     = shift;
	my $systemID = shift;

	return $self->{'meta-db'}->fetchClientIDsOfSystem($systemID);
}

=item C<fetchClientIDsOfGroup($id)>

Fetches the IDs of all clients that are part of the group with the given
ID.

=over

=item Param C<id>

ID of the group whose clients shall be returned.

=item Return Value

An array of client-IDs.

=back

=cut

sub fetchClientIDsOfGroup
{
	my $self    = shift;
	my $groupID = shift;

	return $self->{'meta-db'}->fetchClientIDsOfGroup($groupID);
}

=item C<fetchGroupByFilter([%$filter], [$resultCols])>

Fetches and returns information about all groups that match the given filter.

=over

=item Param C<$filter>

A hash-ref containing the filter criteria that shall be applied - default
is no filtering. See L</"Filters"> for more info.

=item Param C<$resultCols> [Optional]

A comma-separated list of colunm names that shall be returned. If not defined,
all available data must be returned.

=item Return Value

An array of hash-refs containing the resulting data rows.

=back

=cut

sub fetchGroupByFilter
{
	my $self       = shift;
	my $filter     = shift;
	my $resultCols = shift;

	my @groups = $self->{'meta-db'}->fetchGroupByFilter($filter, $resultCols);

	return wantarray() ? @groups : shift @groups;
}

=item C<fetchGroupByID(@$ids, [$resultCols])>

Fetches and returns information the groups with the given IDs.

=over

=item Param C<ids>

An array of the group-IDs you are interested in.

=item Param C<resultCols>

A string listing the columns that shall be returned - default is all columns.

=item Return Value

An array of hash-refs containing the resulting data rows.

=back

=cut

sub fetchGroupByID
{
	my $self       = shift;
	my $ids        = _aref(shift);
	my $resultCols = shift;

	my @groups = $self->{'meta-db'}->fetchGroupByID($ids, $resultCols);

	return wantarray() ? @groups : shift @groups;
}

=item C<fetchGroupIDsOfSystem($id)>

Fetches the IDs of all groups that contain the system with the given
ID.

=over

=item Param C<id>

ID of the system whose groups shall be returned.

=item Return Value

An array of client-IDs.

=back

=cut

sub fetchGroupIDsOfSystem
{
	my $self     = shift;
	my $systemID = shift;

	return $self->{'meta-db'}->fetchGroupIDsOfSystem($systemID);
}

=item C<fetchGroupIDsOfClient($id)>

Fetches the IDs of all groups that contain the client with the given
ID.

=over

=item Param C<id>

ID of the client whose groups shall be returned.

=item Return Value

An array of client-IDs.

=back

=cut

sub fetchGroupIDsOfClient
{
	my $self     = shift;
	my $clientID = shift;

	return $self->{'meta-db'}->fetchGroupIDsOfClient($clientID);
}

=back

=head2 Data Manipulation Methods

=over

=item C<addVendorOS(@$valRows)>

Adds one or more vendor-OS to the database.

=over

=item Param C<valRows>

An array-ref containing hash-refs with the data of the new vendor-OS(es).

=item Return Value

The IDs of the new vendor-OS(es), C<undef> if the creation failed.

=back

=cut

sub addVendorOS
{
	my $self    = shift;
	my $valRows = _aref(shift);

	_checkCols($valRows, 'vendor_os', 'name');

	return $self->{'meta-db'}->addVendorOS($valRows);
}

=item C<removeVendorOS(@$vendorOSIDs)>

Removes one or more vendor-OS from the database.

=over

=item Param C<vendorOSIDs>

An array-ref containing the IDs of the vendor-OSes that shall be removed.

=item Return Value

C<1> if the vendorOS(es) could be removed, C<undef> if not.

=back

=cut

sub removeVendorOS
{
	my $self        = shift;
	my $vendorOSIDs = _aref(shift);

	return $self->{'meta-db'}->removeVendorOS($vendorOSIDs);
}

=item C<changeVendorOS(@$vendorOSIDs, @$valRows)>

Changes the data of one or more vendor-OS.

=over

=item Param C<vendorOSIDs>

An array-ref containing the IDs of the vendor-OSes that shall be changed.

=item Param C<valRows>

An array-ref containing hash-refs with the new data for the vendor-OS(es).

=item Return Value

C<1> if the vendorOS(es) could be changed, C<undef> if not.

=back

=cut

sub changeVendorOS
{
	my $self        = shift;
	my $vendorOSIDs = _aref(shift);
	my $valRows     = _aref(shift);

	return $self->{'meta-db'}->changeVendorOS($vendorOSIDs, $valRows);
}

=item C<addExport(@$valRows)>

Adds one or more export to the database.

=over

=item Param C<valRows>

An array-ref containing hash-refs with the data of the new export(s).

=item Return Value

The IDs of the new export(s), C<undef> if the creation failed.

=back

=cut

sub addExport
{
	my $self    = shift;
	my $valRows = _aref(shift);

	_checkCols($valRows, 'export', qw(name vendor_os_id type));

	return $self->{'meta-db'}->addExport($valRows);
}

=item C<removeExport(@$exportIDs)>

Removes one or more export from the database.

=over

=item Param C<exportIDs>

An array-ref containing the IDs of the exports that shall be removed.

=item Return Value

C<1> if the export(s) could be removed, C<undef> if not.

=back

=cut

sub removeExport
{
	my $self      = shift;
	my $exportIDs = _aref(shift);

	return $self->{'meta-db'}->removeExport($exportIDs);
}

=item C<changeExport(@$exportIDs, @$valRows)>

Changes the data of one or more export.

=over

=item Param C<vendorOSIDs>

An array-ref containing the IDs of the exports that shall be changed.

=item Param C<valRows>

An array-ref containing hash-refs with the new data for the export(s).

=item Return Value

C<1> if the export(s) could be changed, C<undef> if not.

=back

=cut

sub changeExport
{
	my $self      = shift;
	my $exportIDs = _aref(shift);
	my $valRows   = _aref(shift);

	return $self->{'meta-db'}->changeExport($exportIDs, $valRows);
}

=item C<incrementGlobalCounter($counterName)>

Increments the global counter of the given name and returns the *old* value.

=over

=item Param C<counterName>

The name of the global counter that shall be bumped.

=item Return Value

The value the global counter had before it was incremented.

=back

=cut

sub incrementGlobalCounter
{
	my $self        = shift;
	my $counterName = shift;

	$self->startTransaction();
	my $value = $self->fetchGlobalInfo($counterName);
	return unless defined $value;
	my $newValue = $value + 1;
	$self->changeGlobalInfo($counterName, $newValue);
	$self->commitTransaction();

	return $value;
}

=item C<changeGlobalInfo($id, $value)>

Sets the global info element specified by the given ID to the given value.

=over

=item Param C<id>

The ID specifying the global info you'd like to change.

=item Param C<value>

The new value for the global info element.

=item Return Value

The value the global counter had before it was incremented.

=back

=cut

sub changeGlobalInfo
{
	my $self  = shift;
	my $id    = shift;
	my $value = shift;

	return if !defined $self->{'meta-db'}->fetchGlobalInfo($id);

	return $self->{'meta-db'}->changeGlobalInfo($id, $value);
}

=item C<addSystem(@$valRows)>

Adds one or more systems to the database.

=over

=item Param C<valRows>

An array-ref containing hash-refs with the data of the new system(s).

=item Return Value

The IDs of the new system(s), C<undef> if the creation failed.

=back

=cut

sub addSystem
{
	my $self    = shift;
	my $valRows = _aref(shift);

	_checkCols($valRows, 'system', qw(name export_id));

	foreach my $valRow (@$valRows) {
		if (!$valRow->{kernel}) {
			$valRow->{kernel} = 'vmlinuz';
			vlog(
				1,
				_tr(
					"setting kernel of system '%s' to 'vmlinuz'!",
					$valRow->{name}
				)
			);
		}
		if (!$valRow->{label}) {
			$valRow->{label} = $valRow->{name};
		}
	}

	return $self->{'meta-db'}->addSystem($valRows);
}

=item C<removeSystem(@$systemIDs)>

Removes one or more systems from the database.

=over

=item Param C<systemIDs>

An array-ref containing the IDs of the systems that shall be removed.

=item Return Value

C<1> if the system(s) could be removed, C<undef> if not.

=back

=cut

sub removeSystem
{
	my $self      = shift;
	my $systemIDs = _aref(shift);

	foreach my $system (@$systemIDs) {
		$self->setGroupIDsOfSystem($system);
		$self->setClientIDsOfSystem($system);
	}

	return $self->{'meta-db'}->removeSystem($systemIDs);
}

=item C<changeSystem(@$systemIDs, @$valRows)>

Changes the data of one or more systems.

=over

=item Param C<systemIDs>

An array-ref containing the IDs of the systems that shall be changed.

=item Param C<valRows>

An array-ref containing hash-refs with the new data for the system(s).

=item Return Value

C<1> if the system(s) could be changed, C<undef> if not.

=back

=cut

sub changeSystem
{
	my $self      = shift;
	my $systemIDs = _aref(shift);
	my $valRows   = _aref(shift);

	return $self->{'meta-db'}->changeSystem($systemIDs, $valRows);
}

=item C<setClientIDsOfSystem($systemID, @$clientIDs)>

Specifies all clients that should offer the given system for booting.

=over

=item Param C<systemID>

The ID of the system whose clients you'd like to specify.

=item Param C<clientIDs>

An array-ref containing the IDs of the clients that shall be connected to the
system.

=item Return Value

C<1> if the system/client references could be set, C<undef> if not.

=back

=cut

sub setClientIDsOfSystem
{
	my $self      = shift;
	my $systemID  = shift;
	my $clientIDs = _aref(shift);

	my @uniqueClientIDs = _unique(@$clientIDs);

	return $self->{'meta-db'}->setClientIDsOfSystem(
		$systemID, \@uniqueClientIDs
	);
}

=item C<addClientIDsToSystem($systemID, @$clientIDs)>

Add one or more clients to the set that should offer the given system for booting.

=over

=item Param C<systemID>

The ID of the system that you wish to add the clients to.

=item Param C<clientIDs>

An array-ref containing the IDs of the new clients that shall be added to the
system.

=item Return Value

C<1> if the system/client references could be set, C<undef> if not.

=back

=cut

sub addClientIDsToSystem
{
	my $self         = shift;
	my $systemID     = shift;
	my $newClientIDs = _aref(shift);

	my @clientIDs = $self->{'meta-db'}->fetchClientIDsOfSystem($systemID);
	push @clientIDs, @$newClientIDs;

	return $self->setClientIDsOfSystem($systemID, \@clientIDs);
}

=item C<removeClientIDsFromSystem($systemID, @$clientIDs)>

Removes the connection between the given clients and the given system.

=over

=item Param C<systemID>

The ID of the system you'd like to remove groups from.

=item Param C<clientIDs>

An array-ref containing the IDs of the clients that shall be removed from the
system.

=item Return Value

C<1> if the system/client references could be set, C<undef> if not.

=back

=cut

sub removeClientIDsFromSystem
{
	my $self             = shift;
	my $systemID         = shift;
	my $removedClientIDs = _aref(shift);

	my %toBeRemoved;
	@toBeRemoved{@$removedClientIDs} = ();
	my @clientIDs =
	  grep { !exists $toBeRemoved{$_} }
	  $self->{'meta-db'}->fetchClientIDsOfSystem($systemID);

	return $self->setClientIDsOfSystem($systemID, \@clientIDs);
}

=item C<setGroupIDsOfSystem($systemID, @$groupIDs)>

Specifies all groups that should offer the given system for booting.

=over

=item Param C<systemID>

The ID of the system whose groups you'd like to specify.

=item Param C<groupIDs>

An array-ref containing the IDs of the groups that shall be connected to the
system.

=item Return Value

C<1> if the system/group references could be set, C<undef> if not.

=back

=cut

sub setGroupIDsOfSystem
{
	my $self     = shift;
	my $systemID = shift;
	my $groupIDs = _aref(shift);

	my @uniqueGroupIDs = _unique(@$groupIDs);

	return $self->{'meta-db'}->setGroupIDsOfSystem($systemID, \@uniqueGroupIDs);
}

=item C<addGroupIDsToSystem($systemID, @$groupIDs)>

Add one or more groups to the set that should offer the given system for booting.

=over

=item Param C<systemID>

The ID of the system that you wish to add the groups to.

=item Param C<groupIDs>

An array-ref containing the IDs of the new groups that shall be added to the
system.

=item Return Value

C<1> if the system/group references could be set, C<undef> if not.

=back

=cut

sub addGroupIDsToSystem
{
	my $self        = shift;
	my $systemID    = shift;
	my $newGroupIDs = _aref(shift);

	my @groupIDs = $self->{'meta-db'}->fetchGroupIDsOfSystem($systemID);
	push @groupIDs, @$newGroupIDs;

	return $self->setGroupIDsOfSystem($systemID, \@groupIDs);
}

=item C<removeGroupIDsFromSystem($systemID, @$groupIDs)>

Removes the connection between the given groups and the given system.

=over

=item Param C<systemID>

The ID of the system you'd like to remove groups from.

=item Param C<groupIDs>

An array-ref containing the IDs of the groups that shall be removed from the
system.

=item Return Value

C<1> if the system/group references could be set, C<undef> if not.

=back

=cut

sub removeGroupIDsFromSystem
{
	my $self                = shift;
	my $systemID            = shift;
	my $toBeRemovedGroupIDs = _aref(shift);

	my %toBeRemoved;
	@toBeRemoved{@$toBeRemovedGroupIDs} = ();
	my @groupIDs =
	  grep { !exists $toBeRemoved{$_} }
	  $self->{'meta-db'}->fetchGroupIDsOfSystem($systemID);

	return $self->setGroupIDsOfSystem($systemID, \@groupIDs);
}

=item C<addClient(@$valRows)>

Adds one or more clients to the database.

=over

=item Param C<valRows>

An array-ref containing hash-refs with the data of the new client(s).

=item Return Value

The IDs of the new client(s), C<undef> if the creation failed.

=back

=cut

sub addClient
{
	my $self    = shift;
	my $valRows = _aref(shift);

	_checkCols($valRows, 'client', qw(name mac));

	foreach my $valRow (@$valRows) {
		if (!$valRow->{boot_type}) {
			$valRow->{boot_type} = 'pxe';
		}
	}

	return $self->{'meta-db'}->addClient($valRows);
}

=item C<removeClient(@$clientIDs)>

Removes one or more clients from the database.

=over

=item Param C<clientIDs>

An array-ref containing the IDs of the clients that shall be removed.

=item Return Value

C<1> if the client(s) could be removed, C<undef> if not.

=back

=cut

sub removeClient
{
	my $self      = shift;
	my $clientIDs = _aref(shift);

	foreach my $client (@$clientIDs) {
		$self->setGroupIDsOfClient($client);
		$self->setSystemIDsOfClient($client);
	}

	return $self->{'meta-db'}->removeClient($clientIDs);
}

=item C<changeClient(@$clientIDs, @$valRows)>

Changes the data of one or more clients.

=over

=item Param C<clientIDs>

An array-ref containing the IDs of the clients that shall be changed.

=item Param C<valRows>

An array-ref containing hash-refs with the new data for the client(s).

=item Return Value

C<1> if the client(s) could be changed, C<undef> if not.

=back

=cut

sub changeClient
{
	my $self      = shift;
	my $clientIDs = _aref(shift);
	my $valRows   = _aref(shift);

	return $self->{'meta-db'}->changeClient($clientIDs, $valRows);
}

=item C<setSystemIDsOfClient($clientID, @$systemIDs)>

Specifies all systems that should be offered for booting by the given client.

=over

=item Param C<clientID>

The ID of the client whose systems you'd like to specify.

=item Param C<systemIDs>

An array-ref containing the IDs of the systems that shall be connected to the
client.

=item Return Value

C<1> if the client/system references could be set, C<undef> if not.

=back

=cut

sub setSystemIDsOfClient
{
	my $self      = shift;
	my $clientID  = shift;
	my $systemIDs = _aref(shift);

	my @uniqueSystemIDs = _unique(@$systemIDs);

	return $self->{'meta-db'}->setSystemIDsOfClient(
		$clientID, \@uniqueSystemIDs
	);
}

=item C<addSystemIDsToClient($clientID, @$systemIDs)>

Adds some systems to the set that should be offered for booting by the given client.

=over

=item Param C<clientID>

The ID of the client to which you'd like to add systems to.

=item Param C<systemIDs>

An array-ref containing the IDs of the new systems that shall be added to the
client.

=item Return Value

C<1> if the client/system references could be set, C<undef> if not.

=back

=cut

sub addSystemIDsToClient
{
	my $self         = shift;
	my $clientID     = shift;
	my $newSystemIDs = _aref(shift);

	my @systemIDs = $self->{'meta-db'}->fetchSystemIDsOfClient($clientID);
	push @systemIDs, @$newSystemIDs;

	return $self->setSystemIDsOfClient($clientID, \@systemIDs);
}

=item C<removeSystemIDsFromClient($clientID, @$systemIDs)>

Removes some systems from the set that should be offered for booting by the given client.

=over

=item Param C<clientID>

The ID of the client to which you'd like to remove systems from.

=item Param C<systemIDs>

An array-ref containing the IDs of the systems that shall be removed from the
client.

=item Return Value

C<1> if the client/system references could be set, C<undef> if not.

=back

=cut

sub removeSystemIDsFromClient
{
	my $self             = shift;
	my $clientID         = shift;
	my $removedSystemIDs = _aref(shift);

	my %toBeRemoved;
	@toBeRemoved{@$removedSystemIDs} = ();
	my @systemIDs =
	  grep { !exists $toBeRemoved{$_} }
	  $self->{'meta-db'}->fetchSystemIDsOfClient($clientID);

	return $self->setSystemIDsOfClient($clientID, \@systemIDs);
}

=item C<setGroupIDsOfClient($clientID, @$groupIDs)>

Specifies all groups that the given client shall be part of.

=over

=item Param C<clientID>

The ID of the client whose groups you'd like to specify.

=item Param C<groupIDs>

An array-ref containing the IDs of the groups that the client should be part of.

=item Return Value

C<1> if the client/group references could be set, C<undef> if not.

=back

=cut

sub setGroupIDsOfClient
{
	my $self     = shift;
	my $clientID = shift;
	my $groupIDs = _aref(shift);

	my @uniqueGroupIDs = _unique(@$groupIDs);

	return $self->{'meta-db'}->setGroupIDsOfClient($clientID, \@uniqueGroupIDs);
}

=item C<addGroupIDsToClient($clientID, @$groupIDs)>

Adds the given client to the given groups.

=over

=item Param C<clientID>

The ID of the client that you'd like to add to the given groups.

=item Param C<groupIDs>

An array-ref containing the IDs of the groups that shall be added to the
client.

=item Return Value

C<1> if the client/group references could be set, C<undef> if not.

=back

=cut

sub addGroupIDsToClient
{
	my $self        = shift;
	my $clientID    = shift;
	my $newGroupIDs = _aref(shift);

	my @groupIDs = $self->{'meta-db'}->fetchGroupIDsOfClient($clientID);
	push @groupIDs, @$newGroupIDs;

	return $self->setGroupIDsOfClient($clientID, \@groupIDs);
}

=item C<removeGroupsIDsFromClient($clientID, @$groupIDs)>

Removes the given client from the given groups.

=over

=item Param C<clientID>

The ID of the client that you'd like to remove from the given groups.

=item Param C<groupIDs>

An array-ref containing the IDs of the groups that shall be removed from the
client.

=item Return Value

C<1> if the client/group references could be set, C<undef> if not.

=back

=cut

sub removeGroupIDsFromClient
{
	my $self                = shift;
	my $clientID            = shift;
	my $toBeRemovedGroupIDs = _aref(shift);

	my %toBeRemoved;
	@toBeRemoved{@$toBeRemovedGroupIDs} = ();
	my @groupIDs =
	  grep { !exists $toBeRemoved{$_} }
	  $self->{'meta-db'}->fetchGroupIDsOfClient($clientID);

	return $self->setGroupIDsOfClient($clientID, \@groupIDs);
}

=item C<addGroup(@$valRows)>

Adds one or more groups to the database.

=over

=item Param C<valRows>

An array-ref containing hash-refs with the data of the new group(s).

=item Return Value

The IDs of the new group(s), C<undef> if the creation failed.

=back

=cut

sub addGroup
{
	my $self    = shift;
	my $valRows = _aref(shift);

	_checkCols($valRows, 'group', qw(name));

	foreach my $valRow (@$valRows) {
		if (!defined $valRow->{priority}) {
			$valRow->{priority} = '50';
		}
	}
	return $self->{'meta-db'}->addGroup($valRows);
}

=item C<removeGroup(@$groupIDs)>

Removes one or more groups from the database.

=over

=item Param C<groupIDs>

An array-ref containing the IDs of the groups that shall be removed.

=item Return Value

C<1> if the group(s) could be removed, C<undef> if not.

=back

=cut

sub removeGroup
{
	my $self     = shift;
	my $groupIDs = _aref(shift);

	foreach my $group (@$groupIDs) {
		$self->setSystemIDsOfGroup($group, []);
		$self->setClientIDsOfGroup($group, []);
	}

	return $self->{'meta-db'}->removeGroup($groupIDs);
}

=item C<changeGroup(@$groupIDs, @$valRows)>

Changes the data of one or more groups.

=over

=item Param C<groupIDs>

An array-ref containing the IDs of the groups that shall be changed.

=item Param C<valRows>

An array-ref containing hash-refs with the new data for the group(s).

=item Return Value

C<1> if the group(s) could be changed, C<undef> if not.

=back

=cut

sub changeGroup
{
	my $self     = shift;
	my $groupIDs = _aref(shift);
	my $valRows  = _aref(shift);

	return $self->{'meta-db'}->changeGroup($groupIDs, $valRows);
}

=item C<setClientIDsOfGroup($groupID, @$clientIDs)>

Specifies all clients that should be part of the given group.

=over

=item Param C<groupID>

The ID of the group whose clients you'd like to specify.

=item Param C<clientIDs>

An array-ref containing the IDs of the clients that shall be part of the group.

=item Return Value

C<1> if the group/client references could be set, C<undef> if not.

=back

=cut

sub setClientIDsOfGroup
{
	my $self      = shift;
	my $groupID   = shift;
	my $clientIDs = _aref(shift);

	my @uniqueClientIDs = _unique(@$clientIDs);

	return $self->{'meta-db'}->setClientIDsOfGroup($groupID, \@uniqueClientIDs);
}

=item C<addClientIDsToGroup($groupID, @$clientIDs)>

Add some clients to the given group.

=over

=item Param C<groupID>

The ID of the group to which you'd like to add clients.

=item Param C<clientIDs>

An array-ref containing the IDs of the clients that shall be added.

=item Return Value

C<1> if the group/client references could be set, C<undef> if not.

=back

=cut

sub addClientIDsToGroup
{
	my $self         = shift;
	my $groupID      = shift;
	my $newClientIDs = _aref(shift);

	my @clientIDs = $self->{'meta-db'}->fetchClientIDsOfGroup($groupID);
	push @clientIDs, @$newClientIDs;

	return $self->setClientIDsOfGroup($groupID, \@clientIDs);
}

=item C<removeClientIDsFromGroup($groupID, @$clientIDs)>

Remove some clients from the given group.

=over

=item Param C<groupID>

The ID of the group from which you'd like to remove clients.

=item Param C<clientIDs>

An array-ref containing the IDs of the clients that shall be removed.

=item Return Value

C<1> if the group/client references could be set, C<undef> if not.

=back

=cut

sub removeClientIDsFromGroup
{
	my $self             = shift;
	my $groupID          = shift;
	my $removedClientIDs = _aref(shift);

	my %toBeRemoved;
	@toBeRemoved{@$removedClientIDs} = ();
	my @clientIDs =
	  grep { !exists $toBeRemoved{$_} }
	  $self->{'meta-db'}->fetchClientIDsOfGroup($groupID);

	return $self->setClientIDsOfGroup($groupID, \@clientIDs);
}

=item C<setSystemIDsOfGroup($groupID, @$systemIDs)>

Specifies all systems that should be offered for booting by the given group.

=over

=item Param C<groupID>

The ID of the group whose systems you'd like to specify.

=item Param C<systemIDs>

An array-ref containing the IDs of the systems that shall be connected to the
group.

=item Return Value

C<1> if the group/system references could be set, C<undef> if not.

=back

=cut

sub setSystemIDsOfGroup
{
	my $self      = shift;
	my $groupID   = shift;
	my $systemIDs = _aref(shift);

	my @uniqueSystemIDs = _unique(@$systemIDs);

	return $self->{'meta-db'}->setSystemIDsOfGroup($groupID, \@uniqueSystemIDs);
}

=item C<addSystemIDsToGroup($groupID, @$systemIDs)>

Adds some systems to the set that should be offered for booting by the given group.

=over

=item Param C<groupID>

The ID of the group to which you'd like to add systems.

=item Param C<systemIDs>

An array-ref containing the IDs of the systems that shall be added.

=item Return Value

C<1> if the group/system references could be set, C<undef> if not.

=back

=cut

sub addSystemIDsToGroup
{
	my $self         = shift;
	my $groupID      = shift;
	my $newSystemIDs = _aref(shift);

	my @systemIDs = $self->{'meta-db'}->fetchSystemIDsOfGroup($groupID);
	push @systemIDs, @$newSystemIDs;

	return $self->setSystemIDsOfGroup($groupID, \@systemIDs);
}

=item C<removeSystemIDsFromGroup($groupID, @$systemIDs)>

Removes some systems from the set that should be offered for booting by the given group.

=over

=item Param C<groupID>

The ID of the group from which you'd like to remove systems.

=item Param C<systemIDs>

An array-ref containing the IDs of the systems that shall be removed.

=item Return Value

C<1> if the group/system references could be set, C<undef> if not.

=back

=cut

sub removeSystemIDsFromGroup
{
	my $self             = shift;
	my $groupID          = shift;
	my $removedSystemIDs = _aref(shift);

	my %toBeRemoved;
	@toBeRemoved{@$removedSystemIDs} = ();
	my @systemIDs =
	  grep { !exists $toBeRemoved{$_} }
	  $self->{'meta-db'}->fetchSystemIDsOfGroup($groupID);

	return $self->setSystemIDsOfGroup($groupID, \@systemIDs);
}

=item C<emptyDatabase()>

Removes all data from the database - the tables stay, but they will be empty.

=over

=item Return Value

none

=back

=cut

sub emptyDatabase
{    # clears all user-data from the database
	my $self = shift;

	my @groupIDs = map { $_->{id} } $self->fetchGroupByFilter();
	$self->removeGroup(\@groupIDs);

	my @clientIDs = map { $_->{id} }
	  grep { $_->{name} ne '<<<default>>>' } $self->fetchClientByFilter();
	$self->removeClient(\@clientIDs);

	my @sysIDs = map { $_->{id} }
	  grep { $_->{name} ne '<<<default>>>' } $self->fetchSystemByFilter();
	$self->removeSystem(\@sysIDs);

	my @exportIDs = map { $_->{id} } $self->fetchExportByFilter();
	$self->removeExport(\@exportIDs);

	my @vendorOSIDs = map { $_->{id} } $self->fetchVendorOSByFilter();
	$self->removeVendorOS(\@vendorOSIDs);

	return 1;
}

=back

=head2 Data Aggregation Methods

=over

=item C<mergeDefaultAttributesIntoSystem($system)>

merges default system attributes into the given system hash and pushes the default
client attributes on top of that.

=over

=item Param C<system>

The system whose attributes shall be merged into (completed).

=item Return Value

none

=back

=cut

sub mergeDefaultAttributesIntoSystem
{
	my $self   = shift;
	my $system = shift;

	my $defaultSystem = $self->fetchSystemByFilter({name => '<<<default>>>'});
	mergeAttributes($system, $defaultSystem);

	my $defaultClient = $self->fetchClientByFilter({name => '<<<default>>>'});
	pushAttributes($system, $defaultClient);

	return 1;
}

=item C<mergeDefaultAndGroupAttributesIntoClient($client)>

merges default and group configurations into the given client hash.

=over

=item Param C<client>

The client whose attributes shall be merged into (completed).

=item Return Value

none

=back

=cut

sub mergeDefaultAndGroupAttributesIntoClient
{
	my $self   = shift;
	my $client = shift;

	# step over all groups this client belongs to
	# (ordered by priority from highest to lowest):
	my @groupIDs = $self->fetchGroupIDsOfClient($client->{id});
	my @groups   =
	  sort { $a->{priority} <=> $b->{priority} }
	  $self->fetchGroupByID(\@groupIDs);
	foreach my $group (@groups) {
		# merge configuration from this group into the current client:
		vlog(3,
		  _tr('merging from group %d:%s...', $group->{id}, $group->{name}));
		mergeAttributes($client, $group);
	}

	# merge configuration from default client:
	vlog(3, _tr('merging from default client...'));
	my $defaultClient = $self->fetchClientByFilter({name => '<<<default>>>'});
	mergeAttributes($client, $defaultClient);

	return 1;
}

=item C<aggregatedSystemIDsOfClient($client)>

Returns an aggregated list of system-IDs that this client should offer for
booting (as indicated by itself, the default client and the client's groups)

=over

=item Param C<client>

The client whose aggregated systems you're interested in.

=item Return Value

A list of unqiue system-IDs.

=back

=cut

sub aggregatedSystemIDsOfClient
{
	my $self   = shift;
	my $client = shift;

	# add all systems directly linked to client:
	my @systemIDs = $self->fetchSystemIDsOfClient($client->{id});

	# step over all groups this client belongs to:
	my @groupIDs = $self->fetchGroupIDsOfClient($client->{id});
	my @groups   = $self->fetchGroupByID(\@groupIDs);
	foreach my $group (@groups) {
		# add all systems that the client inherits from the current group:
		push @systemIDs, $self->fetchSystemIDsOfGroup($group->{id});
	}

	# add all systems inherited from default client
	my $defaultClient = $self->fetchClientByFilter({name => '<<<default>>>'});
	push @systemIDs, $self->fetchSystemIDsOfClient($defaultClient->{id});

	return _unique(@systemIDs);
}

=item C<aggregatedClientIDsOfSystem($system)>

Returns an aggregated list of client-IDs that offer this system for
booting (as indicated by itself, the default system and the system's groups)

=over

=item Param C<system>

The system whose aggregated clients you're interested in.

=item Return Value

A list of unqiue client-IDs.

=back

=cut

sub aggregatedClientIDsOfSystem
{
	my $self   = shift;
	my $system = shift;

	# add all clients directly linked to system:
	my $defaultClient = $self->fetchClientByFilter({name => '<<<default>>>'});
	my @clientIDs = $self->fetchClientIDsOfSystem($system->{id});

	if (grep { $_ == $defaultClient->{id}; } @clientIDs) {
		# add *all* client-IDs if the system is being referenced by
		# the default client, as that means that all clients should offer
		# this system for booting:
		push @clientIDs,
		  map { $_->{id} } $self->fetchClientByFilter(undef, 'id');
	}

	# step over all groups this system belongs to:
	my @groupIDs = $self->fetchGroupIDsOfSystem($system->{id});
	my @groups   = $self->fetchGroupByID(\@groupIDs);
	foreach my $group (@groups) {
		# add all clients that the system inherits from the current group:
		push @clientIDs, $self->fetchClientIDsOfGroup($group->{id});
	}

	# add all clients inherited from default system
	my $defaultSystem = $self->fetchSystemByFilter({name => '<<<default>>>'});
	push @clientIDs, $self->fetchClientIDsOfSystem($defaultSystem->{id});

	return _unique(@clientIDs);
}

=item C<aggregatedSystemFileInfoFor($system)>

Returns aggregated information about the kernel and initialramfs
this system is using.

=over

=item Param C<system>

The system whose aggregated info you're interested in.

=item Return Value

A hash containing detailled info about the vendor-OS and export used by
this system, as well as the specific kernel-file and export-URI being used.

=back

=cut

sub aggregatedSystemFileInfoFor
{
	my $self   = shift;
	my $system = shift;

	my $info = {%$system};

	my $export = $self->fetchExportByID($system->{export_id});
	if (!defined $export) {
		die _tr(
			"DB-problem: system '%s' references export with id=%s, but that doesn't exist!",
			$system->{name}, $system->{export_id} || ''
		);
	}
	$info->{'export'} = $export;

	my $vendorOS = $self->fetchVendorOSByID($export->{vendor_os_id});
	if (!defined $vendorOS) {
		die _tr(
			"DB-problem: export '%s' references vendor-OS with id=%s, but that doesn't exist!",
			$export->{name}, $export->{vendor_os_id} || ''
		);
	}
	$info->{'vendor-os'} = $vendorOS;

	# check if the specified kernel file really exists (follow links while
	# checking) and if not, find the newest kernel file that is available.
	my $kernelPath =
	  "$openslxConfig{'private-path'}/stage1/$vendorOS->{name}/boot";
	my $kernelFile = "$kernelPath/$system->{kernel}";
	while (-l $kernelFile) {
		$kernelFile = followLink($kernelFile);
	}
	if (!-e $kernelFile) {
		# pick best kernel file available
		my $osSetupEngine = instantiateClass("OpenSLX::OSSetup::Engine");
		$osSetupEngine->initialize($vendorOS->{name}, 'none');
		$kernelFile = $osSetupEngine->pickKernelFile($kernelPath);
		warn(
			_tr(
				"setting kernel of system '%s' to '%s'!",
				$info->{name}, $kernelFile
			)
		);
	}
	$info->{'kernel-file'} = $kernelFile;

	# auto-generate export_uri if none has been given
	my $exportURI = $export->{'uri'} || '';
	if ($exportURI !~ m[\w]) {
		# instantiate OSExport engine and ask it for exportURI
		my $osExportEngine = instantiateClass("OpenSLX::OSExport::Engine");
		$osExportEngine->initializeFromExisting($export->{name});
		$exportURI = $osExportEngine->generateExportURI($export, $vendorOS);
	}
	$info->{'export-uri'} = $exportURI;

	return $info;
}

=back

=head2 Support Functions

=over

=item C<isAttribute($key)>

Returns whether or not the given key is an exportable attribute.

=over

=item Param C<system>

The key to check.

=item Return Value

1 if the given key is indeed an attribute (currently, this means that
it starts with 'attr_'), 0 if not.

=back

=cut

sub isAttribute
{
	my $key = shift;

	return $key =~ m[^attr_];
}

=item C<mergeAttributes($target, $source)>

Copies all attributes from source that are unset in target over (source extends target).

=over

=item Param C<target>

The hash to be used as copy target.

=item Param C<source>

The hash to be used as copy source.

=item Return Value

none

=back

=cut

sub mergeAttributes
{
	my $target = shift;
	my $source = shift;

	foreach my $key (grep { isAttribute($_) } keys %$source) {
		my $sourceVal = $source->{$key} || '';
		my $targetVal = $target->{$key} || '';
		if (length($sourceVal) && !length($targetVal)) {
			vlog(3, _tr("merging %s (val=%s)", $key, $sourceVal));
			$target->{$key} = $sourceVal;
		}
	}

	return 1;
}

=item C<pushAttributes($target, $source)>

Copies all attributes that are set in source into the target (source overrules target).

=over

=item Param C<target>

The hash to be used as copy target.

=item Param C<source>

The hash to be used as copy source.

=item Return Value

none

=back

=cut

sub pushAttributes
{
	my $target = shift;
	my $source = shift;

	foreach my $key (grep { isAttribute($_) } keys %$source) {
		my $sourceVal = $source->{$key} || '';
		if (length($sourceVal)) {
			vlog(3, _tr("pushing %s (val=%s)", $key, $sourceVal));
			$target->{$key} = $sourceVal;
		}
	}

	return 1;
}

=item C<externalIDForSystem($system)>

Returns the given system's name as an external ID - worked into a
state that is usable as a filename.

=over

=item Param C<system>

The system you are interested in.

=item Return Value

The external ID (name) of the given system.

=back

=cut

sub externalIDForSystem
{
	my $system = shift;

	return "default" if $system->{name} eq '<<<default>>>';

	my $name = $system->{name};
	$name =~ tr[/][_];

	return $name;
}

=item C<externalIDForClient($client)>

Returns the given client's MAC as an external ID - worked into a
state that is usable as a filename.

=over

=item Param C<client>

The client you are interested in.

=item Return Value

The external ID (MAC) of the given client.

=back

=cut

sub externalIDForClient
{
	my $client = shift;

	return "default" if $client->{name} eq '<<<default>>>';

	my $mac = lc($client->{mac});
	# PXE seems to expect MACs being all lowercase
	$mac =~ tr[:][-];

	return "01-$mac";
}

=item C<externalConfigNameForClient($client)>

Returns the given client's name as an external ID - worked into a
state that is usable as a filename.

=over

=item Param C<client>

The client you are interested in.

=item Return Value

The external name of the given client.

=back

=cut

sub externalConfigNameForClient
{
	my $client = shift;

	return "default" if $client->{name} eq '<<<default>>>';

	my $name = $client->{name};
	$name =~ tr[/][_];

	return $name;
}

=item C<externalAttrName($attr)>

Returns the given attribute as it is referenced externally - without the
'attr'_-prefix.

=over

=item Param C<attr>

The attribute you are interested in.

=item Return Value

The external name of the given attribute.

=back

=cut

sub externalAttrName
{
	my $attr = shift;

	if ($attr =~ m[^attr_]) {
		return substr($attr, 5);
	}

	return $attr;
}

=item C<generatePlaceholdersFor($varName)>

Returns the given variable as a placeholder - surrounded by '@@@' markers.

=over

=item Param C<varName>

The variable you are interested in.

=item Return Value

The given variable as a placeholder string.

=back

=cut

sub generatePlaceholderFor
{
	my $varName = shift;

	return '@@@' . $varName . '@@@';
}

################################################################################
### private stuff
################################################################################
sub _checkAndUpgradeDBSchemaIfNecessary
{
	my $metaDB = shift;

	vlog(2, "trying to determine schema version...");
	my $currVersion = $metaDB->schemaFetchDBVersion();
	if (!defined $currVersion) {
		# that's bad, someone has messed with our DB, as there is a
		# database, but the 'meta'-table is empty. There might still
		# be data in the other tables, but we have no way to find out
		# which schema version they're in. So it's safer to give up:
		croak _tr('Could not determine schema version of database');
	}

	if ($currVersion < $DbSchema->{version}) {
		vlog(1,
		  _tr('Our schema-version is %s, DB is %s, upgrading DB...',
			$DbSchema->{version}, $currVersion));
		foreach my $v (sort { $a <=> $b } keys %DbSchemaHistory) {
			next if $v <= $currVersion;
			my $changeSet = $DbSchemaHistory{$v};
			foreach my $c (0 .. scalar(@$changeSet) - 1) {
				my $changeDescr = @{$changeSet}[$c];
				my $cmd         = $changeDescr->{cmd};
				if ($cmd eq 'add-table') {
					$metaDB->schemaAddTable(
						$changeDescr->{'table'},
						$changeDescr->{'cols'},
						$changeDescr->{'vals'}
					);
				} elsif ($cmd eq 'drop-table') {
					$metaDB->schemaDropTable($changeDescr->{'table'});
				} elsif ($cmd eq 'rename-table') {
					$metaDB->schemaRenameTable(
						$changeDescr->{'old-table'},
						$changeDescr->{'new-table'},
						$changeDescr->{'cols'}
					);
				} elsif ($cmd eq 'add-columns') {
					$metaDB->schemaAddColumns(
						$changeDescr->{'table'},
						$changeDescr->{'new-cols'},
						$changeDescr->{'new-default-vals'},
						$changeDescr->{'cols'}
					);
				} elsif ($cmd eq 'drop-columns') {
					$metaDB->schemaDropColumns(
						$changeDescr->{'table'},
						$changeDescr->{'drop-cols'},
						$changeDescr->{'cols'}
					);
				} elsif ($cmd eq 'rename-columns') {
					$metaDB->schemaRenameColumns(
						$changeDescr->{'table'},
						$changeDescr->{'col-renames'},
						$changeDescr->{'cols'}
					);
				} else {
					croak _tr('UnknownDbSchemaCommand', $cmd);
				}
			}
		}
		vlog(1, _tr('upgrade done'));
	} else {
		vlog(1, _tr('DB matches current schema version %s', $currVersion));
	}

	return 1;
}

sub _aref
{    # transparently converts the given reference to an array-ref
	my $ref = shift;
	return [] unless defined $ref;
	$ref = [$ref] unless ref($ref) eq 'ARRAY';

	return $ref;
}

sub _unique
{    # return given array filtered to unique elements
	my %seenIDs;

	return grep { !$seenIDs{$_}++; } @_;
}

sub _checkCols
{
	my $valRows  = shift;
	my $table    = shift;
	my @colNames = @_;

	foreach my $valRow (@$valRows) {
		foreach my $col (@colNames) {
			die "need to set '$col' for $table!" if !$valRow->{$col};
		}
	}

	return 1;
}

1;
