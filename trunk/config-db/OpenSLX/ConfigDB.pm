package OpenSLX::ConfigDB;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);
$VERSION = 1.01;		# API-version . implementation-version

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

my @accessExports = qw(
	connectConfigDB disconnectConfigDB
	fetchVendorOSesByFilter fetchVendorOSesByID fetchVendorOSIDsOfSystem
	fetchSystemsByFilter fetchSystemsByID fetchSystemIDsOfClient
	fetchSystemIDsOfGroup
	fetchSystemsVariantByFilter fetchSystemVariantsByID
	fetchSystemVariantIDsOfSystem
	fetchClientsByFilter fetchClientsByID fetchClientIDsOfSystem
	fetchClientIDsOfGroup
	fetchGroupsByFilter fetchGroupsByID fetchGroupIDsOfClient
	fetchGroupIDsOfSystem
);

my @manipulationExports = qw(
	addVendorOS removeVendorOS changeVendorOS
	addSystem removeSystem changeSystem
	setClientIDsOfSystem addClientIDsToSystem removeClientIDsFromSystem
	setGroupIDsOfSystem addGroupIDsToSystem removeGroupIDsFromSystem
	addSystemVariant removeSystemVariant changeSystemVariant
	removeSystemVariantIDsFromSystem
	addClient removeClient changeClient
	setSystemIDsOfClient addSystemIDsToClient removeSystemIDsFromClient
	setGroupIDsOfClient addGroupIDsToClient removeGroupIDsFromClient
	addGroup removeGroup changeGroup
	setClientIDsOfGroup addClientIDsToGroup removeClientIDsFromGroup
	setSystemIDsOfGroup addSystemIDsToGroup removeSystemIDsFromGroup
	emptyDatabase
);

my @aggregationExports = qw(
	mergeDefaultAttributesIntoSystem
	mergeDefaultAndGroupAttributesIntoClient
	aggregatedSystemIDsOfClient aggregatedClientIDsOfSystem
	aggregatedSystemFileInfosOfSystem
);

my @supportExports = qw(
	isAttribute mergeAttributes
	externalIDForSystem externalIDForClient
	externalAttrName
);

@EXPORT = @accessExports;
@EXPORT_OK = (@manipulationExports, @aggregationExports, @supportExports);
%EXPORT_TAGS = (
	'access' => [ @accessExports ],
	'manipulation' => [ @manipulationExports ],
	'aggregation' => [ @aggregationExports ],
	'support' => [ @supportExports ],
);

################################################################################
### private stuff
################################################################################
use Carp;
use OpenSLX::Basics;
use OpenSLX::DBSchema;

sub _checkAndUpgradeDBSchemaIfNecessary
{
	my $metaDB = shift;

	vlog 2, "trying to determine schema version...";
	my $currVersion = $metaDB->schemaFetchDBVersion();
	if (!defined $currVersion) {
		# that's bad, someone has messed with our DB, as there is a
		# database, but the 'meta'-table is empty. There might still
		# be data in the other tables, but we have no way to find out
		# which schema version they're in. So it's safer to give up:
		croak _tr('Could not determine schema version of database');
	}

	if ($currVersion < $DbSchema->{version}) {
		vlog 1, _tr('Our schema-version is %s, DB is %s, upgrading DB...',
					$DbSchema->{version}, $currVersion);
		foreach my $v (sort { $a <=> $b } keys %DbSchemaHistory) {
			next if $v <= $currVersion;
			my $changeSet = $DbSchemaHistory{$v};
			foreach my $c (0..scalar(@$changeSet)-1) {
				my $changeDescr = @{$changeSet}[$c];
				my $cmd = $changeDescr->{cmd};
				if ($cmd eq 'add-table') {
					$metaDB->schemaAddTable($changeDescr->{'table'},
											$changeDescr->{'cols'},
											$changeDescr->{'vals'});
				} elsif ($cmd eq 'drop-table') {
					$metaDB->schemaDropTable($changeDescr->{'table'});
				} elsif ($cmd eq 'rename-table') {
					$metaDB->schemaRenameTable($changeDescr->{'old-table'},
											   $changeDescr->{'new-table'},
											   $changeDescr->{'cols'});
				} elsif ($cmd eq 'add-columns') {
					$metaDB->schemaAddColumns($changeDescr->{'table'},
											  $changeDescr->{'new-cols'},
											  $changeDescr->{'cols'});
				} elsif ($cmd eq 'drop-columns') {
					$metaDB->schemaDropColumns($changeDescr->{'table'},
											   $changeDescr->{'drop-cols'},
											   $changeDescr->{'cols'});
				} elsif ($cmd eq 'rename-columns') {
					$metaDB->schemaRenameColumns($changeDescr->{'table'},
												 $changeDescr->{'col-renames'},
												 $changeDescr->{'cols'});
				} else {
					confess _tr('UnknownDbSchemaCommand', $cmd);
				}
			}
		}
		vlog 1, _tr('upgrade done');
	} else {
		vlog 1, _tr('DB matches current schema version %s', $currVersion);
	}
}

