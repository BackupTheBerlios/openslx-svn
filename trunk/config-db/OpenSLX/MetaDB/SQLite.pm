package OpenSLX::MetaDB::SQLite;

use vars qw(@ISA $VERSION);
@ISA = ('OpenSLX::MetaDB::DBI');
$VERSION = 1.01;		# API-version . implementation-version

################################################################################
### This class provides a MetaDB backend for SQLite databases.
### - by default the db will be created inside a 'openslxdata-sqlite' directory.
################################################################################
use strict;
use Carp;
use OpenSLX::Basics;
use OpenSLX::MetaDB::DBI $VERSION;

my $superVersion = $OpenSLX::MetaDB::DBI::VERSION;
if ($superVersion < $VERSION) {
	confess _tr('Unable to load module <%s> (Version <%s> required, but <%s> found)',
				'OpenSLX::MetaDB::DBI', $VERSION, $superVersion);
}

################################################################################
### implementation
################################################################################
sub new
{
	my $class = shift;
	my $self = {};
	return bless $self, $class;
}

sub connectConfigDB
{
	my $self = shift;

	my $dbSpec = $openslxConfig{'db-spec'};
	if (!defined $dbSpec) {
		# build $dbSpec from individual parameters:
		my $dbBasepath = $openslxConfig{'db-basepath'};
		my $dbDatadir = $openslxConfig{'db-datadir'} || 'openslxdata-sqlite';
		my $dbPath = "$dbBasepath/$dbDatadir";
		mkdir $dbPath unless -e $dbPath;
		my $dbName = $openslxConfig{'db-name'};
		$dbSpec = "dbname=$dbPath/$dbName";
	}
	vlog 1, "trying to connect to SQLite-database <$dbSpec>";
	$self->{'dbh'} = DBI->connect("dbi:SQLite:$dbSpec", undef, undef,
								  {PrintError => 0})
			or confess _tr("Cannot connect to database <%s> (%s)"),
						   $dbSpec, $DBI::errstr;
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
	foreach my $colDescr (@$newColDescrs) {
		my $colDescrString
			= $self->_convertColDescrsToDBNativeString([$colDescr]);
		my $sql = "ALTER TABLE $table ADD COLUMN $colDescrString";
		vlog 3, $sql;
		$dbh->do($sql)
			or confess _tr(q[Can't add column to table <%s> (%s)], $table,
						   $dbh->errstr);
	}
	# if default values have been provided, we apply them now:
	if (defined $newColDefaultVals) {
		$self->_doUpdate($table, undef, $newColDefaultVals);
	}
}

1;