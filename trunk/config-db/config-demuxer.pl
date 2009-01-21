#! /usr/bin/perl
use strict;

# add the folder this script lives in to perl's search path for modules:
use FindBin;
use lib $FindBin::Bin;

use Fcntl qw(:DEFAULT :flock);
use Getopt::Long qw(:config pass_through);
use OpenSLX::Basics;
use OpenSLX::ConfigDB qw(:access :aggregation :support);

my $pxelinux0Path = "/usr/share/syslinux/pxelinux.0";
my $pxeConfigDefaultTemplate = q[NOESCAPE 0
PROMPT 0
TIMEOUT 100
DEFAULT menu.c32
IMPLICIT 1
ALLOWOPTIONS 1
ONERROR menu
MENU TITLE What would you like to do? (use cursor to select)
MENU MASTER PASSWD secret
LABEL menu

];

my (
	$dryRun,
		# dryRun won't touch any file
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
		system(qq[cp -a "$pxelinux0Path" $exportPath/pxe/pxelinux.0]);
	}
}

my $lockFile = "$exportPath/config-demuxer.lock";
lockScript($lockFile);

writeConfigurations();

my $wr = ($dryRun ? "would have written" : "wrote");
print "$wr $systemConfCount systems and $clientSystemConfCount client-configurations to $exportPath/client-conf\n";

disconnectConfigDB($openslxDB);

system("rm -rf $tempPath")		unless $dryRun || length($tempPath) < 12;

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

sub writeAttributesToFile
{
	my $attrHash = shift;
	my $fileName = shift;

	return		if $dryRun;

	open(ATTRS, "> $fileName")		or die "unable to write to $fileName";
	my @attrs = sort grep { isAttribute($_) } keys %$attrHash;
	foreach my $attr (@attrs) {
		if (length($attrHash->{$attr}) > 0) {
			my $externalAttrName = externalAttrName($attr);
			print ATTRS "$externalAttrName = $attrHash->{$attr}\n";
		}
	}
	close(ATTRS);
}

sub copyExternalSystemConfig
{	# copies local configuration extensions of given system from private
	# config folder (var/lib/openslx/config/...) into a temporary folder
	my $systemName = shift;
	my $targetPath = shift;

	return		if $dryRun;

	if ($targetPath !~ m[$tempPath]) {
		die _tr("system-error: illegal target-path <%s>!", $targetPath);
	}
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

################################################################################
###
################################################################################
sub writePXEMenus
{
	my $pxePath = "$exportPath/pxe/pxelinux.cfg";

	my @clients = fetchClientsByFilter($openslxDB);
	foreach my $client (@clients) {
		my $externalClientID = externalIDForClient($client);
		my $pxeFile = "$pxePath/$externalClientID";
		vlog 1, _tr("writing PXE-file %s", $pxeFile);
		open(PXE, "> $pxeFile")		or die "unable to write to $pxeFile";
		print PXE $pxeConfigDefaultTemplate;
		my @systemIDs = aggregatedSystemIDsOfClient($openslxDB, $client);
		my @systems = fetchSystemsByID($openslxDB, \@systemIDs);
		foreach my $system (@systems) {
			print PXE "LABEL openslx-$system->{name}\n";
			print PXE " MENU DEFAULT\n";
			print PXE " MENU LABEL ^$system->{label}\n";
			print PXE " KERNEL $system->{kernel}\n";
			print PXE " append $system->{kernel_params}\n";
			print PXE " ipappend 1\n";
		}
		close(PXE);
 	}
}

sub writeSystemPXEFiles
{
	my $system = shift;

	my $pxePath = "$exportPath/pxe/pxelinux.cfg";

	my @kernelFiles = aggregatedKernelFilesOfSystem($openslxDB, $system);
	foreach my $kernelFile (@kernelFiles) {
		vlog 1, _tr('copying kernel %s to %s/', $kernelFile, $pxePath);
		system(qq[cp -a "$kernelFile" $pxePath/])		unless $dryRun;
	}
	foreach my $initramFile (aggregatedInitramFilesOfSystem($openslxDB, $system)) {
		vlog 1, _tr('copying initramfs %s to %s/', $initramFile, $pxePath);
		system(qq[cp -a "$initramFile" $pxePath/])		unless $dryRun;
	}
}

sub writeClientConfigurationsForSystem
{
	my $system = shift;
	my $buildPath = shift;
	my $attrFile = shift;

	my @clientIDs = aggregatedClientIDsOfSystem($openslxDB, $system);
	my @clients = fetchClientsByID($openslxDB, \@clientIDs);
	foreach my $client (@clients) {
		vlog 2, _tr("exporting client %d:%s", $client->{id}, $client->{name});
		$clientSystemConfCount++;

		# merge configurations of client, it's groups, default client and
		# system and write the resulting attributes to a configuration file:
		mergeDefaultAndGroupAttributesIntoClient($openslxDB, $client);
		mergeAttributes($client, $system);
		writeAttributesToFile($client, $attrFile);

		# create tar containing external system configuration
		# and client attribute file:
		my $externalClientID = externalIDForClient($client);
		my $externalSystemID = externalIDForSystem($system);
		createTarOfPath($buildPath, "${externalClientID}.tgz",
						"$exportPath/client-conf/$externalSystemID");
	}
}

sub writeSystemConfigurations
{
	my @systems = fetchSystemsByFilter($openslxDB);
	foreach my $system (@systems) {
		next 	unless $system->{id} > 0;

		vlog 2, _tr('exporting system %d:%s', $system->{id}, $system->{name});
		$systemConfCount++;

		my $buildPath = "$tempPath/build";
		copyExternalSystemConfig($system->{name}, $buildPath);

		my $attrFile = "$buildPath/initramfs/machine-setup";
		mergeDefaultAttributesIntoSystem($openslxDB, $system);
		writeAttributesToFile($system, $attrFile);

		my $externalSystemID = externalIDForSystem($system);
		my $systemPath = "$exportPath/client-conf/$externalSystemID";
		createTarOfPath($buildPath, "default.tgz", $systemPath);

		writeSystemPXEFiles($system);

		writeClientConfigurationsForSystem($system, $buildPath, $attrFile);

		system("rm -rf $buildPath")		unless $dryRun;
	}
}

sub writeConfigurations
{
	$systemConfCount = $clientSystemConfCount = 0;
	writeSystemConfigurations();
	writePXEMenus();
}

