use Test::More qw(no_plan);

use lib '/opt/openslx/lib';

# basic stuff
use_ok(OpenSLX::ConfigDB);

use strict;
use warnings;

# connecting and disconnecting
ok(my $configDB = OpenSLX::ConfigDB->new, 'can create object');
isa_ok($configDB, 'OpenSLX::ConfigDB');

{
    # create a second object - should work and yield different objects
    ok(my $configDB2 = OpenSLX::ConfigDB->new, 'can create another object');
    cmp_ok($configDB, 'ne', $configDB2, 'should have two different objects now');
}

ok($configDB->connect(), 'connecting');
ok($configDB->disconnect(), 'disconnecting');

