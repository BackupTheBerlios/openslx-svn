#! /usr/bin/perl
use strict;

# add the folder this script lives in to perl's search path for modules:
use FindBin;
use lib $FindBin::Bin;

use Fcntl qw(:DEFAULT :flock);
use Getopt::Long qw(:config pass_through);
use OpenSLX::Basics;
use OpenSLX::ConfigDB;

my $pxelinux0Path = "/usr/share/syslinux/pxelinux.0";
my $pxeConfigDefaultTemplate = q[NOESCAPE 0
PROMPT 0
TIMEOUT 100
DEFAULT menu
IMPLICIT 1
ALLOWOPTIONS 1
ONERROR menu
MENU TITLE What would you like to do? (use cursor to select)
MENU MASTER PASSWD secret
];

my (
	$dryRun,
		# dryRun won't touch any file
	$defaultSystem,
		# configuration specified by default system
	$defaultClient,
		# configuration specified by default client
	%systemConf,
		# system configurations - straight from DB
	%clientConf,
		# configurations for each client, folded info from client, groups
		# and default client
	$systemConfCount,
		# number of system configurations written
	$clientSystemConfCount,
		# number of (system-specific) client configurations written
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
if (!$dryRun) {
	mkdir $tempPath;
	if (!-d $tempPath) {
		die _tr("Unable to create or access temp-path '%s'!", $tempPath);
	}
}
my $exportPath = "$openslxConfig{'public-basepath'}/tftpboot";
if (!$dryRun) {
	system("rm -rf $exportPath/client-conf/* $exportPath/pxe/pxelinux.cfg/*");
	system("mkdir -p $exportPath/client-conf $exportPath/pxe/pxelinux.cfg");
	if (!-d $exportPath) {
		die _tr("Unable to create or access export-path '%s'!", $exportPath);
	}
	if (!-e "$exportPath/pxe/pxelinux.0") {
		system("cp -a $pxelinux0Path $exportPath/pxe/pxelinux.0");
	}
}

my $lockFile = "$exportPath/config-demuxer.lock";
lockScript($lockFile);

fetchConfigurations();

writeConfigurations();

my $wr = ($dryRun ? "would have written" : "wrote");
print "$wr $systemConfCount systems and $clientSystemConfCount client-configurations to $exportPath/client-conf\n";

disconnectConfigDB($openslxDB);

system("rm -rf $tempPath")		unless $dryRun || length($tempPath) == 0;

unlockScript($lockFile);

exit;

################################################################################
###
################################################################################
sub lockScript
{
	my $lockFile = shift;

	return		if $dryRun;

	# use a lock-file to singularize execution of this script:
	if (-e $lockFile) {
		my $ctime = (stat($lockFile))[10];
		my $now = time();
		if ($now - $ctime > 15*60) {
			# existing lock file is older than 15 minutes, wipe it:
			unlink $lockFile;
		}
	}
	sysopen(LOCKFILE, $lockFile, O_RDWR|O_CREAT|O_EXCL)
		or die _tr(qq[Lock-file <%s> exists, script is already running.\nPlease remove the logfile and try again if you are sure that no one else is executing this script.], $lockFile);
}

sub unlockScript
{
	my $lockFile = shift;

	return		if $dryRun;

	unlink $lockFile;
}

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

	return		if $dryRun;

	open(ATTRS, "> $fileName")		or die "unable to write to $fileName";
	my @attrs = sort grep { isAttribute($_) } keys %$attrHash;
	foreach my $attr (@attrs) {
		if (length($attrHash->{$attr}) > 0) {
			my $shellVar = $attr;
			# convert 'attrExampleName' to 'example_name':
			$shellVar =~ s[([A-Z])]['_'.lc($1)]ge;
			$shellVar = substr($shellVar, 5);
			print ATTRS "$shellVar = $attrHash->{$attr}\n";
		}
	}
	close(ATTRS);
}

sub copySystemConfig
{	# copies local configuration extensions of given system from private
	# config folder (var/lib/openslx/config/...) into a temporary folder
	my $systemName = shift;
	my $targetPath = shift;

	return		if $dryRun;

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

	my $tarFile = "$destinationPath/$tarName";
	vlog 1, _tr('creating tar %s', $tarFile);
	return		if $dryRun;

	mkdir $destinationPath;
	my $tarCmd = "cd $buildPath && tar czf $tarFile *";
	if (system("$tarCmd") != 0) {
		die _tr("unable to execute shell-command:\n\t%s \n\t($!)", $tarCmd);
	}
}

sub externalClientIDFor
{
	my $client = shift;

	my $mac = lc($client->{mac});
		# PXE seems to expect MACs being all lowercase
	$mac =~ tr[:][-];
	return "01-$mac";
}