sub _aref
{	# transparently converts the given reference to an array-ref
	my $ref = shift;
	return [] unless defined $ref;
	$ref = [ $ref ] unless ref($ref) eq 'ARRAY';
	return $ref;
}

sub _unique
{	# return given array filtered to unique elements
	my %seenIDs;
	return grep { !$seenIDs{$_}++; } @_;
}

sub _uniqueByKey
{	# return given array filtered to unique key elements
	my $key = shift;

	my %seenIDs;
	return grep { !$seenIDs{$_->{$key}}++; } @_;
}

################################################################################
### data access interface
################################################################################
sub connectConfigDB
{
	my $dbParams = shift;
		# hash-ref with any additional info that might be required by
		# specific metadb-module (not used yet)

	my $dbType = $openslxConfig{'db-type'};
		# name of underlying database module
	my $dbModule = "OpenSLX::MetaDB::$dbType";
	unless (eval "require $dbModule") {
		confess _tr('Unable to load DB-module <%s> (%s)', $dbModule, $@);
	}
	my $modVersion = $dbModule->VERSION;
	if ($modVersion < $VERSION) {
		confess _tr('Could not load module <%s> (Version <%s> required, but <%s> found)',
					$dbModule, $VERSION, $modVersion);
	}
	$dbModule->import;

	my $metaDB = $dbModule->new();
	$metaDB->connectConfigDB($dbParams);
	my $confDB = {
		'db-type' => $dbType,
		'meta-db' => $metaDB,
	};
	foreach my $tk (keys %{$DbSchema->{tables}}) {
		$metaDB->schemaDeclareTable($tk, $DbSchema->{tables}->{$tk});
	}

	_checkAndUpgradeDBSchemaIfNecessary($metaDB);

	return $confDB;
}

sub disconnectConfigDB
{
	my $confDB = shift;

	$confDB->{'meta-db'}->disconnectConfigDB();
}

sub fetchVendorOSesByFilter
{
	my $confDB = shift;
	my $filter = shift;
	my $resultCols = shift;

	my @vendorOSes
		= $confDB->{'meta-db'}->fetchVendorOSesByFilter($filter, $resultCols);
	return wantarray() ? @vendorOSes : shift @vendorOSes;
}

sub fetchVendorOSesByID
{
	my $confDB = shift;
	my $ids = _aref(shift);
	my $resultCols = shift;

	my @vendorOSes
		= $confDB->{'meta-db'}->fetchVendorOSesByID($ids, $resultCols);
	return wantarray() ? @vendorOSes : shift @vendorOSes;
}

sub fetchSystemsByFilter
{
	my $confDB = shift;
	my $filter = shift;
	my $resultCols = shift;

	my @systems
		= $confDB->{'meta-db'}->fetchSystemsByFilter($filter, $resultCols);
	return wantarray() ? @systems : shift @systems;
}

sub fetchSystemsByID
{
	my $confDB = shift;
	my $ids = _aref(shift);
	my $resultCols = shift;

	my @systems = $confDB->{'meta-db'}->fetchSystemsByID($ids, $resultCols);
	return wantarray() ? @systems : shift @systems;
}

sub fetchSystemIDsOfVendorOS
{
	my $confDB = shift;
	my $vendorOSID = shift;

	return $confDB->{'meta-db'}->fetchSystemIDsOfVendorOS($vendorOSID);
}

