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
# mysql.pm
#	- provides mysql-specific overrides of the OpenSLX MetaDB API.
# -----------------------------------------------------------------------------
package OpenSLX::MetaDB::mysql;

use strict;
use vars qw($VERSION);
$VERSION = 1.01;		# API-version . implementation-version
use base qw(OpenSLX::MetaDB::DBI);

################################################################################
### This class provides a MetaDB backend for mysql databases.
### - by default the db will be created inside a 'openslxdata-mysql' directory.
################################################################################
use strict;
use Carp;
use DBD::mysql;
use OpenSLX::Basics;
use OpenSLX::MetaDB::DBI 1;

################################################################################
### implementation
################################################################################
sub new
{
	my $class = shift;
	my $self = {};
	return bless $self, $class;
}

sub connect
{
	my $self = shift;

	my $dbSpec = $openslxConfig{'db-spec'};
	if (!defined $dbSpec) {
		# build $dbSpec from individual parameters:
		$dbSpec = "database=$openslxConfig{'db-name'}";
	}
	my $user = (getpwuid($>))[0];
	vlog 1, "trying to connect user <$user> to mysql-database <$dbSpec>";
	$self->{'dbh'} = DBI->connect("dbi:mysql:$dbSpec", $user, '',
								  {PrintError => 0})
			or confess _tr("Cannot connect to database <%s> (%s)",
						   $dbSpec, $DBI::errstr);
}

sub schemaConvertTypeDescrToNative
{
	my $self = shift;
	my $typeDescr = lc(shift);

	if ($typeDescr eq 'b') {
		return 'integer';
	} elsif ($typeDescr eq 'i') {
		return 'integer';
	} elsif ($typeDescr eq 'pk') {
		return 'integer AUTO_INCREMENT primary key';
	} elsif ($typeDescr eq 'fk') {
		return 'integer';
	} elsif ($typeDescr =~ m[^s\.(\d+)$]i) {
		return "varchar($1)";
	} else {
		confess _tr('UnknownDbSchemaTypeDescr', $typeDescr);
	}
}

sub schemaRenameTable
{
	my $self = shift;
	my $oldTable = shift;
	my $newTable = shift;
	my $colDescrs = shift;
	my $isSubCmd = shift;

	my $dbh = $self->{'dbh'};
	vlog 1, "renaming table <$oldTable> to <$newTable>..." unless $isSubCmd;
	my $sql = "ALTER TABLE $oldTable RENAME TO $newTable";
	vlog 3, $sql;
	$dbh->do($sql)
		or confess _tr(q[Can't rename table <%s> (%s)], $oldTable, $dbh->errstr);
}

sub schemaAddColumns
{
	my $self = shift;
	my $table = shift;
	my $newColDescrs = shift;
	my $newColDefaultVals = shift;
	my $colDescrs = shift;
	my $isSubCmd = shift;

	my $dbh = $self->{'dbh'};
	my $newColNames = $self->_convertColDescrsToColNamesString($newColDescrs);
	vlog 1, "adding columns <$newColNames> to table <$table>" unless $isSubCmd;
	my $addClause
		=	join ', ',
		  	map {
				"ADD COLUMN "
				.$self->_convertColDescrsToDBNativeString([$_]);
			}
			@$newColDescrs;
	my $sql = "ALTER TABLE $table $addClause";
	vlog 3, $sql;
	$dbh->do($sql)
		or confess _tr(q[Can't add columns to table <%s> (%s)], $table,
					   $dbh->errstr);
	# if default values have been provided, we apply them now:
	if (defined $newColDefaultVals) {
		$self->_doUpdate($table, undef, $newColDefaultVals);
	}
}

sub schemaDropColumns
{
	my $self = shift;
	my $table = shift;
	my $dropColNames = shift;
	my $colDescrs = shift;
	my $isSubCmd = shift;

	my $dbh = $self->{'dbh'};
	my $dropColStr = join ', ', @$dropColNames;
	vlog 1, "dropping columns <$dropColStr> from table <$table>..."
			unless $isSubCmd;
	my $dropClause = join ', ', map { "DROP COLUMN $_" } @$dropColNames;
	my $sql = "ALTER TABLE $table $dropClause";
	vlog 3, $sql;
	$dbh->do($sql)
		or confess _tr(q[Can't drop columns from table <%s> (%s)], $table,
					   $dbh->errstr);
}

sub schemaChangeColumns
{
	my $self = shift;
	my $table = shift;
	my $colChanges = shift;
	my $colDescrs = shift;
	my $isSubCmd = shift;

	my $dbh = $self->{'dbh'};
	my $changeColStr = join ', ', keys %$colChanges;
	vlog 1, "changing columns <$changeColStr> in table <$table>..."
			unless $isSubCmd;
	my $changeClause
		=	join ', ',
		  	map {
				"CHANGE COLUMN $_ "
				.$self->_convertColDescrsToDBNativeString([$colChanges->{$_}]);
			}
			keys %$colChanges;
	my $sql = "ALTER TABLE $table $changeClause";
	vlog 3, $sql;
	$dbh->do($sql)
		or confess _tr(q[Can't change columns in table <%s> (%s)], $table,
					   $dbh->errstr);
}
1;