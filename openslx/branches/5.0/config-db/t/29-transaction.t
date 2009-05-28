use Test::More qw(no_plan);

use strict;
use warnings;

use lib '/opt/openslx/lib';

# basic init
use OpenSLX::ConfigDB;

my $configDB = OpenSLX::ConfigDB->new;
$configDB->connect();

my @vendorOSes = $configDB->fetchVendorOSByFilter();
my @exports    = $configDB->fetchExportByFilter();
my @systems    = $configDB->fetchSystemByFilter();
my @clients    = $configDB->fetchClientByFilter();
my @groups     = $configDB->fetchGroupByFilter();

ok($configDB->startTransaction(), 'starting a transaction');

ok($configDB->emptyDatabase(), 'emptying the DB');

ok($configDB->rollbackTransaction(), 'rolling back the transaction');

my @vendorOSes2 = $configDB->fetchVendorOSByFilter();
my @exports2    = $configDB->fetchExportByFilter();
my @systems2    = $configDB->fetchSystemByFilter();
my @clients2    = $configDB->fetchClientByFilter();
my @groups2     = $configDB->fetchGroupByFilter();

is( 
    scalar @vendorOSes2, scalar @vendorOSes, "should still have all vendor-OSes"
);
is(scalar @exports2, scalar @exports, "should still have all exports");
is(scalar @systems2, scalar @systems, "should still have all systems");
is(scalar @clients2, scalar @clients, "should still have all clients");
is(scalar @groups2, scalar @groups, "should still have all groups");

ok($configDB->startTransaction(), 'starting a transaction');

ok($configDB->emptyDatabase(), 'emptying the DB');

ok($configDB->commitTransaction(), 'committing the transaction');

my @vendorOSes3 = $configDB->fetchVendorOSByFilter();
my @exports3    = $configDB->fetchExportByFilter();
my @systems3    = $configDB->fetchSystemByFilter();
my @clients3    = $configDB->fetchClientByFilter();
my @groups3     = $configDB->fetchGroupByFilter();

is(scalar @vendorOSes3, 0, "should have no vendor-OSes");
is(scalar @exports3, 0, "should have no exports");
is(scalar @systems3, 1, "should have one system (default)");
is(scalar @clients3, 1, "should have one client (default)");
is(scalar @groups3, 0, "should have no groups");

$configDB->disconnect();
