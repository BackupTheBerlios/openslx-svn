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
# DBI.pm
#	- provides DBI-based implementation of the OpenSLX MetaDB API.
# -----------------------------------------------------------------------------
package OpenSLX::MetaDB::DBI;

use strict;
use warnings;

use base qw(OpenSLX::MetaDB::Base);

use DBI;
use OpenSLX::Basics;

################################################################################
### basics
################################################################################
sub new
{
	confess "Don't call OpenSLX::MetaDB::DBI::new directly!";
}

sub disconnect
{
	my $self = shift;

	$self->{'dbh'}->disconnect;
	$self->{'dbh'} = undef;
	return;
}

sub quote
{    # default implementation quotes any given values through the DBI
	my $self = shift;

	return $self->{'dbh'}->quote(@_);
}

sub startTransaction
{    # default implementation passes on the request to the DBI
	my $self = shift;

	return $self->{'dbh'}->begin_work();
}

sub commitTransaction
{    # default implementation passes on the request to the DBI
	my $self = shift;

	return $self->{'dbh'}->commit();
}

sub rollbackTransaction
{    # default implementation passes on the request to the DBI
	my $self = shift;

	return $self->{'dbh'}->rollback();
}

################################################################################
### data access
################################################################################
sub _trim
{
	my $s = shift;
	$s =~ s[^\s*(.*?)\s*$][$1];
	return $s;
}

sub _buildFilterClause
{
	my $self         = shift;
	my $filter       = shift || {};
	my $filterClause = shift || '';

	my ($connector, $quotedVal);
	foreach my $col (keys %$filter) {
		$connector = !length($filterClause) ? 'WHERE' : 'AND';
		if (defined $filter->{$col}) {
			$quotedVal = $self->{dbh}->quote($filter->{$col});
			$filterClause .= " $connector $col = $quotedVal";
		} else {
			$filterClause .= " $connector $col IS NULL";
		}
	}
	
	return $filterClause || '';
}

sub _buildAttrFilterClause
{
	my $self         = shift;
	my $attrFilter   = shift || {};
	my $table        = shift;
	my $filterClause = shift || '';

	my %tableMap = (
		'client' => 'client',
		'group'  => 'groups',
		'system' => 'system',
	);

	my ($connector, $quotedName, $quotedValue);
	foreach my $name (keys %$attrFilter) {
		$connector = !length($filterClause) ? 'WHERE' : 'AND';
		$quotedName = $self->{dbh}->quote($name);
		if (defined $attrFilter->{$name}) {
			$quotedValue = $self->{dbh}->quote($attrFilter->{$name});
			$filterClause .= <<"			End-of-Here";
				$connector EXISTS (
					SELECT name FROM ${table}_attr
					WHERE name = $quotedName 
					AND value = $quotedValue
					AND ${table}_id = $tableMap{$table}.id
				)
			End-of-Here
		} else {
			$filterClause .= <<"			End-of-Here";
				$connector NOT EXISTS (
					SELECT name FROM ${table}_attr
					WHERE name = $quotedName 
					AND ${table}_id = $tableMap{$table}.id
				)
			End-of-Here
		}
	}

	return $filterClause;
}

