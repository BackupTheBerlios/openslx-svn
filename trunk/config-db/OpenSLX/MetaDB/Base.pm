# Base.pm - provides empty base of the OpenSLX MetaDB API.
#
# (c) 2006 - OpenSLX.com
#
# Oliver Tappe <ot@openslx.com>
#
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

sub connectConfigDB
{
}

sub disconnectConfigDB
{
}

sub quote
{
}

################################################################################
### data access interface
################################################################################
sub fetchVendorOSesByFilter
{
}

sub fetchVendorOSesByID
{
}

sub fetchSystemsByFilter
{
}

sub fetchSystemsByID
{
}

sub fetchSystemIDsOfVendorOS
{
}

sub fetchSystemIDsOfClient
{
}

sub fetchSystemIDsOfGroup
{
}

sub fetchSystemVariantsByFilter
{
}

sub fetchSystemVariantsByID
{
}

sub fetchSystemVariantIDsOfSystem
{
}

sub fetchClientsByFilter
{
}

sub fetchClientsByID
{
}

sub fetchClientIDsOfSystem
{
}

sub fetchClientIDsOfGroup
{
}

sub fetchGroupsByFilter
{
}

sub fetchGroupsByID
{
}

sub fetchGroupIDsOfClient
{
}

sub fetchGroupIDsOfSystem
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

sub addSystem
{
}

sub removeSystem
{
}

sub changeSystem
{
}

sub addSystemVariant
{
}

sub removeSystemVariant
{
}

sub changeSystemVariant
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

=item C<fetchVendorOSesByFilter([%$filter], [$resultCols])>

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

=item C<fetchVendorOSesByID(@$ids, [$resultCols])>

Fetches and returns information the vendor-OSes with the given IDs.

=over

=item Param C<ids>

An array of the vendor-OS-IDs you are interested in.

=item Param C<resultCols>

A string listing the columns that shall be returned - default is all columns.

=item Return Value

An array of hash-refs containing the resulting data rows.

=back

=item C<fetchSystemsByFilter([%$filter], [$resultCols])>

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

=item C<fetchSystemsByID(@$ids, [$resultCols])>

Fetches and returns information the systems with the given IDs.

=over

=item Param C<ids>

An array of the system-IDs you are interested in.

=item Param C<resultCols>

A string listing the columns that shall be returned - default is all columns.

=item Return Value

An array of hash-refs containing the resulting data rows.

=back

=item C<fetchSystemIDsOfVendorOS($id)>

Fetches the IDs of all systems that make use of the vendor-OS with the given ID.

=over

=item Param C<id>

ID of the vendor-OS whose systems shall be returned.

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

=item C<fetchSystemVariantsByFilter([%$filter], [$resultCols])>

Fetches and returns information about all system variants that match the given
filter.

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

=item C<fetchSystemVariantsByID(@$ids, [$resultCols])>

Fetches and returns information the systems variants with the given IDs.

=over

=item Param C<ids>

An array of the system-variant-IDs you are interested in.

=item Param C<resultCols>

A string listing the columns that shall be returned - default is all columns.

=item Return Value

An array of hash-refs containing the resulting data rows.

=back

=item C<fetchSystemVariantIDsOfSystem($id)>

Fetches the IDs of all system variants that belong to the system with the given
ID.

=over

=item Param C<id>

ID of the system whose variants shall be returned.

=item Return Value

An array of system-variant-IDs.

=back

=item C<fetchClientsByFilter([%$filter], [$resultCols])>

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

=item C<fetchClientsByID(@$ids, [$resultCols])>

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



=item C<fetchGroupsByFilter([%$filter], [$resultCols])>

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



=item C<fetchGroupsByID(@$ids, [$resultCols])>

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

=cut