################################################################################
###
################################################################################
sub writePXEMenus
{
	my $pxePath = "$exportPath/pxe/pxelinux.cfg";

	foreach my $client (values %clientConf) {
		my $externalClientID = externalClientIDFor($client);
		my $pxeFile = "$pxePath/$externalClientID";
		vlog 1, _tr("writing PXE-file $pxeFile");
		open(PXE, "> $pxeFile")		or die "unable to write to $pxeFile";
		print PXE $pxeConfigDefaultTemplate;
		foreach my $system (values %{$client->{systems}}) {
			print PXE "LABEL openslx-$system->{name}\n";
			print PXE "\tMENU DEFAULT\n";
			print PXE "\tMENU LABEL ^$system->{label}\n";
			print PXE "\tKERNEL $system->{kernel}\n";
			print PXE "\tAPPEND $system->{kernel_params}\n";
			print PXE "\tIPAPPEND 1\n";
		}
		close(PXE);
	}
}

sub writeClientConfigurationsForSystem
{
	my $system = shift;
	my $buildPath = shift;
	my $attrFile = shift;

	foreach my $client (values %{$system->{clients}}) {
		vlog 2, _tr("exporting client %d:%s", $client->{id}, $client->{name});
		$clientSystemConfCount++;

		# copy this client's configuration in order to
		# merge system configuration into client config and write the
		# resulting attributes to a configuration file:
		my $clientSystemConf = { %$client };
		mergeConfigAttributes($clientSystemConf, $system);
		writeAttributesToFile($clientSystemConf, $attrFile);

		my $externalClientID = externalClientIDFor($client);
		createTarOfPath($buildPath, "${externalClientID}.tgz",
						"$exportPath/client-conf/$system->{name}");
	}
}

sub writeSystemConfigurations
{
	foreach my $system (values %systemConf) {
		vlog 2, _tr('exporting system %d:%s', $system->{id}, $system->{name});
		$systemConfCount++;

		my $buildPath = "$tempPath/build";
		copySystemConfig($system->{name}, $buildPath);

		my $attrFile = "$buildPath/initramfs/machine-setup";
		writeAttributesToFile($system, $attrFile);

		createTarOfPath($buildPath, "default.tgz",
						"$exportPath/client-conf/$system->{name}");

		writeClientConfigurationsForSystem($system, $buildPath, $attrFile);

		system("rm -rf $buildPath")		unless $dryRun;
	}
}

sub linkClientToSystems
{
	my ($client, @systemIDs) = @_;

	my $clientID = $client->{id};
	$client->{systems} = {}		unless exists $client->{systems};
	foreach my $sysID (@systemIDs) {
		my $sysConf = $systemConf{$sysID};
		next if !defined $sysConf || $sysConf->{unbootable};

		# refer from system to client:
		$sysConf->{clients} = {}		unless exists $sysConf->{clients};
		if (!exists $sysConf->{clients}->{$clientID}) {
			vlog 2, _tr('linking client %d:%s to system %d:%s',
						$clientID, $client->{name},
						$sysID, $sysConf->{name});
			$sysConf->{clients}->{$clientID} = $client;
		}

		# refer from client to system:
		if (!exists $client->{systems}->{$sysID}) {
			$client->{systems}->{$sysID} = $systemConf{$sysID};
		}
	}
}

sub fetchSystemConfigurations
{
	$defaultSystem = fetchSystemsByID($openslxDB, 0);

	foreach my $s (fetchSystemsByFilter($openslxDB)) {
		next unless $s->{id} > 0;
		vlog 2, _tr('read system %d:%s...', $s->{id}, $s->{name});

		# replace any whitespace in name, as we will use it as a
		# directory name later:
		$s->{name} =~ s[\s+][_]g;

		# merge default system configuration into this system and store
		# that into hash:
		mergeConfigAttributes($s, $defaultSystem);
		$systemConf{$s->{id}} = $s;
	}
}

sub fetchClientConfigurations
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
		linkClientToSystems($client,
							fetchSystemIDsOfClient($openslxDB, $client->{id}));

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

		# merge configuration from default client and store client
		# configuration into hash:
		vlog 3, _tr('merging from default client...');
		mergeConfigAttributes($client, $defaultClient);
		$clientConf{$client->{id}} = $client;
	}
}

sub fetchConfigurations
{
	fetchSystemConfigurations();
	fetchClientConfigurations();
}

sub writeConfigurations
{
	$systemConfCount = $clientSystemConfCount = 0;
	writeSystemConfigurations();
	writePXEMenus();
}