sub fetchSystemIDsOfClient
{
	my $confDB = shift;
	my $clientID = shift;

	return $confDB->{'meta-db'}->fetchSystemIDsOfClient($clientID);
}

sub fetchSystemIDsOfGroup
{
	my $confDB = shift;
	my $groupID = shift;

	return $confDB->{'meta-db'}->fetchSystemIDsOfGroup($groupID);
}

sub fetchSystemVariantsByFilter
{
	my $confDB = shift;
	my $filter = shift;
	my $resultCols = shift;

	my @systemVariants
		= $confDB->{'meta-db'}->fetchSystemVariantsByFilter($filter, $resultCols);
	return wantarray() ? @systemVariants : shift @systemVariants;
}

sub fetchSystemVariantsByID
{
	my $confDB = shift;
	my $ids = _aref(shift);
	my $resultCols = shift;

	my @systemVariants
		= $confDB->{'meta-db'}->fetchSystemVariantsByID($ids, $resultCols);
	return wantarray() ? @systemVariants : shift @systemVariants;
}

sub fetchSystemVariantIDsOfSystem
{
	my $confDB = shift;
	my $systemID = shift;

	return $confDB->{'meta-db'}->fetchSystemVariantIDsOfSystem($systemID);
}

sub fetchClientsByFilter
{
	my $confDB = shift;
	my $filter = shift;

	my @clients = $confDB->{'meta-db'}->fetchClientsByFilter($filter);
	return wantarray() ? @clients : shift @clients;
}

sub fetchClientsByID
{
	my $confDB = shift;
	my $ids = _aref(shift);
	my $resultCols = shift;

	my @clients = $confDB->{'meta-db'}->fetchClientsByID($ids, $resultCols);
	return wantarray() ? @clients : shift @clients;
}

sub fetchClientIDsOfSystem
{
	my $confDB = shift;
	my $systemID = shift;

	return $confDB->{'meta-db'}->fetchClientIDsOfSystem($systemID);
}

sub fetchClientIDsOfGroup
{
	my $confDB = shift;
	my $groupID = shift;

	return $confDB->{'meta-db'}->fetchClientIDsOfGroup($groupID);
}

sub fetchGroupsByFilter
{
	my $confDB = shift;
	my $filter = shift;
	my $resultCols = shift;

	my @groups
		= $confDB->{'meta-db'}->fetchGroupsByFilter($filter, $resultCols);
	return wantarray() ? @groups : shift @groups;
}

sub fetchGroupsByID
{
	my $confDB = shift;
	my $ids = _aref(shift);
	my $resultCols = shift;

	my @groups = $confDB->{'meta-db'}->fetchGroupsByID($ids, $resultCols);
	return wantarray() ? @groups : shift @groups;
}

sub fetchGroupIDsOfSystem
{
	my $confDB = shift;
	my $systemID = shift;

	return $confDB->{'meta-db'}->fetchGroupIDsOfSystem($systemID);
}

sub fetchGroupIDsOfClient
{
	my $confDB = shift;
	my $clientID = shift;

	return $confDB->{'meta-db'}->fetchGroupIDsOfClient($clientID);
}

################################################################################
### data manipulation interface
################################################################################
sub addVendorOS
{
	my $confDB = shift;
	my $valRows = _aref(shift);

	return $confDB->{'meta-db'}->addVendorOS($valRows);
}

sub removeVendorOS
{
	my $confDB = shift;
	my $vendorOSIDs = _aref(shift);

	return $confDB->{'meta-db'}->removeVendorOS($vendorOSIDs);
}

sub changeVendorOS
{
	my $confDB = shift;
	my $vendorOSIDs = _aref(shift);
	my $valRows = _aref(shift);

	return $confDB->{'meta-db'}->changeVendorOS($vendorOSIDs, $valRows);
}

sub addSystem
{
	my $confDB = shift;
	my $valRows = _aref(shift);

	return $confDB->{'meta-db'}->addSystem($valRows);
}

