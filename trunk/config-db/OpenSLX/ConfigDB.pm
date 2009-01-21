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
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);
$VERSION = 1;    # API-version

################################################################################
### This module defines the data abstraction layer for the OpenSLX configuration
### database.
### Aim of this abstraction is to hide the details of the data layout and
### the peculiarities of individual database types behind a simple interface
### that offers straightforward access to and manipulation of the
### OpenSLX-systems and -clients (without the need to use SQL).
### The interface is divided into four parts:
### 	- data access methods (getting data)
### 	- data manipulation methods (adding, removing and changing data)
### 	- data aggregation methods (combining data in ways useful for apps)
### 	- support methods
################################################################################

use Exporter;
@ISA = qw(Exporter);

my @supportExports = qw(
  isAttribute mergeAttributes pushAttributes
  externalIDForSystem externalIDForClient externalConfigNameForClient
  externalAttrName generatePlaceholderFor
);

@EXPORT      = ();
@EXPORT_OK   = (@supportExports);
%EXPORT_TAGS = ('support' => [@supportExports],);

################################################################################
### private stuff
################################################################################
use Carp;
use OpenSLX::Basics;
use OpenSLX::DBSchema;

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
					confess _tr('UnknownDbSchemaCommand', $cmd);
				}
			}
		}
		vlog(1, _tr('upgrade done'));
	} else {
		vlog(1, _tr('DB matches current schema version %s', $currVersion));
	}
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

################################################################################
### data access interface
################################################################################
sub new
{
	my $class = shift;
	my $self  = {};
	return bless $self, $class;
}

sub connect
{
	my $self     = shift;
	my $dbParams = shift;
	# hash-ref with any additional info that might be required by
	# specific metadb-module (not used yet)

	my $dbType = $openslxConfig{'db-type'};
	# name of underlying database module...

	# map db-type to name of module, such that the user doesn't have
	# to type the correct case:
	my %dbTypeMap = (
		'csv'    => 'CSV',
		'mysql'  => 'mysql',
		'sqlite' => 'SQLite',
	);
	my $lcType = lc($dbType);
	if (exists $dbTypeMap{$lcType}) {
		$dbType = $dbTypeMap{$lcType};
	}

	my $dbModule = "OpenSLX::MetaDB::$dbType";
	unless (eval "require $dbModule") {
		if ($! == 2) {
			die _tr(
				"Unable to load DB-module <%s>\nthat database type is not supported (yet?)\n",
				$dbModule
			);
		} else {
			die _tr("Unable to load DB-module <%s> (%s)\n", $dbModule, $@);
		}
	}
	my $modVersion = $dbModule->VERSION;
	if ($modVersion < $VERSION) {
		confess _tr(
			'Could not load module <%s> (Version <%s> required, but <%s> found)',
			$dbModule, $VERSION, $modVersion);
	}
	my $metaDB = $dbModule->new();
	if (!eval '$metaDB->connect($dbParams);1') {
		warn _tr("Unable to connect to DB-module <%s>\n%s", $dbModule, $@);
		warn _tr("These DB-modules seem to work ok:");
		foreach my $dbMod ('CSV', 'mysql', 'SQLite') {
			if (eval "require DBD::$dbMod;") {
				vlog(0, "\t$dbMod\n");
			}
		}
		die _tr(
			'Please use slxsettings if you want to switch to another db-type.');
	}

	$self->{'db-type'} = $dbType;
	$self->{'meta-db'} = $metaDB;
	foreach my $tk (keys %{$DbSchema->{tables}}) {
		$metaDB->schemaDeclareTable($tk, $DbSchema->{tables}->{$tk});
	}

	_checkAndUpgradeDBSchemaIfNecessary($metaDB);
}

sub disconnect
{
	my $self = shift;

	$self->{'meta-db'}->disconnect();
}

sub start_transaction
{
	my $self = shift;

	$self->{'meta-db'}->start_transaction();
}

