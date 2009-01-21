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
# Base.pm
#	- provides empty base of the OpenSLX MetaDB API.
# -----------------------------------------------------------------------------
package OpenSLX::MetaDB::Base;

use strict;

use vars qw($VERSION);
$VERSION = 1.01;		# API-version . implementation-version

use Carp;

################################################################################
### basic functions
################################################################################
sub new
{
	confess "Don't create OpenSLX::MetaDB::Base - objects directly!";
}

sub connect
{
}

sub disconnect
{
}

sub quote
{
}

################################################################################
### data access interface
################################################################################
sub fetchVendorOSByFilter
{
}

sub fetchVendorOSByID
{
}

sub fetchExportByFilter
{
}

sub fetchExportByID
{
}

sub fetchExportIDsOfVendorOS
{
}

sub fetchSystemByFilter
{
}

sub fetchSystemByID
{
}

sub fetchSystemIDsOfExport
{
}

sub fetchSystemIDsOfClient
{
}

sub fetchSystemIDsOfGroup
{
}

sub fetchClientByFilter
{
}

sub fetchClientByID
{
}

sub fetchClientIDsOfSystem
{
}

sub fetchClientIDsOfGroup
{
}

sub fetchGroupByFilter
{
}

sub fetchGroupByID
{
}

sub fetchGroupIDsOfClient
{
}

sub fetchGroupIDsOfSystem
{
}

sub fetchSettings
{
}

################################################################################
### data manipulation interface
################################################################################
sub generateNextIdForTable
{	# some DBs (CSV for instance) aren't able to generate any IDs, so we
	# offer an alternative way (by pre-specifying IDs for INSERTs).
	# NB: if this method is called without a tablename, it returns:
	# 	  1 if this backend requires manual ID generation
	# 	  0 if not.
	return undef;
}

sub addVendorOS
{
}

sub removeVendorOS
{
}

sub changeVendorOS
{
}

sub addExport
{
}

sub removeExport
{
}

sub changeExport
{
}

sub addSystem
{
}

sub removeSystem
{
}

sub changeSystem
{
}

sub setClientIDsOfSystem
{
}

sub setGroupIDsOfSystem
{
}

sub addClient
{
}

sub removeClient
{
}

sub changeClient
{
}

sub setSystemIDsOfClient
{
}

sub setGroupIDsOfClient
{
}

sub addGroup
{
}

sub removeGroup
{
}

sub changeGroup
{
}

sub setClientIDsOfGroup
{
}

sub setSystemIDsOfGroup
{
}

sub changeSettings
{
}

################################################################################
### schema related functions
################################################################################
sub schemaFetchDBVersion
{
}

sub schemaConvertTypeDescrToNative
{
}

sub schemaDeclareTable
{
}

sub schemaAddTable
{
}

sub schemaDropTable
{
}

sub schemaRenameTable
{
}

sub schemaAddColumns
{
}

sub schemaDropColumns
{
}

sub schemaChangeColumns
{
}

1;
################################################################################

=pod

=head1 NAME

OpenSLX::MetaDB::Base - the base class for all MetaDB drivers

=head1 SYNOPSIS

  package OpenSLX::MetaDB::coolnewDB;

  use vars qw(@ISA $VERSION);
  @ISA = ('OpenSLX::MetaDB::Base');
  $VERSION = 1.01;

  my $superVersion = $OpenSLX::MetaDB::Base::VERSION;
  if ($superVersion < $VERSION) {
      confess _tr('Unable to load module <%s> (Version <%s> required)',
                  'OpenSLX::MetaDB::Base', $VERSION);
  }

  use coolnewDB;

  sub new
  {
      my $class = shift;
      my $self = {};
      return bless $self, $class;
  }

  sub connectConfigDB
  {
      my $self = shift;

      my $dbName = $openslxConfig{'db-name'};
      vlog 1, "trying to connect to coolnewDB-database <$dbName>";
      $self->{'dbh'} = ... # get connection handle from coolnewDB
  }

  sub disconnectConfigDB
  {
      my $self = shift;

      $self->{'dbh'}->disconnect;
  }

  # override all methods of OpenSLX::MetaDB::Base in order to implement
  # a full MetaDB driver
  ...

I<The synopsis above outlines a class that implements a
MetaDB driver for the (imaginary) database B<coolnewDB>>

=head1 DESCRIPTION

This class defines the MetaDB interface for the OpenSLX.

Aim of the MetaDB abstraction is to make it possible to use a large set
of different databases (from CSV-files to a fullblown Oracle-installation)
transparently.