sub removeSystem
{
	my $confDB = shift;
	my $systemIDs = _aref(shift);

	foreach my $system (@$systemIDs) {
		setGroupIDsOfSystem($confDB, $system);
		setClientIDsOfSystem($confDB, $system);
	}

	return $confDB->{'meta-db'}->removeSystem($systemIDs);
}

sub changeSystem
{
	my $confDB = shift;
	my $systemIDs = _aref(shift);
	my $valRows = _aref(shift);

	return $confDB->{'meta-db'}->changeSystem($systemIDs, $valRows);
}

sub setClientIDsOfSystem
{
	my $confDB = shift;
	my $systemID = shift;
	my $clientIDs = _aref(shift);

	my @uniqueClientIDs = _unique(@$clientIDs);
	return $confDB->{'meta-db'}->setClientIDsOfSystem($systemID,
													  \@uniqueClientIDs);
}

sub addClientIDsToSystem
{
	my $confDB = shift;
	my $systemID = shift;
	my $newClientIDs = _aref(shift);

	my @clientIDs = $confDB->{'meta-db'}->fetchClientIDsOfSystem($systemID);
	push @clientIDs, @$newClientIDs;
	return setClientIDsOfSystem($confDB, $systemID, \@clientIDs);
}

sub removeClientIDsFromSystem
{
	my $confDB = shift;
	my $systemID = shift;
	my $removedClientIDs = _aref(shift);

	my %toBeRemoved;
	@toBeRemoved{@$removedClientIDs} = ();
	my @clientIDs
		= grep { !exists $toBeRemoved{$_} }
			   $confDB->{'meta-db'}->fetchClientIDsOfSystem($systemID);
	return setClientIDsOfSystem($confDB, $systemID, \@clientIDs);
}

sub setGroupIDsOfSystem
{
	my $confDB = shift;
	my $systemID = shift;
	my $groupIDs = _aref(shift);

	my @uniqueGroupIDs = _unique(@$groupIDs);
	return $confDB->{'meta-db'}->setGroupIDsOfSystem($systemID,
													 \@uniqueGroupIDs);
}

sub addGroupIDsToSystem
{
	my $confDB = shift;
	my $systemID = shift;
	my $newGroupIDs = _aref(shift);

	my @groupIDs = $confDB->{'meta-db'}->fetchGroupIDsOfSystem($systemID);
	push @groupIDs, @$newGroupIDs;
	return setGroupIDsOfSystem($confDB, $systemID, \@groupIDs);
}

sub removeGroupIDsFromSystem
{
	my $confDB = shift;
	my $systemID = shift;
	my $toBeRemovedGroupIDs = _aref(shift);

	my %toBeRemoved;
	@toBeRemoved{@$toBeRemovedGroupIDs} = ();
	my @groupIDs
		= grep { !exists $toBeRemoved{$_} }
			   $confDB->{'meta-db'}->fetchGroupIDsOfSystem($systemID);
	return setGroupIDsOfSystem($confDB, $systemID, \@groupIDs);
}

sub addSystemVariant
{
	my $confDB = shift;
	my $valRows = _aref(shift);

	return $confDB->{'meta-db'}->addSystemVariant($valRows);
}

sub removeSystemVariant
{
	my $confDB = shift;
	my $systemVariantIDs = _aref(shift);

	return $confDB->{'meta-db'}->removeSystemVariant($systemVariantIDs);
}

sub changeSystemVariant
{
	my $confDB = shift;
	my $systemVariantIDs = _aref(shift);
	my $valRows = _aref(shift);

	return $confDB->{'meta-db'}->changeSystemVariant($systemVariantIDs, $valRows);
}

sub addClient
{
	my $confDB = shift;
	my $valRows = _aref(shift);

	return $confDB->{'meta-db'}->addClient($valRows);
}

sub removeClient
{
	my $confDB = shift;
	my $clientIDs = _aref(shift);

	foreach my $client (@$clientIDs) {
		setGroupIDsOfClient($confDB, $client);
		setSystemIDsOfClient($confDB, $client);
	}

	return $confDB->{'meta-db'}->removeClient($clientIDs);
}

sub changeClient
{
	my $confDB = shift;
	my $clientIDs = _aref(shift);
	my $valRows = _aref(shift);

	return $confDB->{'meta-db'}->changeClient($clientIDs, $valRows);
}