sub _doSelect
{
	my $self      = shift;
	my $sql       = shift;
	my $resultCol = shift;

	my $dbh = $self->{'dbh'};

	vlog(3, _trim($sql));
	my $sth = $dbh->prepare($sql)
		or croak _tr(
			q[Can't prepare SQL-statement <%s> (%s)], $sql, $dbh->errstr
		);
	$sth->execute()
		or croak _tr(
			q[Can't execute SQL-statement <%s> (%s)], $sql, $dbh->errstr
		);
	my @vals;
	while (my $row = $sth->fetchrow_hashref()) {
		if (defined $resultCol) {
			return $row->{$resultCol} unless wantarray();
			push @vals, $row->{$resultCol};
		} else {
			return $row unless wantarray();
			push @vals, $row;
		}
	}

	# return undef if there's no result in scalar context
	return if !wantarray();		

	return @vals;
}

sub fetchVendorOSByFilter
{
	my $self       = shift;
	my $filter     = shift;
	my $resultCols = shift;

	$resultCols = '*' unless (defined $resultCols);
	my $filterClause = $self->_buildFilterClause($filter);
	my $sql = "SELECT $resultCols FROM vendor_os $filterClause";
	return $self->_doSelect($sql);
}

sub fetchVendorOSByID
{
	my $self       = shift;
	my $ids        = shift;
	my $resultCols = shift;

	$resultCols = '*' unless (defined $resultCols);
	my $idStr = join ',', @$ids;
	return if !length($idStr);
	my $sql = "SELECT $resultCols FROM vendor_os WHERE id IN ($idStr)";
	return $self->_doSelect($sql);
}

sub fetchExportByFilter
{
	my $self       = shift;
	my $filter     = shift;
	my $resultCols = shift;

	$resultCols = '*' unless (defined $resultCols);
	my $filterClause = $self->_buildFilterClause($filter);
	my $sql = "SELECT $resultCols FROM export $filterClause";
	return $self->_doSelect($sql);
}

sub fetchExportByID
{
	my $self       = shift;
	my $ids        = shift;
	my $resultCols = shift;

	$resultCols = '*' unless (defined $resultCols);
	my $idStr = join ',', @$ids;
	return if !length($idStr);
	my $sql = "SELECT $resultCols FROM export WHERE id IN ($idStr)";
	return $self->_doSelect($sql);
}

sub fetchExportIDsOfVendorOS
{
	my $self       = shift;
	my $vendorOSID = shift;

	my $sql = qq[
		SELECT id FROM export WHERE vendor_os_id = '$vendorOSID'
	];
	return $self->_doSelect($sql, 'id');
}

sub fetchGlobalInfo
{
	my $self = shift;
	my $id   = shift;

	return if !length($id);
	my $sql = "SELECT value FROM global_info WHERE id = " . $self->quote($id);
	return $self->_doSelect($sql, 'value');
}

sub fetchSystemByFilter
{
	my $self       = shift;
	my $filter     = shift;
	my $resultCols = shift;
	my $attrFilter = shift;

	$resultCols = '*' unless (defined $resultCols);
	my $filterClause = $self->_buildFilterClause($filter);
	$filterClause = $self->_buildAttrFilterClause(
		$attrFilter, 'system', $filterClause
	);
	my $sql = <<"	End-of-Here";
		SELECT $resultCols FROM system
		$filterClause
	End-of-Here
	return $self->_doSelect($sql);
}

sub fetchSystemByID
{
	my $self       = shift;
	my $ids        = shift;
	my $resultCols = shift;

	$resultCols = '*' unless (defined $resultCols);
	my $idStr = join ',', @$ids;
	return if !length($idStr);
	my $sql = "SELECT $resultCols FROM system WHERE id IN ($idStr)";
	return $self->_doSelect($sql);
}

sub fetchSystemAttrs
{
	my $self      = shift;
	my $systemID  = $self->{dbh}->quote(shift);

	my $sql = <<"	End-of-Here";
		SELECT name, value FROM system_attr
		WHERE system_id = $systemID
	End-of-Here
	my @attrs = $self->_doSelect($sql);
	my $Result = {};
	foreach my $attr (@attrs) {
		$Result->{$attr->{name}} = $attr->{value};
	}
	return $Result;
}

sub fetchSystemIDsOfExport
{
	my $self     = shift;
	my $exportID = shift;

	my $sql = qq[
		SELECT id FROM system WHERE export_id = '$exportID'
	];
	return $self->_doSelect($sql, 'id');
}

sub fetchSystemIDsOfClient
{
	my $self     = shift;
	my $clientID = shift;

	my $sql = qq[
		SELECT system_id FROM client_system_ref WHERE client_id = '$clientID'
	];
	return $self->_doSelect($sql, 'system_id');
}

sub fetchSystemIDsOfGroup
{
	my $self    = shift;
	my $groupID = shift;

	my $sql = qq[
		SELECT system_id FROM group_system_ref WHERE group_id = '$groupID'
	];
	return $self->_doSelect($sql, 'system_id');
}

sub fetchClientByFilter
{
	my $self       = shift;
	my $filter     = shift;
	my $resultCols = shift;
	my $attrFilter = shift;

	$resultCols = '*' unless (defined $resultCols);
	my $filterClause = $self->_buildFilterClause($filter);
	$filterClause = $self->_buildAttrFilterClause(
		$attrFilter, 'client', $filterClause
	);
	my $sql = <<"	End-of-Here";
		SELECT $resultCols FROM client
		$filterClause
	End-of-Here
	return $self->_doSelect($sql);
}

sub fetchClientByID
{
	my $self       = shift;
	my $ids        = shift;
	my $resultCols = shift;

	$resultCols = '*' unless (defined $resultCols);
	my $idStr = join ',', @$ids;
	return if !length($idStr);
	my $sql = "SELECT $resultCols FROM client WHERE id IN ($idStr)";
	return $self->_doSelect($sql);
}

sub fetchClientAttrs
{
	my $self     = shift;
	my $clientID = $self->{dbh}->quote(shift);

	my $sql = <<"	End-of-Here";
		SELECT name, value FROM client_attr
		WHERE client_id = $clientID
	End-of-Here
	my @attrs = $self->_doSelect($sql);
	my $Result = {};
	foreach my $attr (@attrs) {
		$Result->{$attr->{name}} = $attr->{value};
	}
	return $Result;
}

sub fetchClientIDsOfSystem
{
	my $self     = shift;
	my $systemID = shift;

	my $sql = qq[
		SELECT client_id FROM client_system_ref WHERE system_id = '$systemID'
	];
	return $self->_doSelect($sql, 'client_id');
}

sub fetchClientIDsOfGroup
{
	my $self    = shift;
	my $groupID = shift;

	my $sql = qq[
		SELECT client_id FROM group_client_ref WHERE group_id = '$groupID'
	];
	return $self->_doSelect($sql, 'client_id');
}

sub fetchGroupByFilter
{
	my $self       = shift;
	my $filter     = shift;
	my $resultCols = shift;
	my $attrFilter = shift;

	$resultCols = '*' unless (defined $resultCols);
	my $filterClause = $self->_buildFilterClause($filter);
	$filterClause = $self->_buildAttrFilterClause(
		$attrFilter, 'group', $filterClause
	);
	my $sql = <<"	End-of-Here";
		SELECT $resultCols FROM groups
		$filterClause
	End-of-Here
	return $self->_doSelect($sql);
}

sub fetchGroupByID
{
	my $self       = shift;
	my $ids        = shift;
	my $resultCols = shift;

	$resultCols = '*' unless (defined $resultCols);
	my $idStr = join ',', @$ids;
	return if !length($idStr);
	my $sql = "SELECT $resultCols FROM groups WHERE id IN ($idStr)";
	return $self->_doSelect($sql);
}

sub fetchGroupAttrs
{
	my $self    = shift;
	my $groupID = $self->{dbh}->quote(shift);

	my $sql = <<"	End-of-Here";
		SELECT name, value FROM group_attr
		WHERE group_id = $groupID
	End-of-Here
	my @attrs = $self->_doSelect($sql);
	my $Result = {};
	foreach my $attr (@attrs) {
		$Result->{$attr->{name}} = $attr->{value};
	}
	return $Result;
}

sub fetchGroupIDsOfSystem
{
	my $self     = shift;
	my $systemID = shift;

	my $sql = qq[
		SELECT group_id FROM group_system_ref WHERE system_id = '$systemID'
	];
	return $self->_doSelect($sql, 'group_id');
}

sub fetchGroupIDsOfClient
{
	my $self     = shift;
	my $clientID = shift;

	my $sql = qq[
		SELECT group_id FROM group_client_ref WHERE client_id = '$clientID'
	];
	return $self->_doSelect($sql, 'group_id');
}

################################################################################
### data manipulation functions
################################################################################
sub _doInsert
{
	my $self      = shift;
	my $table     = shift;
	my $valRows   = shift;
	my $ignoreIDs = shift;

	my $dbh    = $self->{'dbh'};
	my $valRow = (@$valRows)[0];
	return if !defined $valRow || !scalar keys %$valRow;

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
		if (!defined $valRow->{id} && !$ignoreIDs && $needToGenerateIDs) {
			# let DB-backend pre-specify ID, as current DB can't generate IDs:
			$valRow->{id} = $self->generateNextIdForTable($table);
			vlog(3, "generated id for <$table> is <$valRow->{id}>");
		}
		my $cols = join ', ', keys %$valRow;
		my $values = join ', ',
		  map { $self->quote($valRow->{$_}) } keys %$valRow;
		my $sql = "INSERT INTO $table ( $cols ) VALUES ( $values )";
		vlog(3, $sql);
		my $sth = $dbh->prepare($sql)
		  or croak _tr(q[Can't insert into table <%s> (%s)], $table,
			$dbh->errstr);
		$sth->execute()
		  or croak _tr(q[Can't insert into table <%s> (%s)], $table,
			$dbh->errstr);
		if (!$ignoreIDs && !defined $valRow->{id}) {
			# id has not been pre-specified, we need to fetch it from DB:
			$valRow->{'id'} = $dbh->last_insert_id(undef, undef, $table, 'id');
			vlog(3, "DB-generated id for <$table> is <$valRow->{id}>");
		}
		push @ids, $valRow->{'id'};
	}
	return wantarray() ? @ids : shift @ids;
}

sub _doDelete
{
	my $self                  = shift;
	my $table                 = shift;
	my $IDs                   = shift;
	my $idCol                 = shift;
	my $additionalWhereClause = shift;

	my $dbh = $self->{'dbh'};

	$IDs   = [undef] unless defined $IDs;
	$idCol = 'id'    unless defined $idCol;
	foreach my $id (@$IDs) {
		my $sql = "DELETE FROM $table";
		if (defined $id) {
			$sql .= " WHERE $idCol = " . $self->quote($id);
			if (defined $additionalWhereClause) {
				$sql .= $additionalWhereClause;
			}
		}
		vlog(3, $sql);
		my $sth = $dbh->prepare($sql)
		  or croak _tr(q[Can't delete from table <%s> (%s)], $table,
			$dbh->errstr);
		$sth->execute()
		  or croak _tr(q[Can't delete from table <%s> (%s)], $table,
			$dbh->errstr);
	}
	return 1;
}

sub _doUpdate
{
	my $self    = shift;
	my $table   = shift;
	my $IDs     = shift;
	my $valRows = shift;

	my $dbh    = $self->{'dbh'};
	my $valRow = (@$valRows)[0];
	return 1 if !defined $valRow || !scalar keys %$valRow;

	my $idx = 0;
	foreach my $valRow (@$valRows) {
		my $id      = $IDs->[$idx++];
		my %valData = %$valRow;
		# fail if asked to change the column 'id', as that is bogus
		return if exists $valData{id} && $valData{id} ne $id;
		# filter column 'id' if present, as we don't want to write it
		delete $valData{id};
		my @cols = map { "$_ = " . $self->quote($valRow->{$_}) }
		  grep { $_ ne 'id' }
		  # filter column 'id' if present, as we don't want
		  # to update it!
		  keys %$valRow;
		next if !@cols;
		my $cols = join ', ', @cols;
		my $sql = "UPDATE $table SET $cols";
		if (defined $id) {
			$sql .= " WHERE id = " . $self->quote($id);
		}
		vlog(3, $sql);
		my $sth = $dbh->prepare($sql)
		  or croak _tr(q[Can't update table <%s> (%s)], $table, $dbh->errstr);
		$sth->execute()
		  or croak _tr(q[Can't update table <%s> (%s)], $table, $dbh->errstr);
	}
	return 1;
}

sub _updateRefTable
{
	my $self        = shift;
	my $table       = shift;
	my $keyID       = shift;
	my $newValueIDs = shift;
	my $keyCol      = shift;
	my $valueCol    = shift;
	my $oldValueIDs = shift;

	my %lastValueIDs;
	@lastValueIDs{@$oldValueIDs} = ();

	foreach my $valueID (@$newValueIDs) {
		if (!exists $lastValueIDs{$valueID}) {
			# value-ID is new, create it
			my $valRow = {
				$keyCol   => $keyID,
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
		$self->_doDelete($table, [keys %lastValueIDs],
			$valueCol, " AND $keyCol='$keyID'");
	}
	return 1;
}

sub _updateOneToManyRefAttr
{
	my $self       = shift;
	my $table      = shift;
	my $oneID      = shift;
	my $newManyIDs = shift;
	my $fkCol      = shift;
	my $oldManyIDs = shift;

	my %lastManyIDs;
	@lastManyIDs{@$oldManyIDs} = ();

	foreach my $id (@$newManyIDs) {
		if (!exists $lastManyIDs{$id}) {
			# ID has changed, update it
			$self->_doUpdate($table, $id, [{$fkCol => $oneID}]);
		} else {
			# ID hasn't changed, leave as is, but remove from hash:
			delete $lastManyIDs{$id};
		}
	}

	# all the remaining many-IDs need to be set to 0:
	foreach my $id (scalar keys %lastManyIDs) {
		$self->_doUpdate($table, $id, [{$fkCol => '0'}]);
	}
	return 1;
}

sub addVendorOS
{
	my $self    = shift;
	my $valRows = shift;

	return $self->_doInsert('vendor_os', $valRows);
}

sub removeVendorOS
{
	my $self        = shift;
	my $vendorOSIDs = shift;

	return $self->_doDelete('vendor_os', $vendorOSIDs);
}

sub changeVendorOS
{
	my $self        = shift;
	my $vendorOSIDs = shift;
	my $valRows     = shift;

	return $self->_doUpdate('vendor_os', $vendorOSIDs, $valRows);
}

sub addExport
{
	my $self    = shift;
	my $valRows = shift;

	return $self->_doInsert('export', $valRows);
}

sub removeExport
{
	my $self      = shift;
	my $exportIDs = shift;

	return $self->_doDelete('export', $exportIDs);
}

sub changeExport
{
	my $self      = shift;
	my $exportIDs = shift;
	my $valRows   = shift;

	return $self->_doUpdate('export', $exportIDs, $valRows);
}

sub changeGlobalInfo
{
	my $self  = shift;
	my $id    = shift;
	my $value = shift;

	return $self->_doUpdate('global_info', [$id], [{'value' => $value}]);
}

sub addSystem
{
	my $self    = shift;
	my $valRows = shift;

	# separate the attribute hashes ...
	my @attrValRows 
		=	map {
				my $attrs = $_->{attrs};
				delete $_->{attrs};
				$attrs;
			}
			@$valRows;

	# ... store the systems to get the IDs ...
	my @systemIDs = $self->_doInsert('system', $valRows);

	# ... finally store the individual attribute sets
	foreach my $id (@systemIDs) {
		my $attrs = shift @attrValRows;
		next if !defined $attrs;
		return if !$self->setSystemAttrs($id, $attrs);
	}

	return @systemIDs;
}

sub removeSystem
{
	my $self      = shift;
	my $systemIDs = shift;

	return $self->_doDelete('system', $systemIDs);
}

sub changeSystem
{
	my $self      = shift;
	my $systemIDs = shift;
	my $valRows   = shift;

	# separate the attribute hashes and store them individually
	my @attrValRows 
		=	map {
				my $attrs = $_->{attrs};
				delete $_->{attrs};
				$attrs;
			}
			@$valRows;
	foreach my $id (@$systemIDs) {
		my $attrs = shift @attrValRows;
		next if !defined $attrs;
		return if !$self->setSystemAttrs($id, $attrs);
	}

	# finally update all systems in one go
	return $self->_doUpdate('system', $systemIDs, $valRows);
}

sub setSystemAttrs
{
	my $self     = shift;
	my $systemID = shift;
	my $attrs    = shift;

	# we take the simple path and remove all attributes ...
	return if !$self->_doDelete('system_attr', [ $systemID ], 'system_id');

	# ... and (re-)insert the given ones
	foreach my $key (keys %$attrs) {
		return if !$self->_doInsert(
			'system_attr', [ {
				system_id => $systemID,
				name      => $key,
				value     => $attrs->{$key},
			} ]
		);
	}
	return 1;
}

sub setClientIDsOfSystem
{
	my $self      = shift;
	my $systemID  = shift;
	my $clientIDs = shift;

	my @currClients = $self->fetchClientIDsOfSystem($systemID);
	return $self->_updateRefTable(
		'client_system_ref', $systemID, $clientIDs, 'system_id', 'client_id', 
		\@currClients
	);
}

sub setGroupIDsOfSystem
{
	my $self     = shift;
	my $systemID = shift;
	my $groupIDs = shift;

	my @currGroups = $self->fetchGroupIDsOfSystem($systemID);
	return $self->_updateRefTable(
		'group_system_ref', $systemID, $groupIDs, 'system_id', 'group_id', 
		\@currGroups
	);
}

sub addClient
{
	my $self    = shift;
	my $valRows = shift;

	# separate the attribute hashes ...
	my @attrValRows 
		=	map {
				my $attrs = $_->{attrs};
				delete $_->{attrs};
				$attrs;
			}
			@$valRows;

	# ... store the clients to get the IDs ...
	my @clientIDs = $self->_doInsert('client', $valRows);

	# ... finally store the individual attribute sets
	foreach my $id (@clientIDs) {
		my $attrs = shift @attrValRows;
		next if !defined $attrs;
		return if !$self->setClientAttrs($id, $attrs);
	}

	return @clientIDs;
}

sub removeClient
{
	my $self      = shift;
	my $clientIDs = shift;

	return $self->_doDelete('client', $clientIDs);
}

sub changeClient
{
	my $self      = shift;
	my $clientIDs = shift;
	my $valRows   = shift;

	# separate the attribute hashes and store them individually
	my @attrValRows 
		=	map {
				my $attrs = $_->{attrs};
				delete $_->{attrs};
				$attrs;
			}
			@$valRows;
	foreach my $id (@$clientIDs) {
		my $attrs = shift @attrValRows;
		next if !defined $attrs;
		return if !$self->setClientAttrs($id, $attrs);
	}

	# finally update all systems in one go
	return $self->_doUpdate('client', $clientIDs, $valRows);
}

sub setClientAttrs
{
	my $self     = shift;
	my $clientID = shift;
	my $attrs    = shift;

	# we take the simple path and remove all attributes ...
	return if !$self->_doDelete('client_attr', [ $clientID ], 'client_id');

	# ... and (re-)insert the given ones
	foreach my $key (keys %$attrs) {
		return if !$self->_doInsert(
			'client_attr', [ {
				client_id => $clientID,
				name      => $key,
				value     => $attrs->{$key},
			} ]
		);
	}
	return 1;
}

sub setSystemIDsOfClient
{
	my $self      = shift;
	my $clientID  = shift;
	my $systemIDs = shift;

	my @currSystems = $self->fetchSystemIDsOfClient($clientID);
	return $self->_updateRefTable(
		'client_system_ref', $clientID, $systemIDs, 'client_id', 'system_id', 
		\@currSystems
	);
}

sub setGroupIDsOfClient
{
	my $self     = shift;
	my $clientID = shift;
	my $groupIDs = shift;

	my @currGroups = $self->fetchGroupIDsOfClient($clientID);
	return $self->_updateRefTable(
		'group_client_ref', $clientID, $groupIDs, 'client_id', 'group_id', 
		\@currGroups
	);
}

sub addGroup
{
	my $self    = shift;
	my $valRows = shift;

	# separate the attribute hashes ...
	my @attrValRows 
		=	map {
				my $attrs = $_->{attrs};
				delete $_->{attrs};
				$attrs;
			}
			@$valRows;

	# ... store the groups to get the IDs ...
	my @groupIDs = $self->_doInsert('groups', $valRows);

	# ... finally store the individual attribute sets
	foreach my $id (@groupIDs) {
		my $attrs = shift @attrValRows;
		next if !defined $attrs;
		return if !$self->setGroupAttrs($id, $attrs);
	}

	return @groupIDs;
}

sub removeGroup
{
	my $self     = shift;
	my $groupIDs = shift;

	return $self->_doDelete('groups', $groupIDs);
}

sub changeGroup
{
	my $self     = shift;
	my $groupIDs = shift;
	my $valRows  = shift;

	# separate the attribute hashes and store them individually
	my @attrValRows 
		=	map {
				my $attrs = $_->{attrs};
				delete $_->{attrs};
				$attrs;
			}
			@$valRows;
	foreach my $id (@$groupIDs) {
		my $attrs = shift @attrValRows;
		next if !defined $attrs;
		return if !$self->setGroupAttrs($id, $attrs);
	}

	# finally update all groups in one go
	return $self->_doUpdate('groups', $groupIDs, $valRows);
}

sub setGroupAttrs
{
	my $self    = shift;
	my $groupID = shift;
	my $attrs   = shift;

	# we take the simple path and remove all attributes ...
	return if !$self->_doDelete('group_attr', [ $groupID ], 'group_id');

	# ... and (re-)insert the given ones
	foreach my $key (keys %$attrs) {
		return if !$self->_doInsert(
			'group_attr', [ {
				group_id => $groupID,
				name      => $key,
				value     => $attrs->{$key},
			} ]
		);
	}
	return 1;
}

sub setClientIDsOfGroup
{
	my $self      = shift;
	my $groupID   = shift;
	my $clientIDs = shift;

	my @currClients = $self->fetchClientIDsOfGroup($groupID);
	return $self->_updateRefTable(
		'group_client_ref', $groupID, $clientIDs, 'group_id', 'client_id', 
		\@currClients
	);
}

sub setSystemIDsOfGroup
{
	my $self      = shift;
	my $groupID   = shift;
	my $systemIDs = shift;

	my @currSystems = $self->fetchSystemIDsOfGroup($groupID);
	return $self->_updateRefTable(
		'group_system_ref', $groupID, $systemIDs, 'group_id', 'system_id', 
		\@currSystems
	);
}

################################################################################
### schema related functions
################################################################################
sub _convertColDescrsToDBNativeString
{
	my $self      = shift;
	my $colDescrs = shift;

	my $colDescrString = join ', ', map {
		# convert each column description into database native format
		# (e.g. convert 'name:s.45' to 'name char(45)'):
		if (!m[^\s*(\S+?)\s*:\s*(\S+?)\s*$]) {
			croak _tr('UnknownDbSchemaColumnDescr', $_);
		}
		"$1 " . $self->schemaConvertTypeDescrToNative($2);
	} @$colDescrs;
	return $colDescrString;
}

sub _convertColDescrsToColNames
{
	my $self      = shift;
	my $colDescrs = shift;

	return map {
		# convert each column description into database native format
		# (e.g. convert 'name:s.45' to 'name char(45)'):
		if (!m[^\s*(\S+?)\s*:.+$]) {
			croak _tr('UnknownDbSchemaColumnDescr', $_);
		}
		$1;
	} @$colDescrs;
}

sub _convertColDescrsToColNamesString
{
	my $self      = shift;
	my $colDescrs = shift;

	return join ', ', $self->_convertColDescrsToColNames($colDescrs);
}

sub schemaFetchDBVersion
{
	my $self = shift;

	my $dbh = $self->{dbh};
	local $dbh->{RaiseError} = 1;
	my $row =
	  eval { $dbh->selectrow_hashref('SELECT schema_version FROM meta'); };
	return 0 if $@;
	# no database access possible
	return unless defined $row;
	# no entry in meta-table
	return $row->{schema_version};
}

sub schemaUpgradeDBFrom
{
	my $self        = shift;
	my $currVersion = shift;

	$self->_upgradeDBTo0_2() if $currVersion < 0.2;

	return 1;
}

sub schemaSetDBVersion
{
	my $self      = shift;
	my $dbVersion = shift;

	$self->{dbh}->do("UPDATE meta SET schema_version = '$dbVersion'")
		or croak _tr('Unable to set DB-schema version to %s!', $dbVersion);

	return 1;
}

sub schemaConvertTypeDescrToNative
{    # a default implementation, many DBs need to override...
	my $self      = shift;
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
		croak _tr('UnknownDbSchemaTypeDescr', $typeDescr);
	}
}

sub schemaAddTable
{
	my $self        = shift;
	my $table       = shift;
	my $colDescrs   = shift;
	my $initialVals = shift;
	my $isSubCmd    = shift;

	my $dbh = $self->{'dbh'};
	vlog(1, "adding table <$table> to schema...") unless $isSubCmd;
	my $colDescrString = $self->_convertColDescrsToDBNativeString($colDescrs);
	my $sql            = "CREATE TABLE $table ($colDescrString)";
	vlog(3, $sql);
	$dbh->do($sql)
	  or croak _tr(q[Can't create table <%s> (%s)], $table, $dbh->errstr);
	if (defined $initialVals) {
		my $ignoreIDs = ($colDescrString !~ m[\bid\b]);
		# don't care about IDs if there's no 'id' column in this table
		$self->_doInsert($table, $initialVals, $ignoreIDs);
	}
	return;
}

sub schemaDropTable
{
	my $self     = shift;
	my $table    = shift;
	my $isSubCmd = shift;

	my $dbh = $self->{'dbh'};
	vlog(1, "dropping table <$table> from schema...") unless $isSubCmd;
	my $sql = "DROP TABLE $table";
	vlog(3, $sql);
	$dbh->do($sql)
	  or croak _tr(q[Can't drop table <%s> (%s)], $table, $dbh->errstr);
	return;
}

sub schemaRenameTable
{   # a rather simple-minded implementation that renames a table in several
	# steps:
	# 	- create the new table
	# 	- copy the data over from the old one
	# 	- drop the old table
	# This should be overriden for advanced DBs, as these more often than not
	# implement the 'ALTER TABLE <old> RENAME TO <new>' SQL-command (which
	# is much more efficient).
	my $self      = shift;
	my $oldTable  = shift;
	my $newTable  = shift;
	my $colDescrs = shift;
	my $isSubCmd  = shift;

	my $dbh = $self->{'dbh'};
	vlog(1, "renaming table <$oldTable> to <$newTable>...") unless $isSubCmd;
	my $colDescrString = $self->_convertColDescrsToDBNativeString($colDescrs);
	my $sql            = "CREATE TABLE $newTable ($colDescrString)";
	vlog(3, $sql);
	$dbh->do($sql)
	  or croak _tr(q[Can't create table <%s> (%s)], $oldTable, $dbh->errstr);
	my $colNamesString = $self->_convertColDescrsToColNamesString($colDescrs);
	my @dataRows = $self->_doSelect("SELECT $colNamesString FROM $oldTable");
	$self->_doInsert($newTable, \@dataRows);
	$sql = "DROP TABLE $oldTable";
	vlog(3, $sql);
	$dbh->do($sql)
	  or croak _tr(q[Can't drop table <%s> (%s)], $oldTable, $dbh->errstr);
	return;
}

sub schemaAddColumns
{   # a rather simple-minded implementation that adds columns to a table
	# in several steps:
	# 	- create a temp table with the new layout
	# 	- copy the data from the old table into the new one
	# 	- drop the old table
	# 	- rename the temp table to the original name
	# This should be overriden for advanced DBs, as these more often than not
	# implement the 'ALTER TABLE <table> ADD COLUMN <col>' SQL-command (which
	# is much more efficient).
	my $self              = shift;
	my $table             = shift;
	my $newColDescrs      = shift;
	my $newColDefaultVals = shift;
	my $colDescrs         = shift;
	my $isSubCmd          = shift;

	my $dbh         = $self->{'dbh'};
	my $tempTable   = "${table}_temp";
	my @newColNames = $self->_convertColDescrsToColNames($newColDescrs);
	my $newColStr   = join ', ', @newColNames;
	vlog(1, "adding columns <$newColStr> to table <$table>...")
	  unless $isSubCmd;
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
	return;
}

sub schemaDropColumns
{   # a rather simple-minded implementation that drops columns from a table
	# in several steps:
	# 	- create a temp table with the new layout
	# 	- copy the data from the old table into the new one
	# 	- drop the old table
	# 	- rename the temp table to the original name
	# This should be overriden for advanced DBs, as these sometimes
	# implement the 'ALTER TABLE <table> DROP COLUMN <col>' SQL-command (which
	# is much more efficient).
	my $self         = shift;
	my $table        = shift;
	my $dropColNames = shift;
	my $colDescrs    = shift;
	my $isSubCmd     = shift;

	my $dbh        = $self->{'dbh'};
	my $tempTable  = "${table}_temp";
	my $dropColStr = join ', ', @$dropColNames;
	vlog(1, "dropping columns <$dropColStr> from table <$table>...")
	  unless $isSubCmd;
	$self->schemaAddTable($tempTable, $colDescrs, undef, 1);

	# copy the data from the old table to the new:
	my $colNamesString = $self->_convertColDescrsToColNamesString($colDescrs);
	my @dataRows       = $self->_doSelect("SELECT $colNamesString FROM $table");
	$self->_doInsert($tempTable, \@dataRows);

	$self->schemaDropTable($table, 1);
	$self->schemaRenameTable($tempTable, $table, $colDescrs, 1);
	return;
}

sub schemaChangeColumns
{   # a rather simple-minded implementation that changes columns
	# in several steps:
	# 	- create a temp table with the new layout
	# 	- copy the data from the old table into the new one
	# 	- drop the old table
	# 	- rename the temp table to the original name
	# This should be overriden for advanced DBs, as these sometimes
	# implement the 'ALTER TABLE <table> CHANGE COLUMN <col>' SQL-command (which
	# is much more efficient).
	my $self       = shift;
	my $table      = shift;
	my $colChanges = shift;
	my $colDescrs  = shift;
	my $isSubCmd   = shift;

	my $dbh          = $self->{'dbh'};
	my $tempTable    = "${table}_temp";
	my $changeColStr = join ', ', keys %$colChanges;
	vlog(1, "changing columns <$changeColStr> of table <$table>...")
	  unless $isSubCmd;
	$self->schemaAddTable($tempTable, $colDescrs, undef, 1);

	# copy the data from the old table to the new:
	my $colNamesString = $self->_convertColDescrsToColNamesString($colDescrs);
	my @dataRows       = $self->_doSelect("SELECT * FROM $table");
	foreach my $oldCol (keys %$colChanges) {
		my $newCol =
		  $self->_convertColDescrsToColNamesString([$colChanges->{$oldCol}]);
		# rename current column in all data-rows:
		foreach my $row (@dataRows) {
			$row->{$newCol} = $row->{$oldCol};
			delete $row->{$oldCol};
		}
	}
	$self->_doInsert($tempTable, \@dataRows);

	$self->schemaDropTable($table, 1);
	$self->schemaRenameTable($tempTable, $table, $colDescrs, 1);
	return;
}

sub _upgradeDBTo0_2
{
	my $self = shift;

	# move attributes into separate tables ...
	#
	# ... system attributes ...
	$self->schemaAddTable(
		'system_attr', 
		[
			'id:pk',
			'system_id:fk',
			'name:s.128',
			'value:s.255',
		]
	);
	foreach my $system ($self->fetchSystemByFilter()) {
		my %attrs;
		foreach my $key (keys %$system) {
			next if substr($key, 0, 5) ne 'attr_';
			my $attrValue = $system->{$key} || '';
			next if $system->{id} > 0 && !length($attrValue);
			my $newAttrName = substr($key, 5);
			$attrs{$newAttrName} = $attrValue;
		}
		$self->setSystemAttrs($system->{id}, \%attrs);
	}
	$self->schemaDropColumns(
		'system',
		[
			'attr_automnt_dir',
			'attr_automnt_src',
			'attr_country',
			'attr_dm_allow_shutdown',
			'attr_hw_graphic',
			'attr_hw_monitor',
			'attr_hw_mouse',
			'attr_late_dm',
			'attr_netbios_workgroup',
			'attr_nis_domain',
			'attr_nis_servers',
			'attr_ramfs_fsmods',
			'attr_ramfs_miscmods',
			'attr_ramfs_nicmods',
			'attr_ramfs_screen',
			'attr_sane_scanner',
			'attr_scratch',
			'attr_slxgrp',
			'attr_start_alsasound',
			'attr_start_atd',
			'attr_start_cron',
			'attr_start_dreshal',
			'attr_start_ntp',
			'attr_start_nfsv4',
			'attr_start_printer',
			'attr_start_samba',
			'attr_start_snmp',
			'attr_start_sshd',
			'attr_start_syslog',
			'attr_start_x',
			'attr_start_xdmcp',
			'attr_tex_enable',
			'attr_timezone',
			'attr_tvout',
			'attr_vmware',
		],
		[
			'id:pk',
			'export_id:fk',
			'name:s.64',
			'label:s.64',
			'kernel:s.128',
			'kernel_params:s.512',
			'hidden:b',
			'comment:s.1024',
		]
	);
	#
	# ... client attributes ...
	$self->schemaAddTable(
		'client_attr',
		[
			'id:pk',
			'client_id:fk',
			'name:s.128',
			'value:s.255',
		]
	);
	foreach my $client ($self->fetchClientByFilter()) {
		my %attrs;
		foreach my $key (keys %$client) {
			next if substr($key, 0, 5) ne 'attr_';
			my $attrValue = $client->{$key} || '';
			next if !length($attrValue);
			my $newAttrName = substr($key, 5);
			$attrs{$newAttrName} = $attrValue;
		}
		$self->setClientAttrs($client->{id}, \%attrs);
	}
	$self->schemaDropColumns(
		'client',
		[
			'attr_automnt_dir',
			'attr_automnt_src',
			'attr_country',
			'attr_dm_allow_shutdown',
			'attr_hw_graphic',
			'attr_hw_monitor',
			'attr_hw_mouse',
			'attr_late_dm',
			'attr_netbios_workgroup',
			'attr_nis_domain',
			'attr_nis_servers',
			'attr_sane_scanner',
			'attr_scratch',
			'attr_slxgrp',
			'attr_start_alsasound',
			'attr_start_atd',
			'attr_start_cron',
			'attr_start_dreshal',
			'attr_start_ntp',
			'attr_start_nfsv4',
			'attr_start_printer',
			'attr_start_samba',
			'attr_start_snmp',
			'attr_start_sshd',
			'attr_start_syslog',
			'attr_start_x',
			'attr_start_xdmcp',
			'attr_tex_enable',
			'attr_timezone',
			'attr_tvout',
			'attr_vmware',
		],
		[
			'id:pk',
			'name:s.128',
			'mac:s.20',
			'boot_type:s.20',
			'unbootable:b',
			'kernel_params:s.128',
			'comment:s.1024',
		]
	);
	#
	# ... group attributes ...
	$self->schemaAddTable(
		'group_attr',
		[
			'id:pk',
			'group_id:fk',
			'name:s.128',
			'value:s.255',
		]
	);
	foreach my $group ($self->fetchGroupByFilter()) {
		my %attrs;
		foreach my $key (keys %$group) {
			next if substr($key, 0, 5) ne 'attr_';
			my $attrValue = $group->{$key} || '';
			next if !length($attrValue);
			my $newAttrName = substr($key, 5);
			$attrs{$newAttrName} = $attrValue;
		}
		$self->setGroupAttrs($group->{id}, \%attrs);
	}
	$self->schemaDropColumns(
		'groups',
		[
			'attr_automnt_dir',
			'attr_automnt_src',
			'attr_country',
			'attr_dm_allow_shutdown',
			'attr_hw_graphic',
			'attr_hw_monitor',
			'attr_hw_mouse',
			'attr_late_dm',
			'attr_netbios_workgroup',
			'attr_nis_domain',
			'attr_nis_servers',
			'attr_sane_scanner',
			'attr_scratch',
			'attr_slxgrp',
			'attr_start_alsasound',
			'attr_start_atd',
			'attr_start_cron',
			'attr_start_dreshal',
			'attr_start_ntp',
			'attr_start_nfsv4',
			'attr_start_printer',
			'attr_start_samba',
			'attr_start_snmp',
			'attr_start_sshd',
			'attr_start_syslog',
			'attr_start_x',
			'attr_start_xdmcp',
			'attr_tex_enable',
			'attr_timezone',
			'attr_tvout',
			'attr_vmware',
		],
		[
			'id:pk',
			'name:s.128',
			'priority:i',
			'comment:s.1024',
		]
	);

	return 1;
}

1;

=head1 NAME

DBI.pm - provides DBI-based implementation of the OpenSLX MetaDB API.

=head1 SYNOPSIS

This class is the base for all DBI-related metaDB variants.
It provides a default implementation for every method, such that
each DB-specific implementation needs to override only the methods
that require a different implementation than the one provided here.

=head1 NOTES

In case you ask yourself why none of the SQL-statements in this
file make use of SQL bind params (?), the answer is that at least
one DBD-driver didn't like them at all. As the performance gains
from bound params are not really necessary here, we simply do
not use them.