sub commit_transaction
{
	my $self = shift;

	$self->{'meta-db'}->commit_transaction();
}

sub rollback_transaction
{
	my $self = shift;

	$self->{'meta-db'}->rollback_transaction();
}

sub fetchVendorOSByFilter
{
	my $self       = shift;
	my $filter     = shift;
	my $resultCols = shift;

	my @vendorOS =
	  $self->{'meta-db'}->fetchVendorOSByFilter($filter, $resultCols);
	return wantarray() ? @vendorOS : shift @vendorOS;
}

sub fetchVendorOSByID
{
	my $self       = shift;
	my $ids        = _aref(shift);
	my $resultCols = shift;

	my @vendorOS = $self->{'meta-db'}->fetchVendorOSByID($ids, $resultCols);
	return wantarray() ? @vendorOS : shift @vendorOS;
}

sub fetchExportByFilter
{
	my $self       = shift;
	my $filter     = shift;
	my $resultCols = shift;

	my @exports = $self->{'meta-db'}->fetchExportByFilter($filter, $resultCols);
	return wantarray() ? @exports : shift @exports;
}

sub fetchExportByID
{
	my $self       = shift;
	my $ids        = _aref(shift);
	my $resultCols = shift;

	my @exports = $self->{'meta-db'}->fetchExportByID($ids, $resultCols);
	return wantarray() ? @exports : shift @exports;
}

sub fetchExportIDsOfVendorOS
{
	my $self       = shift;
	my $vendorOSID = shift;

	return $self->{'meta-db'}->fetchExportIDsOfVendorOS($vendorOSID);
}

sub fetchGlobalInfo
{
	my $self = shift;
	my $id   = shift;

	return $self->{'meta-db'}->fetchGlobalInfo($id);
}

sub fetchSystemByFilter
{
	my $self       = shift;
	my $filter     = shift;
	my $resultCols = shift;

	my @systems = $self->{'meta-db'}->fetchSystemByFilter($filter, $resultCols);
	return wantarray() ? @systems : shift @systems;
}

sub fetchSystemByID
{
	my $self       = shift;
	my $ids        = _aref(shift);
	my $resultCols = shift;

	my @systems = $self->{'meta-db'}->fetchSystemByID($ids, $resultCols);
	return wantarray() ? @systems : shift @systems;
}

sub fetchSystemIDsOfExport
{
	my $self     = shift;
	my $exportID = shift;

	return $self->{'meta-db'}->fetchSystemIDsOfExport($exportID);
}

sub fetchSystemIDsOfClient
{
	my $self     = shift;
	my $clientID = shift;

	return $self->{'meta-db'}->fetchSystemIDsOfClient($clientID);
}

sub fetchSystemIDsOfGroup
{
	my $self    = shift;
	my $groupID = shift;

	return $self->{'meta-db'}->fetchSystemIDsOfGroup($groupID);
}

sub fetchClientByFilter
{
	my $self   = shift;
	my $filter = shift;

	my @clients = $self->{'meta-db'}->fetchClientByFilter($filter);
	return wantarray() ? @clients : shift @clients;
}

sub fetchClientByID
{
	my $self       = shift;
	my $ids        = _aref(shift);
	my $resultCols = shift;

	my @clients = $self->{'meta-db'}->fetchClientByID($ids, $resultCols);
	return wantarray() ? @clients : shift @clients;
}

sub fetchClientIDsOfSystem
{
	my $self     = shift;
	my $systemID = shift;

	return $self->{'meta-db'}->fetchClientIDsOfSystem($systemID);
}

sub fetchClientIDsOfGroup
{
	my $self    = shift;
	my $groupID = shift;

	return $self->{'meta-db'}->fetchClientIDsOfGroup($groupID);
}