sub setSystemIDsOfClient
{
	my $confDB = shift;
	my $clientID = shift;
	my $systemIDs = _aref(shift);

	my @uniqueSystemIDs = _unique(@$systemIDs);
	return $confDB->{'meta-db'}->setSystemIDsOfClient($clientID,
													   \@uniqueSystemIDs);
}

sub addSystemIDsToClient
{
	my $confDB = shift;
	my $clientID = shift;
	my $newSystemIDs = _aref(shift);

	my @systemIDs = $confDB->{'meta-db'}->fetchSystemIDsOfClient($clientID);
	push @systemIDs, @$newSystemIDs;
	return setSystemIDsOfClient($confDB, $clientID, \@systemIDs);
}

sub removeSystemIDsFromClient
{
	my $confDB = shift;
	my $clientID = shift;
	my $removedSystemIDs = _aref(shift);

	my %toBeRemoved;
	@toBeRemoved{@$removedSystemIDs} = ();
	my @systemIDs
		= grep { !exists $toBeRemoved{$_} }
			   $confDB->{'meta-db'}->fetchSystemIDsOfClient($clientID);
	return setSystemIDsOfClient($confDB, $clientID, \@systemIDs);
}

sub setGroupIDsOfClient
{
	my $confDB = shift;
	my $clientID = shift;
	my $groupIDs = _aref(shift);

	my @uniqueGroupIDs = _unique(@$groupIDs);
	return $confDB->{'meta-db'}->setGroupIDsOfClient($clientID,
													 \@uniqueGroupIDs);
}

sub addGroupIDsToClient
{
	my $confDB = shift;
	my $clientID = shift;
	my $newGroupIDs = _aref(shift);

	my @groupIDs = $confDB->{'meta-db'}->fetchGroupIDsOfClient($clientID);
	push @groupIDs, @$newGroupIDs;
	return setGroupIDsOfClient($confDB, $clientID, \@groupIDs);
}

sub removeGroupIDsFromClient
{
	my $confDB = shift;
	my $clientID = shift;
	my $toBeRemovedGroupIDs = _aref(shift);

	my %toBeRemoved;
	@toBeRemoved{@$toBeRemovedGroupIDs} = ();
	my @groupIDs
		= grep { !exists $toBeRemoved{$_} }
			   $confDB->{'meta-db'}->fetchGroupIDsOfClient($clientID);
	return setGroupIDsOfClient($confDB, $clientID, \@groupIDs);
}

sub addGroup
{
	my $confDB = shift;
	my $valRows = _aref(shift);

	return $confDB->{'meta-db'}->addGroup($valRows);
}

sub removeGroup
{
	my $confDB = shift;
	my $groupIDs = _aref(shift);

	foreach my $group (@$groupIDs) {
		setSystemIDsOfGroup($confDB, $group, []);
		setClientIDsOfGroup($confDB, $group, []);
	}

	return $confDB->{'meta-db'}->removeGroup($groupIDs);
}

sub changeGroup
{
	my $confDB = shift;
	my $groupIDs = _aref(shift);
	my $valRows = _aref(shift);

	return $confDB->{'meta-db'}->changeGroup($groupIDs, $valRows);
}

sub setClientIDsOfGroup
{
	my $confDB = shift;
	my $groupID = shift;
	my $clientIDs = _aref(shift);

	my @uniqueClientIDs = _unique(@$clientIDs);
	return $confDB->{'meta-db'}->setClientIDsOfGroup($groupID,
													 \@uniqueClientIDs);
}

sub addClientIDsToGroup
{
	my $confDB = shift;
	my $groupID = shift;
	my $newClientIDs = _aref(shift);

	my @clientIDs = $confDB->{'meta-db'}->fetchClientIDsOfGroup($groupID);
	push @clientIDs, @$newClientIDs;
	return setClientIDsOfGroup($confDB, $groupID, \@clientIDs);
}

sub removeClientIDsFromGroup
{
	my $confDB = shift;
	my $groupID = shift;
	my $removedClientIDs = _aref(shift);

	my %toBeRemoved;
	@toBeRemoved{@$removedClientIDs} = ();
	my @clientIDs
		= grep { !exists $toBeRemoved{$_} }
			   $confDB->{'meta-db'}->fetchClientIDsOfGroup($groupID);
	return setClientIDsOfGroup($confDB, $groupID, \@clientIDs);
}

