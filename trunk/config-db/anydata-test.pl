#! /usr/bin/perl

use DBI;

my $dbh = DBI->connect("dbi:AnyData(PrintError => 0):")
		or die "no connect";

mkdir "datafiles-test";

my $dbPath = '/home/zooey/Sources/odlx/config-db/datafiles-sqlite';

  my $dbh = DBI->connect('dbi:AnyData:(RaiseError=>1)');
  $dbh->func(
      'test',
      'DBI',
      DBI->connect("dbi:SQLite:dbname=$dbPath/odlx", undef, undef),
      {sql=>"SELECT * FROM meta"},
	  'ad_import');

$dbh->func( 'test', 'CSV', 'xxx',
				{ col_map => [ 'schema_version', 'next_system_id', 'next_client_id' ],
				  'pretty_print' => 'indented' },
				'ad_export');

#print $dbh->func( 'test', 'XML', 'ad_export');

$dbh->disconnect;