sub fetchGroupByFilter
{
	my $self       = shift;
	my $filter     = shift;
	my $resultCols = shift;

	my @groups = $self->{'meta-db'}->fetchGroupByFilter($filter, $resultCols);
	return wantarray() ? @groups : shift @groups;
}

sub fetchGroupByID
{
	my $self       = shift;
	my $ids        = _aref(shift);
	my $resultCols = shift;

	my @groups = $self->{'meta-db'}->fetchGroupByID($ids, $resultCols);
	return wantarray() ? @groups : shift @groups;
}

sub fetchGroupIDsOfSystem
{
	my $self     = shift;
	my $systemID = shift;

	return $self->{'meta-db'}->fetchGroupIDsOfSystem($systemID);
}

sub fetchGroupIDsOfClient
{
	my $self     = shift;
	my $clientID = shift;

	return $self->{'meta-db'}->fetchGroupIDsOfClient($clientID);
}

################################################################################
### data manipulation interface
################################################################################
sub addVendorOS
{
	my $self    = shift;
	my $valRows = _aref(shift);

	return $self->{'meta-db'}->addVendorOS($valRows);
}

sub removeVendorOS
{
	my $self        = shift;
	my $vendorOSIDs = _aref(shift);

	return $self->{'meta-db'}->removeVendorOS($vendorOSIDs);
}

sub changeVendorOS
{
	my $self        = shift;
	my $vendorOSIDs = _aref(shift);
	my $valRows     = _aref(shift);

	return $self->{'meta-db'}->changeVendorOS($vendorOSIDs, $valRows);
}

sub incrementExportCounterForVendorOS
{
	my $self = shift;
	my $id   = shift;

	$self->start_transaction();
	my $vendorOS = $self->fetchVendorOSByID($id);
	return undef unless defined $vendorOS;
	my $exportCounter = $vendorOS->{export_counter} + 1;
	$self->changeVendorOS($id, {'export_counter' => $exportCounter});
	$self->commit_transaction();

	return $exportCounter;
}

sub incrementGlobalCounter
{
	my $self        = shift;
	my $counterName = shift;

	$self->start_transaction();
	my $value = $self->fetchGlobalInfo($counterName);
	return undef unless defined $value;
	my $newValue = $value + 1;
	$self->changeGlobalInfo($counterName, $newValue);
	$self->commit_transaction();

	return $value;
}

sub addExport
{
	my $self    = shift;
	my $valRows = _aref(shift);

	return $self->{'meta-db'}->addExport($valRows);
}

sub removeExport
{
	my $self      = shift;
	my $exportIDs = _aref(shift);

	return $self->{'meta-db'}->removeExport($exportIDs);
}

sub changeExport
{
	my $self      = shift;
	my $exportIDs = _aref(shift);
	my $valRows   = _aref(shift);

	return $self->{'meta-db'}->changeExport($exportIDs, $valRows);
}

sub changeGlobalInfo
{
	my $self  = shift;
	my $id    = shift;
	my $value = shift;

	return $self->{'meta-db'}->changeGlobalInfo($id, $value);
}

sub addSystem
{
	my $self    = shift;
	my $valRows = _aref(shift);

	foreach my $valRow (@$valRows) {
		if (!length($valRow->{kernel})) {
			$valRow->{kernel} = 'vmlinuz';
		}
		if (!length($valRow->{label})) {
			$valRow->{label} = $valRow->{name};
		}
	}

	return $self->{'meta-db'}->addSystem($valRows);
}

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

sub changeSystem
{
	my $self      = shift;
	my $systemIDs = _aref(shift);
	my $valRows   = _aref(shift);

	return $self->{'meta-db'}->changeSystem($systemIDs, $valRows);
}

sub setClientIDsOfSystem
{
	my $self      = shift;
	my $systemID  = shift;
	my $clientIDs = _aref(shift);

	my @uniqueClientIDs = _unique(@$clientIDs);
	return $self->{'meta-db'}
	  ->setClientIDsOfSystem($systemID, \@uniqueClientIDs);
}

