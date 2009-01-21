#! /usr/bin/perl

# add the folder this script lives in to perl's search path for modules:
use FindBin;
use lib $FindBin::Bin;

use Getopt::Long qw(:config pass_through);

use OpenSLX::Basics;
use OpenSLX::ConfigDB;

my (
	$dryRun,
	$defaultSystem,
	$defaultClient,
	%systemConf,
	%clientConf,
	%clientPXE,
);

GetOptions(
	'dry-run' => \$dryRun
		# dry-run doesn't write anything, just prints statistic about what
		# would have been written
);

openslxInit();

my $openslxDB = connectConfigDB();

my $configPath = "$openslxConfig{'private-basepath'}/config";
if (!-d $configPath) {
	die _tr("Unable to access config-path '%s'!", $configPath);
}
my $tempPath = "$openslxConfig{'temp-basepath'}/oslx-demuxer";
mkdir $tempPath;
if (!-d $tempPath) {
	die _tr("Unable to create or access temp-path '%s'!", $tempPath);
}
my $exportPath = "$openslxConfig{'public-basepath'}/tftpboot";
system("rm -rf $exportPath/client-conf/* $exportPath/pxe/pxelinux.cfg/*");
system("mkdir -p $exportPath/client-conf $exportPath/pxe/pxelinux.cfg");
if (!-d $exportPath) {
	die _tr("Unable to create or access export-path '%s'!", $exportPath);
}

demuxConfigurations();

if (!$dryRun) {
	writeConfigurations();
}

disconnectConfigDB($openslxDB);

system("rm -rf $tempPath");

exit;

################################################################################
###
################################################################################
sub isAttribute
{	# returns whether or not the given key is an exportable attribute
	my $key = shift;

	return $key =~ m[^attr];
}

sub mergeConfigAttributes
{	# copies all attributes of source that are unset in target over
	my $target = shift;
	my $source = shift;

	foreach my $key (grep { isAttribute($_) } keys %$source) {
		if (length($source->{$key}) > 0 && length($target->{$key}) == 0) {
			vlog 3, _tr("\tmerging %s (val=%s)", $key, $source->{$key});
			$target->{$key} = $source->{$key};
		}
	}
}

sub writeAttributesToFile
{
	my $attrHash = shift;
	my $fileName = shift;

	open(ATTRS, "> $fileName")		or die "unable to write to $fileName";
	my @attrs = sort grep { isAttribute($_) } keys %$attrHash;
	foreach my $attr (@attrs) {
		if (length($attrHash->{$attr}) > 0) {
			my $shellVar = $attr;
			# convert 'attrExampleName' to 'example_name':
			$shellVar =~ s[([A-Z])]['_'.lc($1)]ge;
			$shellVar = substr($shellVar, 5);
			print SYSCONF "$shellVar = $attrHash->{$attr}\n";
		}
	}
	close(ATTRS);
}

sub copySystemConfig
{	# copies local configuration extensions of given system from private
	# config folder (var/lib/openslx/config/...) into a temporary folder
	my $systemName = shift;
	my $targetPath = shift;

	system("rm -rf $targetPath");
	mkdir $targetPath;

	# first copy default files...
	my $defaultConfigPath = "$configPath/default";
	if (-d $defaultConfigPath) {
		system("cp -r $defaultConfigPath/* $targetPath");
	}
	# now pour system-specific configuration on top (if any):
	my $systemConfigPath = "$configPath/$systemName";
	if (-d $systemConfigPath) {
		system("cp -r $systemConfigPath/* $targetPath");
	}
}

sub createTarOfPath
{
	my $buildPath = shift;
	my $tarName = shift;
	my $destinationPath = shift;

	mkdir $destinationPath;
	my $tarFile = "$destinationPath/$tarName";
	vlog 1, _tr('creating tar %s', $tarFile);
	my $tarCmd = "cd $buildPath && tar czf $tarFile *";
	if (system("$tarCmd") != 0) {
		die _tr("unable to execute shell-command:\n\t%s \n\t($!)", $tarCmd);
	}
}

