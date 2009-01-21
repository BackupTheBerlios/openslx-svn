# CSV.pm - provides CSV-specific overrides of the OpenSLX MetaDB API.
#
# (c) 2006 - OpenSLX.com
#
# Oliver Tappe <ot@openslx.com>
#
package OpenSLX::MetaDB::CSV;

use vars qw(@ISA $VERSION);
@ISA = ('OpenSLX::MetaDB::DBI');
$VERSION = 1.01;		# API-version . implementation-version

################################################################################
### This class provides a MetaDB backend for CSV files (CSV = comma separated
### files).
### - each table will be stored into a CSV file.
### - by default all files will be created inside a 'openslxdata-csv' directory.
################################################################################
use strict;
use Carp;
use Fcntl qw(:DEFAULT :flock);
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
		my $dbDatadir = $openslxConfig{'db-datadir'}
						|| "$openslxConfig{'db-name'}-csv";
		my $dbPath = "$dbBasepath/$dbDatadir";
		mkdir $dbPath unless -e $dbPath;
		$dbSpec = "f_dir=$dbPath";
	}
	vlog 1, "trying to connect to CSV-database <$dbSpec>";
	eval ('require DBD::CSV; 1;')
		or die _tr(qq[%s doesn't seem to be installed,
so there is no support for %s available, sorry!\n], 'DBI::CSV', 'CSV');
	$self->{'dbh'} = DBI->connect("dbi:CSV:$dbSpec", undef, undef,
								  {PrintError => 0})
			or confess _tr("Cannot connect to database <%s> (%s)",
						   $dbSpec, $DBI::errstr);
}

sub quote
{	# DBD::CSV has a buggy quoting mechanism which can't cope with backslashes
	# so we reimplement the quoting ourselves...
	my $self = shift;
	my $val = shift;

	$val =~ s[(['])][\\$1]go;
	return "'$val'";
}

sub generateNextIdForTable
{	# CSV doesn't provide any mechanism to generate IDs, we just...
	my $self = shift;
	my $table = shift;

	return 1 unless defined $table;

	# now fetch the next ID from a table-specific file:
	my $dbh = $self->{'dbh'};
	my $idFile = "$dbh->{'f_dir'}/id-$table";
	sysopen(IDFILE, $idFile, O_RDWR|O_CREAT)
		or confess _tr(q[Can't open ID-file <%s> (%s)], $idFile, $!);
	flock(IDFILE, LOCK_EX)
		or confess _tr(q[Can't lock ID-file <%s> (%s)], $idFile, $!);
	my $nextID = <IDFILE>;
	if (!$nextID) {
		# no ID information available, we protect against users having
		# deleted the ID-file by fetching the highest ID from the DB:
		$nextID = 1+$self->_doSelect("SELECT max(id) AS id FROM $table", 'id');
	}
	seek(IDFILE, 0, 0)
		or confess _tr(q[Can't to seek ID-file <%s> (%s)], $idFile, $!);
	truncate(IDFILE, 0)
		or confess _tr(q[Can't truncate ID-file <%s> (%s)], $idFile, $!);
	print IDFILE $nextID+1
		or confess _tr(q[Can't update ID-file <%s> (%s)], $idFile, $!);
	close(IDFILE);

	return $nextID;
}

sub schemaDeclareTable
{	# explicitly set file name for each table such that it makes
	# use of '.csv'-extension
	my $self = shift;
	my $table = shift;

	my $dbh = $self->{'dbh'};
	$dbh->{'csv_tables'}->{"$table"} = { 'file' => "${table}.csv"};
}

sub schemaRenameTable
{	# renames corresponding id-file after renaming the table
	my $self = shift;
	my $oldTable = shift;
	my $newTable = shift;

	$self->schemaDeclareTable($newTable);
	$self->SUPER::schemaRenameTable($oldTable, $newTable, @_);
	my $dbh = $self->{'dbh'};
	rename "$dbh->{'f_dir'}/id-$oldTable", "$dbh->{'f_dir'}/id-$newTable";
}

sub schemaDropTable
{	# removes corresponding id-file after dropping the table
	my $self = shift;
	my $table = shift;

	$self->SUPER::schemaDropTable($table, @_);
	my $dbh = $self->{'dbh'};
	unlink "$dbh->{'f_dir'}/id-$table";
}

1;