sub addClientIDsToSystem
{
	my $self         = shift;
	my $systemID     = shift;
	my $newClientIDs = _aref(shift);

	my @clientIDs = $self->{'meta-db'}->fetchClientIDsOfSystem($systemID);
	push @clientIDs, @$newClientIDs;
	return $self->setClientIDsOfSystem($systemID, \@clientIDs);
}

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

sub setGroupIDsOfSystem
{
	my $self     = shift;
	my $systemID = shift;
	my $groupIDs = _aref(shift);

	my @uniqueGroupIDs = _unique(@$groupIDs);
	return $self->{'meta-db'}->setGroupIDsOfSystem($systemID, \@uniqueGroupIDs);
}

sub addGroupIDsToSystem
{
	my $self        = shift;
	my $systemID    = shift;
	my $newGroupIDs = _aref(shift);

	my @groupIDs = $self->{'meta-db'}->fetchGroupIDsOfSystem($systemID);
	push @groupIDs, @$newGroupIDs;
	return $self->setGroupIDsOfSystem($systemID, \@groupIDs);
}

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

sub addClient
{
	my $self    = shift;
	my $valRows = _aref(shift);

	foreach my $valRow (@$valRows) {
		if (!length($valRow->{boot_type})) {
			$valRow->{boot_type} = 'pxe';
		}
	}

	return $self->{'meta-db'}->addClient($valRows);
}

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

sub changeClient
{
	my $self      = shift;
	my $clientIDs = _aref(shift);
	my $valRows   = _aref(shift);

	return $self->{'meta-db'}->changeClient($clientIDs, $valRows);
}

sub setSystemIDsOfClient
{
	my $self      = shift;
	my $clientID  = shift;
	my $systemIDs = _aref(shift);

	my @uniqueSystemIDs = _unique(@$systemIDs);
	return $self->{'meta-db'}
	  ->setSystemIDsOfClient($clientID, \@uniqueSystemIDs);
}

sub addSystemIDsToClient
{
	my $self         = shift;
	my $clientID     = shift;
	my $newSystemIDs = _aref(shift);

	my @systemIDs = $self->{'meta-db'}->fetchSystemIDsOfClient($clientID);
	push @systemIDs, @$newSystemIDs;
	return $self->setSystemIDsOfClient($clientID, \@systemIDs);
}

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

sub setGroupIDsOfClient
{
	my $self     = shift;
	my $clientID = shift;
	my $groupIDs = _aref(shift);

	my @uniqueGroupIDs = _unique(@$groupIDs);
	return $self->{'meta-db'}->setGroupIDsOfClient($clientID, \@uniqueGroupIDs);
}

sub addGroupIDsToClient
{
	my $self        = shift;
	my $clientID    = shift;
	my $newGroupIDs = _aref(shift);

	my @groupIDs = $self->{'meta-db'}->fetchGroupIDsOfClient($clientID);
	push @groupIDs, @$newGroupIDs;
	return $self->setGroupIDsOfClient($clientID, \@groupIDs);
}

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

sub addGroup
{
	my $self    = shift;
	my $valRows = _aref(shift);

	return $self->{'meta-db'}->addGroup($valRows);
}

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

sub changeGroup
{
	my $self     = shift;
	my $groupIDs = _aref(shift);
	my $valRows  = _aref(shift);

	return $self->{'meta-db'}->changeGroup($groupIDs, $valRows);
}

sub setClientIDsOfGroup
{
	my $self      = shift;
	my $groupID   = shift;
	my $clientIDs = _aref(shift);

	my @uniqueClientIDs = _unique(@$clientIDs);
	return $self->{'meta-db'}->setClientIDsOfGroup($groupID, \@uniqueClientIDs);
}

