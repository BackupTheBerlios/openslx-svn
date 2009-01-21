#! /usr/bin/perl

# add the folder this script lives in to perl's search path for modules:
use FindBin;
use lib $FindBin::Bin;

use Getopt::Long;

use ODLX::Basics;
use ODLX::ConfigDB;

my (
	$dryRun,
	%systemConf,
	%sytemClientConf,
	%clientPXE,
);

odlxInit();

GetOptions(
	'dry-run' => \$dryRun
		# dry-run doesn't write anything, just prints statistic about what
		# would have been written
);

print "dry-run...\n" if $dryRun;

my $odlxDB = connectConfigDB();

demuxConfigurations();

disconnectConfigDB($odlxDB);

exit;

################################################################################
###
################################################################################
sub initSystemConfigurations
{
	foreach my $s (fetchSystemsByFilter($odlxDB)) {
		vlog 3, _tr('system %d:%s...', $s->{id}, $s->{name});
		$systemConf{$s->{id}} = $s;
	}
}

sub mergeConfigAttributes
{	# copies all attributes of source that do not exists in target over
	my $target = shift;
	my $source = shift;

	foreach my $key (grep { $_ =~ m[^attr] } keys %$source) {
		if (length($source->{$key}) > 0 && length($target->{$key}) == 0) {
			$target->{$key} = $source->{$key};
		}
	}
}

sub demuxClientConfigurations
{
	my %groups;
	foreach my $g (fetchGroupsByFilter($odlxDB)) {
		vlog 3, _tr('group %d:%s...', $g->{id}, $g->{name});
		$groups{$g->{id}} = $g;
	}

	foreach my $client (fetchClientsByFilter($odlxDB)) {
		vlog 3, _tr('client %d:%s...', $client->{id}, $client->{name});

		# add all systems directly linked to client:
		$client->{systems} = {};
		foreach my $s (fetchSystemIDsOfClient($odlxDB, $client->{id})) {
			if (!exists $client->{systems}->{$s->{id}}) {
				$client->{systems}->{$s->{id}} = $systems{$s->{id}};
			}
		}

		# now fetch and step over all groups this client belongs to
		# (ordered by priority from highest to lowest):
		my @clientGroups
			= sort { $b->{priority} <=> $a->{priority} }
			  map { $groups{$_} }
			  grep { exists $groups{$_} }
					# just to be safe: filter out unknown group-IDs
			  fetchGroupIDsOfClient($odlxDB, $client->{id});
		foreach my $group (@clientGroups) {
			# fetch and add all systems that the client inherits from
			# the current group:
			foreach my $s (fetchSystemIDsOfGroup($odlxDB, $group->{id})) {
				if (!exists $client->{systems}->{$s->{id}}) {
					$client->{systems}->{$s->{id}} = $systems{$s->{id}};
				}
				mergeConfigAttributes($client, $group);
			}
		}

		# finally demux client-config to system-specific configuration
		# and merge system-specific attributes into that:
		foreach my $s (values %{$client->{systems}}) {
			$systemClientConf{$client->{id}} = { %$client };
			mergeConfigAttributes($systemClientConf{$client->{id}}, $system);
		}
	}
}

sub demuxConfigurations()
{
	initSystemConfigurations();
	demuxClientConfigurations();
}

