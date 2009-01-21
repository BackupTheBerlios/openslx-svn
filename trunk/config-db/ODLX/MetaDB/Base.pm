################################################################################
# ODLX::MetaDB:Base - the base class for all MetaDB drivers
#
# Copyright 2006 by Oliver Tappe - all rights reserved.
#
# You may distribute this module under the terms of the GNU GPL v2.
################################################################################

package ODLX::MetaDB::Base;

use vars qw($VERSION);
$VERSION = 1.01;		# API-version . implementation-version

################################################################################
=pod

=head1 NAME

ODLX::MetaDB::Base - the base class for all MetaDB drivers

=head1 SYNOPSIS

  package ODLX::MetaDB::coolnewDB;

  use vars qw(@ISA $VERSION);
  @ISA = ('ODLX::MetaDB::Base');
  $VERSION = 1.01;

  my $superVersion = $ODLX::MetaDB::Base::VERSION;
  if ($superVersion < $VERSION) {
      confess _tr('Unable to load module <%s> (Version <%s> required)',
                  'ODLX::MetaDB::Base', $VERSION);
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

      my $dbName = $odlxConfig{'db-name'};
      vlog 1, "trying to connect to coolnewDB-database <$dbName>";
      $self->{'dbh'} = ... # get connection handle from coolnewDB
  }

  sub disconnectConfigDB
  {
      my $self = shift;

      $self->{'dbh'}->disconnect;
  }

  # override all methods of ODLX::MetaDB::Base in order to implement
  # a full MetaDB driver
  ...

I<The synopsis above outlines a class that implements a
MetaDB driver for the (imaginary) database B<coolnewDB>>

=head1 DESCRIPTION

This class defines the MetaDB interface for the ODLX.

Aim of the MetaDB abstraction is to make it possible to use a large set
of different databases (from CSV-files to a fullblown Oracle-installation)
transparently.

While ODLX::ConfigDB represents the data layer to the outside world, each
implementation of ODLX::MetaDB::Base provides a backend for a specific database.

This way, the different ODLX-scripts do not have to burden
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
to inherit from B<ODLX::MetaDB::Base> and implement the full interface. As this
is quite some work, it might be wiser to actually inherit your driver from
B<L<ODLX::MetaDB::DBI|ODLX::MetaDB::DBI>>, which is a default implementation for SQL databases.

If there is a DBD-driver for the database your new MetaDB driver wants to talk
to then all you need to do is inherit from B<ODLX::MetaDB::DBI> and then
reimplement L<C<connectConfigDB>> (and maybe some other methods in order to
improve efficiency).

=cut

################################################################################
use strict;
use Carp;

################################################################################

=head2 Basic Methods

The following basic methods need to be implemented in a MetaDB driver:

=over

=cut

################################################################################
sub new
{
	confess "Don't create ODLX::MetaDB::Base - objects directly!";
}

=item C<connectConfigDB>

  $metaDB->connectConfigDB($dbParams);

Tries to establish a connection to the DBMS that this MetaDB driver deals with.
The global configuration hash C<%config> contains further info about the
requested connection. When implementing this method, you may have to look at
the following entries in order to find out which database to connect to:

=over

=item C<$config{'db-basepath'}>

basic path to odlx database, defaults to path of running script

=item C<$config{'db-datadir'}>

data folder created under db-basepath, default depends on db-type (many
DBMSs don't have such a folder, as they do not store the data in the
filesystem).

=item C<$config{'db-spec'}>

full specification of database, a special string defining the
precise database to connect to (this allows connecting to a database
that requires specifications which aren't cared for by the existing
C<%config>-entries).

=item C<$config{'db-name'}>

the precise name of the database that should be connected (defaults to 'odlx').

=back

=cut

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

=back

=head2 Data Access Methods

The following methods need to be implemented in a MetaDB driver in order to
allow the user to access data:

=over

=cut

################################################################################

=item C<fetchSystemsByFilter>

  my $filter = { 'os_type' => 'LINUX' };
  my $resultCols = 'id,name,descr';
  my @systems = $metaDBH->fetchSystemsByFilter($filter, $resultCols);

Fetches and returns information about all systems match the given filter.

=over

=item Param C<$filter>

A hash-ref defining the filter criteria to be applied. Each key corresponds
to a DB column and the (hash-)value contains the respective column value. [At a
later stage, this might be improved to support more structured approach to
filtering (with boolean operators and more)].

=item Param C<$resultCols> [Optional]

A comma-separated list of colunm names that shall be returned. If not defined,
all available data must be returned.

=item Return Value

An array of hash-refs containing the resulting data rows.


=back

=cut

sub fetchVendorOSesByFilter
{
}

sub fetchVendorOSesById
{
}

sub fetchSystemsByFilter
{
}

sub fetchSystemsById
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

sub fetchClientsByFilter
{
}

sub fetchClientsById
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

sub fetchGroupsById
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

sub setSystemIDsOfVendorOS
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

=back

=cut

1;