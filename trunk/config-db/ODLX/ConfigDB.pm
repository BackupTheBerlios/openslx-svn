package ODLX::ConfigDB;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);
$VERSION = 1.01;		# API-version . implementation-version

################################################################################
### This module defines the data abstraction layer for the ODLX configuration
### database.
### Aim of this abstraction is to hide the details of the data layout and
### the peculiarities of individual database types behind a simple interface
### that offers straightforward access to and manipulation of the ODLX-systems
### and -clients (without the need to use SQL).
### The interface is divided into two parts:
### 	- data access methods (getting data)
### 	- data manipulation methods (adding, removing and changing data)
################################################################################
use Exporter;
@ISA = qw(Exporter);

my @accessExports = qw(
	connectConfigDB disconnectConfigDB
	fetchSystemsByFilter fetchSystemsById fetchAllSystemsOfClient
	fetchClientsByFilter fetchClientsById fetchAllClientsForSystem
);
my @manipulationExports = qw(
	addSystem removeSystem changeSystem
	addClient removeClient changeClient
);

@EXPORT = @accessExports;
@EXPORT_OK = @manipulationExports;
%EXPORT_TAGS = (
	'access' => [ @accessExports ],
	'manipulation' => [ @manipulationExports ],
);

################################################################################
### private stuff
################################################################################
use Carp;
use ODLX::Basics;
use ODLX::DBSchema;

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
	$ref = [ $ref ] unless ref($ref) eq 'ARRAY';
	return $ref;
}

################################################################################
### data access interface
################################################################################
sub connectConfigDB
{
	my $dbParams = shift;
		# hash-ref with any additional info that might be required by
		# specific metadb-module (not used yet)

	my $dbType = $odlxConfig{'db-type'};
		# name of underlying database module
	my $dbModule = "ODLX::MetaDB::$dbType";
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

sub fetchSystemsByFilter
{
	my $confDB = shift;
	my $filter = shift;
	my $resultCols = shift;

	my @systems
		= $confDB->{'meta-db'}->fetchSystemsByFilter($filter, $resultCols);
	return wantarray() ? @systems : shift @systems;
}

sub fetchSystemsById
{
	my $confDB = shift;
	my $id = shift;

	my $filter = { 'id' => $id };
	my @systems = $confDB->{'meta-db'}->fetchSystemsByFilter($filter);
	return wantarray() ? @systems : shift @systems;
}

sub fetchAllSystemIDsForClient
{
	my $confDB = shift;
	my $clientID = shift;

	my @systemIDs = $confDB->{'meta-db'}->fetchAllSystemIDsOfClient($clientID);
	return @systemIDs;
}

sub fetchClientsByFilter
{
	my $confDB = shift;
	my $filter = shift;

	my @clients = $confDB->{'meta-db'}->fetchClientsByFilter($filter);
	return wantarray() ? @clients : shift @clients;
}

sub fetchClientsById
{
	my $confDB = shift;
	my $id = shift;

	my $filter = { 'id' => $id };
	my @clients = $confDB->{'meta-db'}->fetchClientsByFilter($filter);
	return wantarray() ? @clients : shift @clients;
}

sub fetchAllClientIDsForSystem
{
	my $confDB = shift;
	my $systemID = shift;

	my @clientIDs = $confDB->{'meta-db'}->fetchAllClientIDsOfSystem($systemID);
	return @clientIDs;
}

################################################################################
### data manipulation interface
################################################################################
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

	return $confDB->{'meta-db'}->removeSystem($systemIDs);
}

sub changeSystem
{
	my $confDB = shift;
	my $systemIDs = _aref(shift);
	my $valRows = _aref(shift);

	return $confDB->{'meta-db'}->changeSystem($systemIDs, $valRows);
}

sub setClientIDsForSystem
{
	my $confDB = shift;
	my $systemID = shift;
	my $clientIDs = _aref(shift);

	my %seen;
	my @uniqueClientIDs = grep { !$seen{$_}++ } @$clientIDs;
	return $confDB->{'meta-db'}->setClientIDsForSystem($systemID,
													   \@uniqueClientIDs);
}

sub addClientIDsToSystem
{
	my $confDB = shift;
	my $systemID = shift;
	my $newClientIDs = _aref(shift);

	my @clientIDs
		= $confDB->{'meta-db'}->fetchAllClientIDsOfSystem($systemID);
	push @clientIDs, @$newClientIDs;
	return setClientIDsForSystem($confDB, $systemID, \@clientIDs);
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
		  $confDB->{'meta-db'}->fetchAllClientIDsOfSystem($systemID);
	return setClientIDsForSystem($confDB, $systemID, \@clientIDs);
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

	return $confDB->{'meta-db'}->removeClient($clientIDs);
}

sub changeClient
{
	my $confDB = shift;
	my $clientIDs = _aref(shift);
	my $valRows = _aref(shift);

	return $confDB->{'meta-db'}->changeClient($clientIDs, $valRows);
}

sub setSystemIDsForClient
{
	my $confDB = shift;
	my $clientID = shift;
	my $systemIDs = _aref(shift);

	my %seen;
	my @uniqueSystemIDs = grep { !$seen{$_}++ } @$systemIDs;
	return $confDB->{'meta-db'}->setSystemIDsForClient($clientID,
													   \@uniqueSystemIDs);
}

sub addSystemIDsToClient
{
	my $confDB = shift;
	my $clientID = shift;
	my $newSystemIDs = _aref(shift);

	my @systemIDs
		= $confDB->{'meta-db'}->fetchAllSystemIDsForClient($clientID);
	push @systemIDs, @$newSystemIDs;
	return setSystemIDsForClient($confDB, $clientID, \@systemIDs);
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
		  $confDB->{'meta-db'}->fetchAllSystemIDsForClient($clientID);
	return setSystemIDsForClient($confDB, $clientID, \@systemIDs);
}

1;