sub addClientIDsToGroup
{
	my $self         = shift;
	my $groupID      = shift;
	my $newClientIDs = _aref(shift);

	my @clientIDs = $self->{'meta-db'}->fetchClientIDsOfGroup($groupID);
	push @clientIDs, @$newClientIDs;
	return $self->setClientIDsOfGroup($groupID, \@clientIDs);
}

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

sub setSystemIDsOfGroup
{
	my $self      = shift;
	my $groupID   = shift;
	my $systemIDs = _aref(shift);

	my @uniqueSystemIDs = _unique(@$systemIDs);
	return $self->{'meta-db'}->setSystemIDsOfGroup($groupID, \@uniqueSystemIDs);
}

sub addSystemIDsToGroup
{
	my $self         = shift;
	my $groupID      = shift;
	my $newSystemIDs = _aref(shift);

	my @systemIDs = $self->{'meta-db'}->fetchSystemIDsOfGroup($groupID);
	push @systemIDs, @$newSystemIDs;
	return $self->setSystemIDsOfGroup($groupID, \@systemIDs);
}

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

sub emptyDatabase
{    # clears all user-data from the database
	my $self = shift;

	my @groupIDs = map { $_->{id} } $self->fetchGroupByFilter();
	$self->removeGroup(\@groupIDs);

	my @clientIDs = map { $_->{id} }
	  grep { $_->{id} > 0 } $self->fetchClientByFilter();
	$self->removeClient(\@clientIDs);

	my @sysIDs = map { $_->{id} }
	  grep { $_->{id} > 0 } $self->fetchSystemByFilter();
	$self->removeSystem(\@sysIDs);

	my @exportIDs = map { $_->{id} }
	  grep { $_->{id} > 0 } $self->fetchExportByFilter();
	$self->removeExport(\@exportIDs);

	my @vendorOSIDs = map { $_->{id} }
	  grep { $_->{id} > 0 } $self->fetchVendorOSByFilter();
	$self->removeVendorOS(\@vendorOSIDs);
}

################################################################################
### data aggregation interface
################################################################################
sub mergeDefaultAttributesIntoSystem
{    # merge default system attributes into given system
	    # and push the default client attributes on top of that
	my $self   = shift;
	my $system = shift;

	my $defaultSystem = $self->fetchSystemByID(0);
	mergeAttributes($system, $defaultSystem);

	my $defaultClient = $self->fetchClientByID(0);
	pushAttributes($system, $defaultClient);
}

sub mergeDefaultAndGroupAttributesIntoClient
{       # merge default and group configurations into given client
	my $self   = shift;
	my $client = shift;

	# step over all groups this client belongs to
	# (ordered by priority from highest to lowest):
	my @groupIDs = $self->fetchGroupIDsOfClient($client->{id});
	my @groups   =
	  sort { $b->{priority} <=> $a->{priority} }
	  $self->fetchGroupByID(\@groupIDs);
	foreach my $group (@groups) {
		# merge configuration from this group into the current client:
		vlog(3,
		  _tr('merging from group %d:%s...', $group->{id}, $group->{name}));
		mergeAttributes($client, $group);
	}

	# merge configuration from default client:
	vlog(3, _tr('merging from default client...'));
	my $defaultClient = $self->fetchClientByID(0);
	mergeAttributes($client, $defaultClient);
}

sub aggregatedSystemIDsOfClient
{    # return aggregated list of system-IDs this client should offer
	    # (as indicated by itself, the default client and the client's groups)
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
	push @systemIDs, $self->fetchSystemIDsOfClient(0);

	return _unique(@systemIDs);
}