sub setSystemIDsOfGroup
{
	my $confDB = shift;
	my $groupID = shift;
	my $systemIDs = _aref(shift);

	my @uniqueSystemIDs = _unique(@$systemIDs);
	return $confDB->{'meta-db'}->setSystemIDsOfGroup($groupID,
													  \@uniqueSystemIDs);
}

sub addSystemIDsToGroup
{
	my $confDB = shift;
	my $groupID = shift;
	my $newSystemIDs = _aref(shift);

	my @systemIDs = $confDB->{'meta-db'}->fetchSystemIDsOfGroup($groupID);
	push @systemIDs, @$newSystemIDs;
	return setSystemIDsOfGroup($confDB, $groupID, \@systemIDs);
}

sub removeSystemIDsFromGroup
{
	my $confDB = shift;
	my $groupID = shift;
	my $removedSystemIDs = _aref(shift);

	my %toBeRemoved;
	@toBeRemoved{@$removedSystemIDs} = ();
	my @systemIDs
		= grep { !exists $toBeRemoved{$_} }
			   $confDB->{'meta-db'}->fetchSystemIDsOfGroup($groupID);
	return setSystemIDsOfGroup($confDB, $groupID, \@systemIDs);
}

sub emptyDatabase
{	# clears all user-data from the database
	my $confDB = shift;

	my @groupIDs
		= map { $_->{id} }
		  fetchGroupsByFilter($confDB);
	removeGroup($confDB, \@groupIDs);

	my @clientIDs
		= map { $_->{id} }
		  grep { $_->{id} > 0 }
		  fetchClientsByFilter($confDB);
	removeClient($confDB, \@clientIDs);

	my @sysVarIDs
		= map { $_->{id} }
		  grep { $_->{id} > 0 }
		  fetchSystemVariantsByFilter($confDB);
	removeSystemVariant($confDB, \@sysVarIDs);

	my @sysIDs
		= map { $_->{id} }
		  grep { $_->{id} > 0 }
		  fetchSystemsByFilter($confDB);
	removeSystem($confDB, \@sysIDs);

	my @vendorOSIDs
		= map { $_->{id} }
		  grep { $_->{id} > 0 }
		  fetchVendorOSesByFilter($confDB);
	removeVendorOS($confDB, \@vendorOSIDs);
}

################################################################################
### data aggregation interface
################################################################################
sub mergeDefaultAttributesIntoSystem
{	# merge default system configuration into given system
	my $confDB = shift;
	my $system = shift;
	my $defaultSystem = shift;

	$defaultSystem = fetchSystemsByID($confDB, 0)
		unless defined $defaultSystem;

	mergeAttributes($system, $defaultSystem);
}

sub mergeDefaultAndGroupAttributesIntoClient
{	# merge default and group configurations into given client
	my $confDB = shift;
	my $client = shift;

	# step over all groups this client belongs to
	# (ordered by priority from highest to lowest):
	my @groupIDs = fetchGroupIDsOfClient($confDB, $client->{id});
	my @groups = sort { $b->{priority} <=> $a->{priority} }
				 fetchGroupsByID($confDB, \@groupIDs);
	foreach my $group (@groups) {
		# merge configuration from this group into the current client:
		vlog 3, _tr('merging from group %d:%s...', $group->{id}, $group->{name});
		mergeAttributes($client, $group);
	}

	# merge configuration from default client:
	vlog 3, _tr('merging from default client...');
	my $defaultClient = fetchClientsByID($confDB, 0);
	mergeAttributes($client, $defaultClient);
}