While OpenSLX::ConfigDB represents the data layer to the outside world, each
implementation of OpenSLX::MetaDB::Base provides a backend for a specific database.

This way, the different OpenSLX-scripts do not have to burden
themselves with any DB-specific details, they just request the data they want
from the ConfigDB-layer and that in turn creates and communicates with the
appropriate MetaDB driver in order to connect to the database and fetch and/or
change the data as instructed.

The MetaDB interface contains of four different parts:

=over

=item - L<basic methods> (connection handling and utilities)

=item - L<data access methods> (getting data)

=item - L<data manipulation methods> (adding, removing and changing data)

=item - L<schema related methods> (migrating between different DB-versions)

=back

In order to implement a MetaDB driver for a specific database, you need
to inherit from B<OpenSLX::MetaDB::Base> and implement the full interface. As this
is quite some work, it might be wiser to actually inherit your driver from
B<L<OpenSLX::MetaDB::DBI|OpenSLX::MetaDB::DBI>>, which is a default implementation for SQL databases.

If there is a DBD-driver for the database your new MetaDB driver wants to talk
to then all you need to do is inherit from B<OpenSLX::MetaDB::DBI> and then
reimplement L<C<connectConfigDB>> (and maybe some other methods in order to
improve efficiency).

=head1 Special Concepts

=over

=item C<Filters>

A filter is a hash-ref defining the filter criteria to be applied to a database
query. Each key of the filter corresponds to a DB column and the (hash-)value
contains the respective column value.

[At a later stage, this will be improved to support a more structured approach
to filtering (with boolean operators and hierarchical expressions)].

=back

=head1 Methods

=head2 Basic Methods

The following basic methods need to be implemented in a MetaDB driver:

=over

=item C<connectConfigDB()>

Tries to establish a connection to the DBMS that this MetaDB driver deals with.
The global configuration hash C<%config> contains further info about the
requested connection. When implementing this method, you may have to look at
the following entries in order to find out which database to connect to:

=over

=item C<$config{'db-basepath'}>

Basic path to openslx database, defaults to path of running script

=item C<$config{'db-datadir'}>

Data folder created under db-basepath, default depends on db-type (many
DBMSs don't have such a folder, as they do not store the data in the
filesystem).

=item C<$config{'db-spec'}>

Full specification of database, a special string defining the
precise database to connect to (this allows connecting to a database
that requires specifications which aren't cared for by the existing
C<%config>-entries).

=item C<$config{'db-name'}>

The precise name of the database that should be connected (defaults to 'openslx').

=back

=item C<disconnectConfigDB()>

Tears down the connection to the DBMS that this MetaDB driver deals with and
cleans up.

=item C<quote(string)>

Returns the given string quoted such that it can be used in SQL-statements
(with respect to the corresponding DBMS).

This usually involves putting
single quotes around the string and escaping any single quote characters
enclosed in the given string with a backslash.

=back

=head2 Data Access Methods

The following methods need to be implemented in a MetaDB driver in order to
allow the user to access data:

=over

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

=item C<fetchExportIDsOfVendorOS($id)>

Fetches the IDs of all exports that make use of the vendor-OS with the given ID.

=over

=item Param C<id>

ID of the vendor-OS whose exports shall be returned.

=item Return Value

An array of system-IDs.

=back

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

=item C<fetchSystemIDsOfExport($id)>

Fetches the IDs of all systems that make use of the export with the given ID.

=over

=item Param C<id>

ID of the export whose systems shall be returned.

=item Return Value

An array of system-IDs.

=back

=item C<fetchSystemIDsOfClient($id)>

Fetches the IDs of all systems that are used by the client with the given
ID.

=over

=item Param C<id>

ID of the client whose systems shall be returned.

=item Return Value

An array of system-IDs.

=back

=item C<fetchSystemIDsOfGroup($id)>

Fetches the IDs of all systems that are part of the group with the given
ID.

=over

=item Param C<id>

ID of the group whose systems shall be returned.

=item Return Value

An array of system-IDs.

=back

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

=item C<fetchClientIDsOfSystem($id)>

Fetches the IDs of all clients that make use of the system with the given
ID.

=over

=item Param C<id>

ID of the system whose clients shall be returned.

=item Return Value

An array of client-IDs.

=back

=item C<fetchClientIDsOfGroup($id)>

Fetches the IDs of all clients that are part of the group with the given
ID.

=over

=item Param C<id>

ID of the group whose clients shall be returned.

=item Return Value

An array of client-IDs.

=back



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



