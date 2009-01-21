package ODLX::MetaDB::DBI;

use vars qw(@ISA $VERSION);
@ISA = ('ODLX::MetaDB::Base');
$VERSION = 1.01;		# API-version . implementation-version

################################################################################
### This class is the base for all DBI-related metaDB variants.
### It provides a default implementation for every method, such that
### each DB-specific implementation needs to override only the methods
### that require a different implementation than the one provided here.
################################################################################

use strict;
use Carp;
use DBI;
use ODLX::Basics;
use ODLX::MetaDB::Base;

my $superVersion = $ODLX::MetaDB::Base::VERSION;
if ($superVersion < $VERSION) {
	confess _tr('Unable to load module <%s> (Version <%s> required, but <%s> found)',
				'ODLX::MetaDB::Base', $VERSION, $superVersion);
}

################################################################################
### basics
################################################################################
sub new
{
	confess "Don't call ODLX::MetaDB::DBI::new directly!";
}

sub disconnectConfigDB
{
	my $self = shift;

	$self->{'dbh'}->disconnect;
	$self->{'dbh'} = undef;
}

sub quote
{	# default implementation quotes any given values through the DBD-driver
	my $self = shift;

	return $self->{'dbh'}->quote(@_);
}

################################################################################
### data access functions
################################################################################
sub _doSelect
{
	my $self = shift;
	my $sql = shift;
	my $resultCol = shift;

	my $dbh = $self->{'dbh'};

	my $sth = $dbh->prepare($sql)
		or confess _tr(q[Can't prepare SQL-statement <%s> (%s)], $sql,
					   $dbh->errstr);
	$sth->execute()
		or confess _tr(q[Can't execute SQL-statement <%s> (%s)], $sql,
					   $dbh->errstr);
	my (@vals, $row);
	while($row = $sth->fetchrow_hashref()) {
		if (defined $resultCol) {
			return $row->{$resultCol} unless wantarray();
			push @vals, $row->{$resultCol};
		} else {
			return $row unless wantarray();
			push @vals, $row;
		}
	}
	return @vals;
}

sub fetchSystemsByFilter
{
	my $self = shift;
	my $filter = shift;
	my $resultCols = shift;

	$resultCols = '*' unless (defined $resultCols);
	my $sql = "SELECT $resultCols FROM system";
	my $connector;
	foreach my $col (keys %$filter) {
		$connector = !defined $connector ? 'WHERE' : 'AND';
		$sql .= " $connector $col = '$filter->{$col}'";
	}
	my @rows = $self->_doSelect($sql);
	return @rows;
}

sub fetchSystemsById
{
	my $self = shift;
	my $id = shift;
	my $resultCols = shift;

	return $self->fetchSystemsByFilter({'id' => $id}, $resultCols);
}

sub fetchAllSystemIDsOfClient
{
	my $self = shift;
	my $clientID = shift;

	my $sql = qq[
		SELECT system_id FROM client_system_ref WHERE client_id = '$clientID'
	];
	my @rows = $self->_doSelect($sql, 'system_id');
	return @rows;
}

sub fetchClientsByFilter
{
	my $self = shift;
	my $filter = shift;
	my $resultCols = shift;

	$resultCols = '*' 		unless (defined $resultCols);
	my $sql = "SELECT $resultCols FROM client";
	my $connector;
	foreach my $col (keys %$filter) {
		$connector = !defined $connector ? 'WHERE' : 'AND';
		$sql .= " $connector $col = '$filter->{$col}'";
	}
	my @rows = $self->_doSelect($sql);
	return @rows;
}

sub fetchClientsById
{
	my $self = shift;
	my $id = shift;
	my $resultCols = shift;

	return $self->fetchClientsByFilter({'id' => $id}, $resultCols);
}

sub fetchAllClientIDsOfSystem
{
	my $self = shift;
	my $clientID = shift;

	my $sql = qq[
		SELECT client_id FROM client_system_ref WHERE system_id = '$clientID'
	];
	my @rows = $self->_doSelect($sql, 'system_id');
	return @rows;
}

################################################################################
### data manipulation functions
################################################################################
sub _doInsert
{
	my $self = shift;
	my $table = shift;
	my $valRows = shift;
	my $ignoreIDs = shift;

	my $dbh = $self->{'dbh'};
	my $valRow = (@$valRows)[0];
	return if !defined $valRow;

	if ($table =~ m[_ref$]) {
		# reference tables do not have IDs:
		$ignoreIDs = 1;
	}

	my $needToGenerateIDs = $self->generateNextIdForTable(undef);
	if (!$ignoreIDs && $needToGenerateIDs) {
		# DB requires pre-specified IDs, so we add the 'id' column:
		$valRow->{id} = undef unless exists $valRow->{id};
	}
	my @ids;
	foreach my $valRow (@$valRows) {
		my $cols = join ', ', keys %$valRow;
		my $values = join ', ', map { $self->quote($valRow->{$_}) } keys %$valRow;
		my $sql = "INSERT INTO $table ( $cols ) VALUES ( $values )";
		my $sth = $dbh->prepare($sql)
			or confess _tr(q[Can't insert into table <%s> (%s)], $table,
						$dbh->errstr);
		if (!defined $valRow->{id} && !$ignoreIDs && $needToGenerateIDs) {
			# let DB-backend pre-specify ID, as current DB can't generate IDs:
			$valRow->{id} = $self->generateNextIdForTable($table);
			vlog 3, "generated id for <$table> is <$valRow->{id}>";
		}
		vlog 3, $sql;
		$sth->execute()
			or confess _tr(q[Can't insert into table <%s> (%s)], $table,
						   $dbh->errstr);
		if (!$ignoreIDs && !defined $valRow->{id}) {
			# id has not been pre-specified, we need to fetch it from DB:
			$valRow->{'id'} = $dbh->last_insert_id(undef, undef, $table, 'id');
			vlog 3, "DB-generated id for <$table> is <$valRow->{id}>";
		}
		push @ids, $valRow->{'id'};
	}
	return wantarray() ? @ids : shift @ids;
}

sub _doDelete
{
	my $self = shift;
	my $table = shift;
	my $IDs = shift;
	my $idCol = shift;

	my $dbh = $self->{'dbh'};

	$IDs = [undef] unless defined $IDs;
	$idCol = 'id' unless defined $idCol;
	foreach my $id (@$IDs) {
		my $sql = "DELETE FROM $table";
		if (defined $id) {
			$sql .= " WHERE $idCol = ".$self->quote($id);
		}
		my $sth = $dbh->prepare($sql)
			or confess _tr(q[Can't delete from table <%s> (%s)], $table,
						$dbh->errstr);
		vlog 3, $sql;
		$sth->execute()
			or confess _tr(q[Can't delete from table <%s> (%s)], $table,
						   $dbh->errstr);
	}
	return 1;
}

sub _doUpdate
{
	my $self = shift;
	my $table = shift;
	my $IDs = shift;
	my $valRows = shift;

	my $dbh = $self->{'dbh'};
	my $valRow = (@$valRows)[0];
	return if !defined $valRow;

	my $idx = 0;
	foreach my $valRow (@$valRows) {
		my $id = $IDs->[$idx++];
		my %valData = %$valRow;
		delete $valData{'id'};
			# filter column 'id' if present, as we don't want to update it
		my $cols =  join ', ',
					map { "$_ = ".$self->quote($valRow->{$_}) }
					grep { $_ ne 'id' }
						# filter column 'id' if present, as we don't want
						# to update it
					keys %$valRow;
		my $sql = "UPDATE $table SET $cols";
		if (defined $id) {
			$sql .= " WHERE id = ".$self->quote($id);
		}
		my $sth = $dbh->prepare($sql)
			or confess _tr(q[Can't update table <%s> (%s)], $table, $dbh->errstr);
		vlog 3, $sql;
		$sth->execute()
			or confess _tr(q[Can't update table <%s> (%s)], $table,
						   $dbh->errstr);
	}
	return 1;
}

sub _updateRefTable
{
	my $self = shift;
	my $table = shift;
	my $keyID = shift;
	my $newValueIDs = shift;
	my $keyCol = shift;
	my $valueCol = shift;
	my $oldValueIDs = shift;

	my %lastValueIDs;
	@lastValueIDs{@$oldValueIDs} = ();

	foreach my $valueID (@$newValueIDs) {
		if (!exists $lastValueIDs{$valueID}) {
			# value-ID is new, create it
			my $valRow = {
				$keyCol => $keyID,
				$valueCol => $valueID,
			};
			$self->_doInsert($table, [$valRow]);
		} else {
			# value-ID already exists, leave as is, but remove from hash:
			delete $lastValueIDs{$valueID};
		}
	}

	# all the remaining value-IDs need to be removed:
	if (scalar keys %lastValueIDs) {
		$self->_doDelete($table, keys %lastValueIDs, $valueCol);
	}
}

sub addSystem
{
	my $self = shift;
	my $valRows = shift;

	return $self->_doInsert('system', $valRows);
}

sub removeSystem
{
	my $self = shift;
	my $systemIDs = shift;

	return $self->_doDelete('system', $systemIDs);
}

sub changeSystem
{
	my $self = shift;
	my $systemIDs = shift;
	my $valRows = shift;

	return $self->_doUpdate('system', $systemIDs, $valRows);
}

sub setClientIDsOfSystem
{
	my $self = shift;
	my $systemID = shift;
	my $clientIDs = shift;

	my @currClients = $self->fetchAllClientIDsOfSystem($systemID);
	$self->_updateRefTable('client_system_ref', $systemID, $clientIDs,
						   'system_id', 'client_id', \@currClients);
}

sub setGroupIDsOfSystem
{
	my $self = shift;
	my $systemID = shift;
	my $groupIDs = shift;

	my @currGroups = $self->fetchAllGroupIDsOfSystem($systemID);
	$self->_updateRefTable('grop_system_ref', $systemID, $groupIDs,
						   'system_id', 'group_id', \@currGroups);
}

sub addClient
{
	my $self = shift;
	my $valRows = shift;

	return $self->_doInsert('client', $valRows);
}

sub removeClient
{
	my $self = shift;
	my $clientIDs = shift;

	return $self->_doDelete('client', $clientIDs);
}

sub changeClient
{
	my $self = shift;
	my $clientIDs = shift;
	my $valRows = shift;

	return $self->_doUpdate('client', $clientIDs, $valRows);
}

sub setSystemIDsOfClient
{
	my $self = shift;
	my $clientID = shift;
	my $systemIDs = shift;

	my @currSystems = $self->fetchAllSystemsOfClient($clientID);
	$self->_updateRefTable('client_system_ref', $clientID, $systemIDs,
						   'client_id', 'system_id', \@currSystems);
}

sub setGroupIDsOfClient
{
	my $self = shift;
	my $clientID = shift;
	my $groupIDs = shift;

	my @currGroups = $self->fetchAllGroupsOfClient($clientID);
	$self->_updateRefTable('group_client_ref', $clientID, $groupIDs,
						   'client_id', 'group_id', \@currGroups);
}

sub addGroup
{
	my $self = shift;
	my $valRows = shift;

	return $self->_doInsert('group', $valRows);
}

sub removeGroup
{
	my $self = shift;
	my $groupIDs = shift;

	return $self->_doDelete('group', $groupIDs);
}

sub changeGroup
{
	my $self = shift;
	my $groupIDs = shift;
	my $valRows = shift;

	return $self->_doUpdate('group', $groupIDs, $valRows);
}

sub setClientIDsOfGroup
{
	my $self = shift;
	my $groupID = shift;
	my $clientIDs = shift;

	my @currClients = $self->fetchAllClientsOfGroup($groupID);
	$self->_updateRefTable('group_client_ref', $groupID, $clientIDs,
						   'group_id', 'client_id', \@currClients);
}

sub setSystemIDsOfGroup
{
	my $self = shift;
	my $groupID = shift;
	my $systemIDs = shift;

	my @currSystems = $self->fetchAllSystemsOfGroup($groupID);
	$self->_updateRefTable('group_system_ref', $groupID, $systemIDs,
						   'group_id', 'system_id', \@currSystems);
}

################################################################################
### schema related functions
################################################################################
sub _convertColDescrsToDBNativeString
{
	my $self = shift;
	my $colDescrs = shift;

	my $colDescrString
		= join ', ',
		  map {
			  # convert each column description into database native format
			  # (e.g. convert 'name:s.45' to 'name char(45)'):
			  if (!m[^\s*(\S+?)\s*:\s*(\S+?)\s*$]) {
				  confess _tr('UnknownDbSchemaColumnDescr', $_);
			  }
			  "$1 ".$self->schemaConvertTypeDescrToNative($2);
		  }
		  @$colDescrs;
	return $colDescrString;
}

sub _convertColDescrsToColNames
{
	my $self = shift;
	my $colDescrs = shift;

	return
		map {
			# convert each column description into database native format
			# (e.g. convert 'name:s.45' to 'name char(45)'):
			if (!m[^\s*(\S+?)\s*:.+$]) {
				confess _tr('UnknownDbSchemaColumnDescr', $_);
			}
			$1;
		}
		@$colDescrs;
}

sub _convertColDescrsToColNamesString
{
	my $self = shift;
	my $colDescrs = shift;

	return join ', ', $self->_convertColDescrsToColNames($colDescrs);
}

sub schemaFetchDBVersion
{
	my $self = shift;

	my $dbh = $self->{'dbh'};
	local $dbh->{RaiseError} = 1;
	my $row = eval {
		$dbh->selectrow_hashref('SELECT schema_version FROM meta');
	};
	return 0 if $@;
		# no database access possible
	return undef unless defined $row;
		# no entry in meta-table
	return $row->{schema_version};
}

sub schemaConvertTypeDescrToNative
{	# a default implementation, many DBs need to override...
	my $self = shift;
	my $typeDescr = lc(shift);

	if ($typeDescr eq 'b') {
		return 'integer';
	} elsif ($typeDescr eq 'i') {
		return 'integer';
	} elsif ($typeDescr eq 'pk') {
		return 'integer primary key';
	} elsif ($typeDescr eq 'fk') {
		return 'integer';
	} elsif ($typeDescr =~ m[^s\.(\d+)$]i) {
		return "varchar($1)";
	} else {
		confess _tr('UnknownDbSchemaTypeDescr', $typeDescr);
	}
}

sub schemaAddTable
{
	my $self = shift;
	my $table = shift;
	my $colDescrs = shift;
	my $initialVals = shift;
	my $isSubCmd = shift;

	my $dbh = $self->{'dbh'};
	vlog 1, "adding table <$table> to schema..." unless $isSubCmd;
	my $colDescrString = $self->_convertColDescrsToDBNativeString($colDescrs);
	my $sql = "CREATE TABLE $table ($colDescrString)";
	vlog 3, $sql;
	$dbh->do($sql)
		or confess _tr(q[Can't create table <%s> (%s)], $table, $dbh->errstr);
	if (defined $initialVals) {
		my $ignoreIDs = ($colDescrString !~ m[\bid\b]);
			# don't care about IDs if there's no 'id' column in this table
		$self->_doInsert($table, $initialVals, $ignoreIDs);
	}
}

sub schemaDropTable
{
	my $self = shift;
	my $table = shift;
	my $isSubCmd = shift;

	my $dbh = $self->{'dbh'};
	vlog 1, "dropping table <$table> from schema..." unless $isSubCmd;
	my $sql = "DROP TABLE $table";
	vlog 3, $sql;
	$dbh->do($sql)
		or confess _tr(q[Can't drop table <%s> (%s)], $table, $dbh->errstr);
}

sub schemaRenameTable
{	# a rather simple-minded implementation that renames a table in several
	# steps:
	# 	- create the new table
	# 	- copy the data over from the old one
	# 	- drop the old table
	# This should be overriden for advanced DBs, as these more often than not
	# implement the 'ALTER TABLE <old> RENAME TO <new>' SQL-command (which
	# is much more efficient).
	my $self = shift;
	my $oldTable = shift;
	my $newTable = shift;
	my $colDescrs = shift;
	my $isSubCmd = shift;

	my $dbh = $self->{'dbh'};
	vlog 1, "renaming table <$oldTable> to <$newTable>..." unless $isSubCmd;
	my $colDescrString = $self->_convertColDescrsToDBNativeString($colDescrs);
	my $sql = "CREATE TABLE $newTable ($colDescrString)";
	vlog 3, $sql;
	$dbh->do($sql)
		or confess _tr(q[Can't create table <%s> (%s)], $oldTable, $dbh->errstr);
	my $colNamesString = $self->_convertColDescrsToColNamesString($colDescrs);
	my @dataRows = $self->_doSelect("SELECT $colNamesString FROM $oldTable");
	$self->_doInsert($newTable, \@dataRows);
	$sql = "DROP TABLE $oldTable";
	vlog 3, $sql;
	$dbh->do($sql)
		or confess _tr(q[Can't drop table <%s> (%s)], $oldTable, $dbh->errstr);
}

sub schemaAddColumns
{	# a rather simple-minded implementation that adds columns to a table
	# in several steps:
	# 	- create a temp table with the new layout
	# 	- copy the data from the old table into the new one
	# 	- drop the old table
	# 	- rename the temp table to the original name
	# This should be overriden for advanced DBs, as these more often than not
	# implement the 'ALTER TABLE <old> RENAME TO <new>' SQL-command (which
	# is much more efficient).
	my $self = shift;
	my $table = shift;
	my $newColDescrs = shift;
	my $newColDefaultVals = shift;
	my $colDescrs = shift;
	my $isSubCmd = shift;

	my $dbh = $self->{'dbh'};
	my $tempTable = "${table}_temp";
	my @colNames = $self->_convertColDescrsToColNames($colDescrs);
	my @newColNames = $self->_convertColDescrsToColNames($newColDescrs);
	my $newColStr = join ', ', @newColNames;
	vlog 1, "adding columns <$newColStr> to table <$table>..." unless $isSubCmd;
	$self->schemaAddTable($tempTable, $colDescrs, undef, 1);

	# copy the data from the old table to the new:
	my @dataRows = $self->_doSelect("SELECT * FROM $table");
	$self->_doInsert($tempTable, \@dataRows);
		# N.B.: for the insert, we rely on the caller having added the new
		# columns to the end of the table (if that isn't the case, things
		# break here!)

	if (defined $newColDefaultVals) {
		# default values have been provided, we apply them now:
		$self->_doUpdate($tempTable, undef, $newColDefaultVals);
	}

	$self->schemaDropTable($table, 1);
	$self->schemaRenameTable($tempTable, $table, $colDescrs, 1);
}

sub schemaDropColumns
{	# a rather simple-minded implementation that drops columns from a table
	# in several steps:
	# 	- create a temp table with the new layout
	# 	- copy the data from the old table into the new one
	# 	- drop the old table
	# 	- rename the temp table to the original name
	# This should be overriden for advanced DBs, as these sometimes
	# implement the 'ALTER TABLE <old> DROP COLUMN <col>' SQL-command (which
	# is much more efficient).
	my $self = shift;
	my $table = shift;
	my $dropColNames = shift;
	my $colDescrs = shift;
	my $isSubCmd = shift;

	my $dbh = $self->{'dbh'};
	my $tempTable = "${table}_temp";
	my $dropColStr = join ', ', @$dropColNames;
	vlog 1, "dropping columns <$dropColStr> from table <$table>..."
			unless $isSubCmd;
	$self->schemaAddTable($tempTable, $colDescrs, undef, 1);

	# copy the data from the old table to the new:
	my $colNamesString = $self->_convertColDescrsToColNamesString($colDescrs);
	my @dataRows = $self->_doSelect("SELECT $colNamesString FROM $table");
	$self->_doInsert($tempTable, \@dataRows);

	$self->schemaDropTable($table, 1);
	$self->schemaRenameTable($tempTable, $table, $colDescrs, 1);
}

sub schemaChangeColumns
{	# a rather simple-minded implementation that changes columns
	# in several steps:
	# 	- create a temp table with the new layout
	# 	- copy the data from the old table into the new one
	# 	- drop the old table
	# 	- rename the temp table to the original name
	# This should be overriden for advanced DBs, as these sometimes
	# implement the 'ALTER TABLE <old> CHANGE COLUMN <col>' SQL-command (which
	# is much more efficient).
	my $self = shift;
	my $table = shift;
	my $colChanges = shift;
	my $colDescrs = shift;
	my $isSubCmd = shift;

	my $dbh = $self->{'dbh'};
	my $tempTable = "${table}_temp";
	my $changeColStr = join ', ', keys %$colChanges;
	vlog 1, "changing columns <$changeColStr> of table <$table>..."
			unless $isSubCmd;
	$self->schemaAddTable($tempTable, $colDescrs, undef, 1);

	# copy the data from the old table to the new:
	my $colNamesString = $self->_convertColDescrsToColNamesString($colDescrs);
	my @dataRows = $self->_doSelect("SELECT * FROM $table");
	foreach my $oldCol (keys %$colChanges) {
		my $newCol
			= $self->_convertColDescrsToColNamesString([$colChanges->{$oldCol}]);
		# rename current column in all data-rows:
		foreach my $row (@dataRows) {
			$row->{$newCol} = $row->{$oldCol};
			delete $row->{$oldCol};
		}
	}
	$self->_doInsert($tempTable, \@dataRows);

	$self->schemaDropTable($table, 1);
	$self->schemaRenameTable($tempTable, $table, $colDescrs, 1);
}

1;