sub aggregatedSystemIDsOfClient
{	# return aggregated list of system-IDs this client should offer
	# (as indicated by itself, the default client and the client's groups)
	my $confDB = shift;
	my $client = shift;

	# add all systems directly linked to client:
	my @systemIDs = fetchSystemIDsOfClient($confDB, $client->{id});

	# step over all groups this client belongs to:
	my @groupIDs = fetchGroupIDsOfClient($confDB, $client->{id});
	my @groups = fetchGroupsByID($confDB, \@groupIDs);
	foreach my $group (@groups) {
		# add all systems that the client inherits from the current group:
		push @systemIDs, fetchSystemIDsOfGroup($confDB, $group->{id});
	}

	# add all systems inherited from default client
	push @systemIDs, fetchSystemIDsOfClient($confDB, 0);

	return _unique(@systemIDs);
}

sub aggregatedClientIDsOfSystem
{	# return aggregated list of client-IDs this system is linked to
	# (as indicated by itself, the default system and the system's groups)
	my $confDB = shift;
	my $system = shift;

	# add all clients directly linked to system:
	my @clientIDs = fetchClientIDsOfSystem($confDB, $system->{id});

	# step over all groups this system belongs to:
	my @groupIDs = fetchGroupIDsOfSystem($confDB, $system->{id});
	my @groups = fetchGroupsByID($confDB, \@groupIDs);
	foreach my $group (@groups) {
		# add all clients that the system inherits from the current group:
		push @clientIDs, fetchClientIDsOfGroup($confDB, $group->{id});
	}

	# add all clients inherited from default system
	push @clientIDs, fetchClientIDsOfSystem($confDB, 0);

	return _unique(@clientIDs);
}

sub aggregatedSystemFileInfosOfSystem
{	# return aggregated list of hash-refs that contain information about
	# the kernel- and initialramfs-files this system is using
	# (as indicated by itself and the system's variants)
	my $confDB = shift;
	my $system = shift;

	my $vendorOS = fetchVendorOSesByID($confDB, $system->{vendor_os_id});
	return () if !$vendorOS || !length($vendorOS->{path});
	my $kernelPath
		= "$openslxConfig{'private-path'}/stage1/$vendorOS->{path}";

	my $exportURI = $system->{'export_uri'};
	if ($exportURI !~ m[\w]) {
		# auto-generate export_uri if none has been given:
		my $type = $system->{'export_type'};
		my $serverIpToken = '@@@server_ip@@@';
		$exportURI
			= "$type://$serverIpToken$openslxConfig{'export-path'}/$type/$vendorOS->{path}";
	}

	my @variantIDs = fetchSystemVariantIDsOfSystem($confDB, $system->{id});
	my @variants = fetchSystemVariantsByID($confDB, \@variantIDs);

	my @infos;
	foreach my $sys ($system, @variants) {
		next if !length($sys->{kernel});
		my %info = %$sys;
		$info{'kernel-file'} = "$kernelPath/$sys->{kernel}";
		$info{'export-uri'} = $exportURI;
		if (!defined $info{'name'}) {
			# compose full name and label for system-variant:
			$info{'name'} = "$system->{name}-$info{name_addition}";
			$info{'label'} = "$system->{label} $info{label_addition}";
		}
		push @infos, \%info;
	}
	return _uniqueByKey('name', @infos);
}

################################################################################
### support interface
################################################################################
sub isAttribute
{	# returns whether or not the given key is an exportable attribute
	my $key = shift;

	return $key =~ m[^attr];
}

sub mergeAttributes
{	# copies all attributes of source that are unset in target over
	my $target = shift;
	my $source = shift;

	foreach my $key (grep { isAttribute($_) } keys %$source) {
		if (length($source->{$key}) > 0 && length($target->{$key}) == 0) {
			vlog 3, _tr("merging %s (val=%s)", $key, $source->{$key});
			$target->{$key} = $source->{$key};
		}
	}
}

sub externalIDForSystem
{
	my $system = shift;

	return "default" if $system->{id} == 0;

	my $externalID = $system->{name};
	$externalID =~ s[\s+][_]g;
		# replace any whitespace in name, such that the external ID can
		# be used as a directory name (without complications)
	return $externalID;
}


sub externalIDForClient
{
	my $client = shift;

	return "default" if $client->{id} == 0;

	my $mac = lc($client->{mac});
		# PXE seems to expect MACs being all lowercase
	$mac =~ tr[:][-];
	return "01-$mac";
}

sub externalAttrName
{
	my $attr = shift;
	return substr($attr, 5);
}

1;