sub aggregatedClientIDsOfSystem
{    # return aggregated list of client-IDs this system is linked to
	    # (as indicated by itself, the default system and the system's groups).
	my $self   = shift;
	my $system = shift;

	# add all clients directly linked to system:
	my @clientIDs = $self->fetchClientIDsOfSystem($system->{id});

	if (grep { $_ == 0; } @clientIDs) {
		# add *all* client-IDs if the system is being referenced by
		# the default client, as that means that all clients should offer
		#this system for booting:
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
	push @clientIDs, $self->fetchClientIDsOfSystem(0);

	return _unique(@clientIDs);
}

sub aggregatedSystemFileInfoFor
{    # return aggregated information about the kernel and initialramfs
	    # this system is using
	my $self   = shift;
	my $system = shift;

	my $info = {%$system};

	my $export = $self->fetchExportByID($system->{export_id});
	if (!defined $export) {
		die _tr(
			"DB-problem: system '%s' references export with id=%s, but that doesn't exist!",
			$system->{name}, $system->{export_id}
		);
	}
	$info->{'export'} = $export;

	my $vendorOS = $self->fetchVendorOSByID($export->{vendor_os_id});
	if (!defined $vendorOS) {
		die _tr(
			"DB-problem: export '%s' references vendor-OS with id=%s, but that doesn't exist!",
			$export->{name}, $export->{vendor_os_id}
		);
	}
	$info->{'vendor-os'} = $vendorOS;

	my $kernelPath =
	  "$openslxConfig{'private-path'}/stage1/$vendorOS->{name}/boot";
	$info->{'kernel-file'} = "$kernelPath/$system->{kernel}";

	my $exportURI = $export->{'uri'};
	if ($exportURI !~ m[\w]) {
		# auto-generate export_uri if none has been given:
		my $type           = $export->{'type'};
		my $osExportEngine = instantiateClass("OpenSLX::OSExport::Engine");
		$osExportEngine->initializeFromExisting($export->{name});
		$exportURI = $osExportEngine->generateExportURI($export, $vendorOS);
	}
	$info->{'export-uri'} = $exportURI;

	return $info;
}

################################################################################
### support interface
################################################################################
sub isAttribute
{    # returns whether or not the given key is an exportable attribute
	my $key = shift;

	return $key =~ m[^attr_];
}

sub mergeAttributes
{    # copies all attributes of source that are unset in target over
	my $target = shift;
	my $source = shift;

	foreach my $key (grep { isAttribute($_) } keys %$source) {
		if (length($source->{$key}) > 0 && length($target->{$key}) == 0) {
			vlog(3, _tr("merging %s (val=%s)", $key, $source->{$key}));
			$target->{$key} = $source->{$key};
		}
	}
}

sub pushAttributes
{    # copies all attributes that are set in source into the target
	my $target = shift;
	my $source = shift;

	foreach my $key (grep { isAttribute($_) } keys %$source) {
		if (length($source->{$key}) > 0) {
			vlog(3, _tr("pushing %s (val=%s)", $key, $source->{$key}));
			$target->{$key} = $source->{$key};
		}
	}
}

sub externalIDForSystem
{    # returns given system's name as the external ID, worked into a
	    # state that is usable as a filename:
	my $system = shift;

	return "default" if $system->{id} == 0;

	my $name = $system->{name};
	$name =~ tr[/][_];
	return $name;
}

sub externalIDForClient
{       # returns given client's MAC as the external ID, worked into a
	    # state that is usable as a filename:
	my $client = shift;

	return "default" if $client->{id} == 0;

	my $mac = lc($client->{mac});
	# PXE seems to expect MACs being all lowercase
	$mac =~ tr[:][-];
	return "01-$mac";
}

sub externalConfigNameForClient
{       # returns given client's name as the external ID, worked into a
	    # state that is usable as a filename:
	my $client = shift;

	return "default" if $client->{id} == 0;

	my $name = $client->{name};
	$name =~ tr[/][_];
	return $name;
}

sub externalAttrName
{
	my $attr = shift;
	if ($attr =~ m[^attr_]) {
		return substr($attr, 5);
	}
	return $attr;
}

sub generatePlaceholderFor
{
	my $varName = shift;
	return '@@@' . $varName . '@@@';
}

1;
