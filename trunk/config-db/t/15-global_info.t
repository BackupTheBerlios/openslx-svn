use Test::More qw(no_plan);

use lib '/opt/openslx/lib';

# basic init
use OpenSLX::ConfigDB;

my $configDB = OpenSLX::ConfigDB->new;
$configDB->connect();

# fetch global-info 'next-nbd-server-port'
ok(
	$globalInfo = $configDB->fetchGlobalInfo('next-nbd-server-port'), 
	'fetch global-info'
);
is($globalInfo, '5000', 'global-info - value');

# try to fetch a couple of non-existing global-infos
is(
	$configDB->fetchGlobalInfo(-1), undef, 
	'global-info with id -1 should not exist'
);
is($configDB->fetchGlobalInfo('xxx'), undef, 
	'global-info with id xxx should not exist');

# change value of global-info and then fetch and check the new value
ok($configDB->changeGlobalInfo('next-nbd-server-port', '5050'), 'changing global-info');
is(
	$configDB->fetchGlobalInfo('next-nbd-server-port'), '5050',
	'fetching changed global-info'
);

# changing a non-existing global-info should fail
ok(
	! eval { $configDB->changeGlobalInfo('xxx', 'new-value') }, 
	'changing unknown global-info should fail'
);

$configDB->disconnect();

