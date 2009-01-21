package ODLX::MetaDB::XML;

use strict;
use vars qw(@ISA @EXPORT $VERSION);

use Exporter;
$VERSION = 0.02;
@ISA = qw(Exporter);

@EXPORT = qw(
	&metaConnectConfigDB &metaDisconnectConfigDB
	&metaAddSystem
	&metaFetchDBSchemaVersion &metaSchemaAddTable &metaSchemaDeclareTable
);

################################################################################
### private stuff required by this module
################################################################################
use Carp;
use DBI;
use ODLX::Base;

################################################################################
### basics
################################################################################
sub metaConnectConfigDB
{
	my $dbParams = shift;

	my $dbPath = $dbParams->{'db-path'}
				 || '/home/zooey/Sources/odlx/config-db/datafiles-xml';
	mkdir $dbPath;
	vlog 1, "trying to connect to XML-database <$dbPath>";
	my $dbh = DBI->connect("dbi:AnyData:",
						   undef, undef,
						   {PrintError => 0})
		or confess _tr("Cannot connect to database <%s> (%s)"),
					   $dbPath, $DBI::errstr;
	my $metaDB = {
		'db-path' => $dbPath,
		'dbi-dbh' => $dbh,
	};
	return $metaDB;
}

sub metaDisconnectConfigDB
{
	my $metaDB = shift;

	my $dbh = $metaDB->{'dbi-dbh'};

	$dbh->disconnect;
}

################################################################################
### data access functions
################################################################################

sub metaFetchSystemsById
{
}

################################################################################
### data manipulation functions
################################################################################

sub metaDoInsert
{
	my $metaDB = shift;
	my $table = shift;
	my $valRows = shift;

	my $dbh = $metaDB->{'dbi-dbh'};
	my $valRow = (@$valRows)[0];
	return if !defined $valRow;
	my $cols = join ', ', keys %$valRow;
print "cols: $cols\n";
	my $placeholders = join ', ', map { '?' } keys %$valRow;
	my $sql = "INSERT INTO $table ( $cols ) VALUES ( $placeholders )";
	my $sth = $dbh->prepare($sql)
		or confess _tr("Cannot insert into table <%s> (%s)", $table, $dbh->errstr);
	foreach my $valRow (@$valRows) {
		vlog 3, $sql;
my $vals = join ', ', values %$valRow;
print "vals: $vals\n";
		$sth->execute(values %$valRow)
			or confess _tr("Cannot insert into table <%s> (%s)",
							$table, $dbh->errstr);
	}

}

sub metaAddSystem
{
	my $metaDB = shift;
	my $valRows = shift;

	metaDoInsert($metaDB, 'system', $valRows);
}

################################################################################
### schema related functions
################################################################################
sub metaFetchDBSchemaVersion
{
	my $metaDB = shift;

	my $dbh = $metaDB->{'dbi-dbh'};
	local $dbh->{RaiseError} = 0;
	my $sth = $dbh->prepare('SELECT schema_version FROM meta')
		or return 0;
	my $row = $sth->fetchrow_hashref();
	return 0 unless defined $row;
		# no entry in meta-table
	return $row->{schema_version};
}

sub metaSchemaConvertTypeDescrToNative
{
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

sub metaSchemaDeclareTable
{
	my $metaDB = shift;
	my $table = shift;
	my $colDescrs = shift;

	my $dbh = $metaDB->{'dbi-dbh'};
	my $dbPath = $metaDB->{'db-path'};
	my @colNames = map { my $col = $_; $col =~ s[:.+$][]; $col } @$colDescrs;
	my $cols = join(', ', @colNames);
	vlog 2, "declaring table <$table> as ($cols)...";
	$dbh->func( $table, 'XML', "$dbPath/${table}.xml",
				{ 'col_map' => [ @colNames ], 'pretty_print' => 'indented' },
				'ad_catalog');
}

sub metaSchemaAddTable
{
	my $metaDB = shift;
	my $changeDescr = shift;

	my $dbh = $metaDB->{'dbi-dbh'};
	my $table = $changeDescr->{table};
	vlog 2, "adding table <$table> to schema...";
	my $cols =
		join ', ',
		map {
			# convert each column description into database native format
			# (e.g. convert 'name:s.45' to 'name char(45)'):
			if (!m[^\s*(\S+)\s*:\s*(\S+)\s*$]) {
				confess _tr('UnknownDbSchemaColumnDescr', $_);
			}
			"$1 ".metaSchemaConvertTypeDescrToNative($2);
		}
		@{$changeDescr->{cols}};
	my $sql = "CREATE TABLE $changeDescr->{table} ($cols)";
	vlog 3, $sql;
	$dbh->do($sql)
		or confess _tr("Cannot create table <%s> (%s)", $table, $dbh->errstr);
	if (exists $changeDescr->{vals}) {
		metaDoInsert($metaDB, $table, $changeDescr->{vals});
	}

print "exporting...\n";
	$dbh->func( $table, 'XML', "$metaDB->{'db-path'}/$table.xml",
				{'pretty_print' => 'indented'}, 'ad_export');
print "exporting done\n";
}

1;