################################################################################
###
################################################################################
sub writeClientConfigurationsForSystem
{
	my $system = shift;
	my $buildPath = shift;
	my $attrFile = shift;

	foreach my $client (values %{$system->{clients}}) {
		vlog 2, _tr("exporting client %d:%s", $client->{id}, $client->{name});

		writeAttributesToFile($client, $attrFile);

		my $mac = $client->{mac};
		$mac =~ tr[:][-];
		createTarOfPath($buildPath, "01-$mac.tgz",
						"$exportPath/client-conf/$system->{name}");
	}
}


sub writeSystemConfigurations
{
	foreach my $system (values %systemConf) {
		vlog 2, _tr('exporting system %d:%s', $system->{id}, $system->{name});
		my $buildPath = "$tempPath/build";

		copySystemConfig($system->{name}, $buildPath);

		my $attrFile = "$buildPath/initramfs/machine-setup";
		writeAttributesToFile($system, $attrFile);

		createTarOfPath($buildPath, "default.tgz",
						"$exportPath/client-conf/$system->{name}");

		writeClientConfigurationsForSystem($system, $buildPath, $attrFile);

		system("rm -rf $buildPath");
	}
}

sub initSystemConfigurations
{
	$defaultSystem = fetchSystemsByID($openslxDB, 0);

	foreach my $s (fetchSystemsByFilter($openslxDB)) {
		next unless $s->{id} > 0;
		vlog 2, _tr('read system %d:%s...', $s->{id}, $s->{name});

		# replace any whitespace in name, as we will use it as a
		# directory name later:
		$s->{name} =~ s[\s+][_]g;

		mergeConfigAttributes($s, $defaultSystem);
		$systemConf{$s->{id}} = $s;
	}
}

sub linkClientToSystems
{
	my ($client, @systemIDs) = @_;

	my $clientID = $client->{id};
	foreach my $sysID (@systemIDs) {
		my $sysConf = $systemConf{$sysID};
		next if !defined $sysConf;
		$sysConf->{clients} = {}		unless exists $sysConf->{clients};
		if (!exists $sysConf->{clients}->{$clientID}
		&& !$sysConf->{unbootable}) {
			vlog 2, _tr('linking client %d:%s to system %d:%s',
						$client->{id}, $client->{name},
						$sysID, $sysConf->{name});
			$sysConf->{clients}->{$clientID} = $client;
		}
	}
}

sub demuxClientConfigurations
{
	my %groups;
	foreach my $g (fetchGroupsByFilter($openslxDB)) {
		vlog 2, _tr('read group %d:%s...', $g->{id}, $g->{name});
		$groups{$g->{id}} = $g;
	}

	$defaultClient = fetchClientsByID($openslxDB, 0);

	foreach my $client (fetchClientsByFilter($openslxDB)) {
		next unless $client->{id} > 0;
		vlog 2, _tr('read client %d:%s...', $client->{id}, $client->{name});

		# add all systems directly linked to client:
my @sysIDs = fetchSystemIDsOfClient($openslxDB, $client->{id});
		linkClientToSystems($client, @sysIDs
							);

		# now fetch and step over all groups this client belongs to
		# (ordered by priority from highest to lowest):
		my @clientGroups
			= sort { $b->{priority} <=> $a->{priority} }
			  map { $groups{$_} }
			  grep { exists $groups{$_} }
					# just to be safe: filter out unknown group-IDs
			  fetchGroupIDsOfClient($openslxDB, $client->{id});
		foreach my $group (@clientGroups) {
			# fetch and add all systems that the client inherits from
			# the current group:
			linkClientToSystems($client,
								fetchSystemIDsOfGroup($openslxDB, $group->{id}));

			# merge configuration from this group into the current client:
			vlog 3, _tr('merging from group %d:%s...', $group->{id}, $group->{name});
			mergeConfigAttributes($client, $group);
		}

		# merge configuration from default client:
		vlog 3, _tr('merging from default client...');
		mergeConfigAttributes($client, $defaultClient);

		# finally demux client-config to systems bootable by that client
		# and merge system-specific attributes into that:
		foreach my $s (values %{$client->{systems}}) {
			$clientConf{$client->{id}} = { %$client };
			vlog 3, _tr('merging from system %d:%s...', $system->{id}, $system->{name});
			mergeConfigAttributes($systemClientConf{$client->{id}}, $system);
		}
	}
}

sub demuxConfigurations()
{
	initSystemConfigurations();
	demuxClientConfigurations();
}

sub writeConfigurations()
{
	writeSystemConfigurations();
}

