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
# SQLite.pm
#	- provides SQLite-specific overrides of the OpenSLX MetaDB API.
# -----------------------------------------------------------------------------
package OpenSLX::MetaDB::SQLite;

use strict;
use warnings;

use base qw(OpenSLX::MetaDB::DBI);

################################################################################
### This class provides a MetaDB backend for SQLite databases.
### - by default the db will be created inside a 'openslxdata-sqlite' directory.
################################################################################
use DBD::SQLite;
use OpenSLX::Basics;

################################################################################
### implementation
################################################################################
sub new
{
	my $class = shift;
	my $self  = {};
	return bless $self, $class;
}

sub connect		## no critic (ProhibitBuiltinHomonyms)
{
	my $self = shift;

	my $dbSpec = $openslxConfig{'db-spec'};
	if (!defined $dbSpec) {
		# build $dbSpec from individual parameters:
		my $dbBasepath = "$openslxConfig{'private-path'}/db";
		my $dbDatadir  = 'sqlite';
		my $dbPath     = "$dbBasepath/$dbDatadir";
		system("mkdir -p $dbPath") unless -e $dbPath;
		$dbSpec = "dbname=$dbPath/$openslxConfig{'db-name'}";
	}
	vlog(1, "trying to connect to SQLite-database <$dbSpec>");
	$self->{'dbh'} =
	  DBI->connect("dbi:SQLite:$dbSpec", undef, undef,
		{PrintError => 0, AutoCommit => 1})
	  or die _tr("Cannot connect to database <%s> (%s)", $dbSpec, $DBI::errstr);
	return 1;
}

sub schemaRenameTable
{
	my $self      = shift;
	my $oldTable  = shift;
	my $newTable  = shift;
	my $colDescrs = shift;
	my $isSubCmd  = shift;

	my $dbh = $self->{'dbh'};
	vlog(1, "renaming table <$oldTable> to <$newTable>...") unless $isSubCmd;
	my $sql = "ALTER TABLE $oldTable RENAME TO $newTable";
	vlog(3, $sql);
	$dbh->do($sql)
	  or croak(_tr(q[Can't rename table <%s> (%s)], $oldTable, $dbh->errstr));
	return;
}

sub schemaAddColumns
{
	my $self              = shift;
	my $table             = shift;
	my $newColDescrs      = shift;
	my $newColDefaultVals = shift;
	my $colDescrs         = shift;
	my $isSubCmd          = shift;

	my $dbh         = $self->{'dbh'};
	my $newColNames = $self->_convertColDescrsToColNamesString($newColDescrs);
	vlog(1, "adding columns <$newColNames> to table <$table>")
	  unless $isSubCmd;    
	foreach my $colDescr (@$newColDescrs) {
		my $colDescrString =
		  $self->_convertColDescrsToDBNativeString([$colDescr]);
		my $sql = "ALTER TABLE $table ADD COLUMN $colDescrString";
		vlog(3, $sql);
		$dbh->do($sql)
		  or croak(_tr(q[Can't add column to table <%s> (%s)], $table,
			$dbh->errstr));
	}
	# if default values have been provided, we apply them now:
	if (defined $newColDefaultVals) {
		$self->_doUpdate($table, undef, $newColDefaultVals);
	}
	return;
}

1;