=item C<fetchGroupIDsOfClient($id)>

Fetches the IDs of all groups that contain the client with the given
ID.

=over

=item Param C<id>

ID of the client whose groups shall be returned.

=item Return Value

An array of client-IDs.

=back



=item C<fetchGroupIDsOfSystem($id)>

Fetches the IDs of all groups that contain the system with the given
ID.

=over

=item Param C<id>

ID of the system whose groups shall be returned.

=item Return Value

An array of client-IDs.

=back



=item C<fetchSettings()>

Fetches all entries of the settings table, where a single row holds the info
about all system wide configuration parameters.

=over

=item Return Value

A hash containing all column values of the single row that lives
int the settings table.

=back


=head2 Data Manipulation Methods

The following methods need to be implemented in a MetaDB driver in order to
allow the user to access change the underlying:



=item C<addVendorOS(@$valRows)>

Adds one or more vendor-OS to the database.

=over

=item Param C<valRows>

An array-ref containing hash-refs with the data of the new vendor-OS(es).

=item Return Value

The IDs of the new vendor-OS(es), C<undef> if the creation failed.

=back



=item C<removeVendorOS(@$vendorOSIDs)>

Removes one or more vendor-OS from the database.

=over

=item Param C<vendorOSIDs>

An array-ref containing the IDs of the vendor-OSes that shall be removed.

=item Return Value

C<1> if the vendorOS(es) could be removed, C<undef> if not.

=back



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



=item C<addExport(@$valRows)>

Adds one or more export to the database.

=over

=item Param C<valRows>

An array-ref containing hash-refs with the data of the new export(s).

=item Return Value

The IDs of the new export(s), C<undef> if the creation failed.

=back



=item C<removeExport(@$exportIDs)>

Removes one or more export from the database.

=over

=item Param C<exportIDs>

An array-ref containing the IDs of the exports that shall be removed.

=item Return Value

C<1> if the export(s) could be removed, C<undef> if not.

=back



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



=item C<addSystem(@$valRows)>

Adds one or more systems to the database.

=over

=item Param C<valRows>

An array-ref containing hash-refs with the data of the new system(s).

=item Return Value

The IDs of the new system(s), C<undef> if the creation failed.

=back



=item C<removeSystem(@$systemIDs)>

Removes one or more systems from the database.

=over

=item Param C<systemIDs>

An array-ref containing the IDs of the systems that shall be removed.

=item Return Value

C<1> if the system(s) could be removed, C<undef> if not.

=back



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



=item C<setGroupIDsOfSystem($systemID, @$groupIDs)>

Specifies all groups that should offer the given system for booting.

=over

=item Param C<systemID>

The ID of the system whose groups you'd like to specify.

=item Param C<clientIDs>

An array-ref containing the IDs of the groups that shall be connected to the
system.

=item Return Value

C<1> if the system/group references could be set, C<undef> if not.

=back



=item C<addClient(@$valRows)>

Adds one or more clients to the database.

=over

=item Param C<valRows>

An array-ref containing hash-refs with the data of the new client(s).

=item Return Value

The IDs of the new client(s), C<undef> if the creation failed.

=back



=item C<removeClient(@$clientIDs)>

Removes one or more clients from the database.

=over

=item Param C<clientIDs>

An array-ref containing the IDs of the clients that shall be removed.

=item Return Value

C<1> if the client(s) could be removed, C<undef> if not.

=back



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



=item C<setSystemIDsOfClient($clientID, @$clientIDs)>

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



=item C<addGroup(@$valRows)>

Adds one or more groups to the database.

=over

=item Param C<valRows>

An array-ref containing hash-refs with the data of the new group(s).

=item Return Value

The IDs of the new group(s), C<undef> if the creation failed.

=back



=item C<removeGroup(@$groupIDs)>

Removes one or more groups from the database.

=over

=item Param C<groupIDs>

An array-ref containing the IDs of the groups that shall be removed.

=item Return Value

C<1> if the group(s) could be removed, C<undef> if not.

=back



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



=item C<setSystemIDsOfGroup($groupID, @$groupIDs)>

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



=item C<changeSettings(%$settings)>

Changes one or more of the system-wide setting parameters.

=over

=item Param C<settings>

A hash-ref containing the column-names you'd like to change with their new
values.

=item Return Value

C<1> if the settings could be changed, C<undef> if not.

=back






=head2 Schema Related Methods

The following methods need to be implemented in a MetaDB driver in order to
be able to automatically adjust to new database schema versions (by adding
and/or removing tables and table-columns).

=cut
