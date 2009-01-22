#!/usr/bin/perl

use warnings;
use strict;

use Test::Harness;

# add the development paths to perl's search path for modules:
use FindBin;
use lib "$FindBin::RealBin/../";
use lib "$FindBin::RealBin/../../lib";

chdir "$FindBin::RealBin" or die "unable to chdir to $FindBin::RealBin! ($!)\n";

use OpenSLX::Basics;

use OpenSLX::MetaDB::SQLite;

# make sure a specific test-db will be used
$cmdlineConfig{'private-path'} = $ENV{SLX_PRIVATE_PATH} = '/tmp/slx-db-test';
$cmdlineConfig{'db-name'}      = $ENV{SLX_DB_NAME}      = 'slx-test';
$cmdlineConfig{'db-type'}      = $ENV{SLX_DB_TYPE}      = 'SQLite';

openslxInit();

$Test::Harness::Verbose = 1 if $openslxConfig{'verbose-level'};

# remove the test-db if it already exists 
my $metaDB = OpenSLX::MetaDB::SQLite->new();
if ($metaDB->databaseExists()) {
	print "removing leftovers of slx-test-db\n";
	$metaDB->dropDatabase();
}
runtests(glob("*.t"));

$metaDB->dropDatabase();
