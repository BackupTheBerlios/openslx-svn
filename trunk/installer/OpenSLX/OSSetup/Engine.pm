# Engine.pm - provides driver enginge for the OSSetup API.
#
# (c) 2006 - OpenSLX.com
#
# Oliver Tappe <ot@openslx.com>
#
package OpenSLX::OSSetup::Engine;

use vars qw(@ISA @EXPORT $VERSION);
$VERSION = 1.01;		# API-version . implementation-version

use Exporter;
@ISA = qw(Exporter);

@EXPORT = qw(
	%supportedDistros
);

use strict;
use Carp;
use File::Basename;
use OpenSLX::Basics;

use vars qw(%supportedDistros);

%supportedDistros = (
#	'debian-3.1' 		=> 'Debian_3_1',
#	'debian-4.0' 		=> 'Debian_4_0',
	'fedora-6' 			=> 'Fedora_6',
#	'fedora-6-x86_64' 	=> 'Fedora_6_x86_64',
#	'mandriva-2007.0' 	=> 'Mandriva_2007_0',
#	'suse-9.3' 			=> 'SUSE_9_3',
#	'suse-10.0' 		=> 'SUSE_10_0',
#	'suse-10.0-x86_64' 	=> 'SUSE_10_0_x86_64',
	'suse-10.1' 		=> 'SUSE_10_1',
#	'suse-10.1-x86_64' 	=> 'SUSE_10_1_x86_64',
	'suse-10.2' 		=> 'SUSE_10_2',
	'suse-10.2-x86_64' 	=> 'SUSE_10_2_x86_64',
#	'ubuntu-6.10' 		=> 'Ubuntu_6_10',
);

################################################################################
### interface methods
################################################################################
sub new
{
	my $class = shift;

	my $self = {
	};

	return bless $self, $class;
}

sub initialize
{
	my $self = shift;
	my $distroName = shift;
	my $selectionName = shift;
	my $protectSystemPath = shift;
	my $cloneMode = shift;

	if (!exists $supportedDistros{lc($distroName)}) {
		print _tr("Sorry, distro '%s' is unsupported.\n", $distroName);
		print _tr("List of supported distros:\n\t");
		print join("\n\t", keys %supportedDistros)."\n";
		exit 1;
	}

	# load module for the requested distro:
	my $distroModule
		= "OpenSLX::OSSetup::Distro::".$supportedDistros{lc($distroName)};
	unless (eval "require $distroModule") {
		if ($! == 2) {
			die _tr("Distro-module <%s> not found!\n", $distroModule);
		} else {
			die _tr("Unable to load distro-module <%s> (%s)\n", $distroModule, $@);
		}
	}
	my $modVersion = $distroModule->VERSION;
	if ($modVersion < 1.01) {
		die _tr('Could not load module <%s> (Version <%s> required, but <%s> found)',
				$distroModule, 1.01, $modVersion);
	}
	$distroModule->import;
	my $distro = $distroModule->new;
	$distro->initialize($self);
	$self->{distro} = $distro;

	$self->{'selection-name'} = $selectionName;
	my $vendorOSName = $self->{distro}->{'base-name'};
	if (length($selectionName) && $selectionName ne 'default') {
		$vendorOSName .= "-$selectionName";
	}
	$self->{'vendor-os-name'} = $vendorOSName;
	$self->{'clone-mode'} = $cloneMode;

	# setup path to distribution-specific info:
	my $distroInfoDir = "../lib/distro-info/$distro->{'base-name'}";
	if (!-d $distroInfoDir) {
		die _tr("unable to find distro-info for system '%s'\n", $distro->{'base-name'});
	}
	$self->{'distro-info-dir'} = $distroInfoDir;
	$self->readDistroInfo();

	if (!$self->{'clone-mode'}
	&& !exists $self->{'distro-info'}->{'selection'}->{$selectionName}) {
		die _tr("selection '%s' is unknown to system '%s'\n",
				$selectionName, $distro->{'base-name'})
			."These selections are available:\n\t"
			.join("\n\t", keys %{$self->{'distro-info'}->{'selection'}})
			."\n";
	}

	$self->{'system-path'}
		= "$openslxConfig{'stage1-path'}/$self->{'vendor-os-name'}";
	vlog 1, "system will be installed to '$self->{'system-path'}'";
	if ($protectSystemPath && -e $self->{'system-path'}) {
		die _tr("'%s' already exists, giving up!", $self->{'system-path'});
	}

	$self->createPackager();
	$self->createMetaPackager();

}

sub installVendorOS
{
	my $self = shift;

	$self->createSystemPath();

	$self->setupStage1A();
	my $pid = fork();
	if (!$pid) {
		# child, execute the tasks that involve a chrooted environment:
		$self->setupStage1B();
		$self->setupStage1C();
		exit 0;
	}

	# parent, wait for child to do its work inside the chroot
	waitpid($pid, 0);
	if ($?) {
		exit $?;
	}
	$self->stage1C_cleanupBasicSystem();
	$self->setupStage1D();
	vlog 0, _tr("Vendor-OS <%s> installed succesfully.\n",
				$self->{'vendor-os-name'});

	$self->addInstalledVendorOSToConfigDB();
}

sub cloneVendorOS
{
	my $self = shift;
	my $source = shift;

	$self->createSystemPath();

	$self->clone_fetchSource($source);
	vlog 0, _tr("Vendor-OS <%s> cloned succesfully.\n",
				$self->{'vendor-os-name'});

	$self->addInstalledVendorOSToConfigDB();
}

sub updateVendorOS
{
	my $self = shift;

	$self->updateStage1D();
	vlog 0, _tr("Vendor-OS <%s> updated succesfully.\n",
				$self->{'vendor-os-name'});
}

sub addInstalledVendorOSToConfigDB
{
	my $self = shift;

	my $configDBModule = "OpenSLX::ConfigDB";
	unless (eval "require $configDBModule") {
		if ($! == 2) {
			vlog 1, _tr("ConfigDB-module not found, unable to access OpenSLX-database.\n");
		} else {
			die _tr("Unable to load ConfigDB-module <%s> (%s)\n", $configDBModule, $@);
		}
	} else {
		my $modVersion = $configDBModule->VERSION;
		if ($modVersion < 1.01) {
			die _tr('Could not load module <%s> (Version <%s> required, but <%s> found)',
					$configDBModule, 1.01, $modVersion);
		}
		$configDBModule->import(qw(:access :manipulation));
		my $openslxDB = connectConfigDB();
		# insert new system if it doesn't already exist in DB:
		my $vendorOSName = $self->{'vendor-os-name'};
		my $vendorOS
			= fetchVendorOSesByFilter($openslxDB,
									  { 'name' => $vendorOSName },
									  'id');
		if (defined $vendorOS) {
			vlog 0, _tr("Vendor-OS <%s> already exists in OpenSLX-database.\n",
						$vendorOSName);
		} else {
			my $id = addVendorOS($openslxDB, {
				'name' => $vendorOSName,
				'path' => $self->{'vendor-os-name'},
			});

			vlog 0, _tr("Vendor-OS <%s> has been added to DB (ID=%s).\n",
						$vendorOSName, $id);
		}

		disconnectConfigDB($openslxDB);
	}
}

################################################################################
### implementation methods
################################################################################
sub readDistroInfo
{
	my $self = shift;

	vlog 1, "reading configuration info for $self->{'vendor-os-name'}...";
	# merge user-provided configuration distro defaults...
	my %repository = %{$self->{distro}->{config}->{repository}};
	my %selection = %{$self->{distro}->{config}->{selection}};
	my $package_subdir = $self->{distro}->{config}->{'package-subdir'};
	my $prereq_packages = $self->{distro}->{config}->{'prereq-packages'};
	my $bootstrap_prereq_packages
		= $self->{distro}->{config}->{'bootstrap-prereq-packages'};
	my $bootstrap_packages = $self->{distro}->{config}->{'bootstrap-packages'};
	my $file = "$self->{'distro-info-dir'}/settings.local";
	if (-e $file) {
		vlog 3, "reading configuration file $file...";
		my $config = slurpFile($file);
		if (!eval $config && length($@)) {
			die _tr("error in config-file <%s> (%s)", $file, $@)."\n";
		}
	}
	# ...and store merged config:
	$self->{'distro-info'} = {
		'package-subdir' => $package_subdir,
		'prereq-packages' => $prereq_packages,
		'bootstrap-prereq-packages' => $bootstrap_prereq_packages,
		'bootstrap-packages' => $bootstrap_packages,
		'repository' => \%repository,
		'selection' => \%selection,
	};

	if ($openslxConfig{'verbose-level'} >= 2) {
		# dump distro-info, if asked for:
		foreach my $r (sort keys %repository) {
			vlog 2, "repository '$r':";
			foreach my $k (sort keys %{$repository{$r}}) {
				vlog 2, "\t$k = '$repository{$r}->{$k}'";
			}
		}
		foreach my $s (sort keys %selection) {
			my @selLines = split "\n", $selection{$s};
			vlog 2, "selection '$s':";
			foreach my $sl (@selLines) {
				vlog 2, "\t$sl";
			}
		}
	}
}

sub createSystemPath
{
	my $self = shift;

	if (system("mkdir -p $self->{'system-path'}")) {
		die _tr("unable to create directory '%s', giving up! (%s)",
				$self->{'system-path'}, $!);
	}
}

sub createPackager
{
	my $self = shift;

	my $packagerModule
		= "OpenSLX::OSSetup::Packager::$self->{distro}->{'packager-type'}";
	unless (eval "require $packagerModule") {
		if ($! == 2) {
			die _tr("Packager-module <%s> not found!\n", $packagerModule);
		} else {
			die _tr("Unable to load packager-module <%s> (%s)\n", $packagerModule, $@);
		}
	}
	my $modVersion = $packagerModule->VERSION;
	if ($modVersion < 1.01) {
		die _tr('Could not load module <%s> (Version <%s> required, but <%s> found)',
				$packagerModule, 1.01, $modVersion);
	}
	$packagerModule->import;
	my $packager = $packagerModule->new;
	$packager->initialize($self);
	$self->{'packager'} = $packager;
}

sub createMetaPackager
{
	my $self = shift;

	my $metaPackagerModule
		= "OpenSLX::OSSetup::MetaPackager::$self->{distro}->{'meta-packager-type'}";
	unless (eval "require $metaPackagerModule") {
		if ($! == 2) {
			die _tr("Meta-packager-module <%s> not found!\n", $metaPackagerModule);
		} else {
			die _tr("Unable to load meta-packager-module <%s> (%s)\n", $metaPackagerModule, $@);
		}
	}
	my $modVersion = $metaPackagerModule->VERSION;
	if ($modVersion < 1.01) {
		die _tr('Could not load module <%s> (Version <%s> required, but <%s> found)',
				$metaPackagerModule, 1.01, $modVersion);
	}
	$metaPackagerModule->import;
	my $metaPackager = $metaPackagerModule->new;
	$metaPackager->initialize($self);
	$self->{'meta-packager'} = $metaPackager;
}

sub selectBaseURL
{
	my $self = shift;
	my $repoInfo = shift;

	my $baseURL = $repoInfo->{url};
	if (!defined $baseURL) {
		my @baseURLs = string2Array($repoInfo->{urls});
		# TODO: insert a closest mirror algorithm here!
		$baseURL = $baseURLs[0];
	}
	return $baseURL;
}

sub setupStage1A
{
	my $self = shift;

	vlog 1, "setting up stage1a for $self->{'vendor-os-name'}...";

	# specify individual paths for the respective substages:
	$self->{stage1aDir} = "$self->{'system-path'}/stage1a";
	$self->{stage1bSubdir} = 'slxbootstrap';
	$self->{stage1cSubdir} = 'slxfinal';

	# we create *all* of the above folders by creating stage1cDir:
	my $stage1cDir
		= "$self->{'stage1aDir'}/$self->{'stage1bSubdir'}/$self->{'stage1cSubdir'}";
	if (system("mkdir -p $stage1cDir")) {
		die _tr("unable to create directory '%s', giving up! (%s)",
				$stage1cDir, $!);
	}

	$self->stage1A_createBusyboxEnvironment();
	$self->stage1A_setupResolver();
	$self->stage1A_copyPrerequiredFiles();
	$self->stage1A_copyTrustedPackageKeys();
	$self->stage1A_createRequiredFiles();
}

sub stage1A_createBusyboxEnvironment
{
	my $self = shift;

	# copy busybox and all required binaries into stage1a-dir:
	vlog 1, "creating busybox-environment...";
	copyFile("$openslxConfig{'share-path'}/busybox/busybox",
			 "$self->{stage1aDir}/bin");

	# determine all required libraries and copy those, too:
	vlog 2, "calling slxldd for busybox";
	my $requiredLibsStr = `slxldd $openslxConfig{'share-path'}/busybox/busybox`;
	chomp $requiredLibsStr;
	vlog 2, "slxldd results:\n$requiredLibsStr";
	foreach my $lib (split "\n", $requiredLibsStr) {
		vlog 3, "copying lib '$lib'";
		my $libDir = dirname($lib);
		copyFile($lib, "$self->{stage1aDir}/$libDir");
	}

	# create all needed links to busybox:
	my $links
		= slurpFile("$openslxConfig{'share-path'}/busybox/busybox.links");
	foreach my $linkTarget (split "\n", $links) {
		linkFile('/bin/busybox', "$self->{stage1aDir}/$linkTarget");
	}
}

sub stage1A_setupResolver
{
	my $self = shift;

	copyFile('/etc/resolv.conf', "$self->{stage1aDir}/etc");
	copyFile('/lib/libresolv*', "$self->{stage1aDir}/lib");
	copyFile('/lib/libnss_dns*', "$self->{stage1aDir}/lib");

	my $stage1cDir
		= "$self->{'stage1aDir'}/$self->{'stage1bSubdir'}/$self->{'stage1cSubdir'}";
	copyFile('/etc/resolv.conf', "$stage1cDir/etc");
}

sub stage1A_copyPrerequiredFiles
{
	my $self = shift;

	return unless -d "$self->{'distro-info-dir'}/prereqfiles";

	vlog 2, "copying folder with pre-required files...";
	my $stage1cDir
		= "$self->{'stage1aDir'}/$self->{'stage1bSubdir'}/$self->{'stage1cSubdir'}";
	my $cmd = qq[
		tar --exclude=.svn -cp -C $self->{'distro-info-dir'}/prereqfiles . \\
		| tar -xp -C $stage1cDir
	];
	if (system($cmd)) {
		die _tr("unable to copy folder with pre-required files to folder <%s> (%s)",
				$stage1cDir, $!);
	}
	$self->{distro}->fixPrerequiredFiles($stage1cDir);
}

sub stage1A_copyTrustedPackageKeys
{
	my $self = shift;

	return unless -d "$self->{'distro-info-dir'}/trusted-package-keys";

	vlog 2, "copying folder with trusted package keys...";
	my $stage1bDir
		= "$self->{'stage1aDir'}/$self->{'stage1bSubdir'}";
	my $cmd = qq[
		tar --exclude=.svn -cp -C $self->{'distro-info-dir'} trusted-package-keys \\
		| tar -xp -C $stage1bDir
	];
	if (system($cmd)) {
		die _tr("unable to copy folder with trusted package keys to folder <%s> (%s)",
				$stage1bDir, $!);
	}
	system("chmod 444 $stage1bDir/trusted-package-keys/*");

	# install ultimately trusted keys (from distributor):
	my $stage1cDir
		= "$stage1bDir/$self->{'stage1cSubdir'}";
	my $keyDir = "$self->{'distro-info-dir'}/trusted-package-keys";
	if (-e "$keyDir/pubring.gpg") {
		copyFile("$keyDir/pubring.gpg", "$stage1cDir/usr/lib/rpm/gnupg");
	}
}

sub stage1A_createRequiredFiles
{
	my $self = shift;

	vlog 2, "creating required files...";
	# fake all files required by stage1b (by creating them empty):
	my $stage1bDir
		= "$self->{'stage1aDir'}/$self->{'stage1bSubdir'}";
	foreach my $fake (@{$self->{distro}->{'stage1b-faked-files'}}) {
		fakeFile("$stage1bDir/$fake");
	}

	# fake all files required by stage1c (by creating them empty):
	my $stage1cDir
		= "$stage1bDir/$self->{'stage1cSubdir'}";
	foreach my $fake (@{$self->{distro}->{'stage1c-faked-files'}}) {
		fakeFile("$stage1cDir/$fake");
	}

	mkdir "$stage1cDir/dev";
	if (system("mknod $stage1cDir/dev/null c 1 3")) {
		die _tr("unable to create node <%s> (%s)", "$stage1cDir/dev/null", $!);
	}
}

sub setupStage1B
{
	my $self = shift;

	vlog 1, "setting up stage1b for $self->{'vendor-os-name'}...";
	$self->stage1B_chrootAndBootstrap();
}

sub stage1B_chrootAndBootstrap
{
	my $self = shift;

	vlog 2, "chrooting into $self->{stage1aDir}...";
	# chdir into stage1aDir...
	chdir $self->{stage1aDir}
		or die _tr("unable to chdir into <%s> (%s)", $self->{stage1aDir}, $!);
	# ...do chroot
	chroot "."
		or die _tr("unable to chroot into <%s> (%s)", $self->{stage1aDir}, $!);

	$ENV{PATH} = "/bin:/sbin:/usr/bin:/usr/sbin";

	# chdir into slxbootstrap, as we want to drop packages into there:
	chdir "/$self->{stage1bSubdir}"
		or die _tr("unable to chdir into <%s> (%s)", "/$self->{stage1bSubdir}", $!);

	# fetch prerequired packages:
	my $baseURL
		= $self->selectBaseURL($self->{'distro-info'}->{repository}->{base});
	my $pkgDirURL = $baseURL;
	if (length($self->{'distro-info'}->{'package-subdir'})) {
		$pkgDirURL .= "/$self->{'distro-info'}->{'package-subdir'}";
	}
	my @pkgs = string2Array($self->{'distro-info'}->{'prereq-packages'});
	my @prereqPkgs = downloadFilesFrom(\@pkgs, $pkgDirURL);
	$self->{packager}->unpackPackages(\@prereqPkgs);

	@pkgs = string2Array($self->{'distro-info'}->{'bootstrap-prereq-packages'});
	my @bootstrapPrereqPkgs = downloadFilesFrom(\@pkgs, $pkgDirURL);
	$self->{'local-bootstrap-prereq-packages'} = \@bootstrapPrereqPkgs;

	@pkgs = string2Array($self->{'distro-info'}->{'bootstrap-packages'});
	my @bootstrapPkgs = downloadFilesFrom(\@pkgs, $pkgDirURL);
	my @allPkgs = (@prereqPkgs, @bootstrapPrereqPkgs, @bootstrapPkgs);
	$self->{'local-bootstrap-packages'}	= \@allPkgs;
}

sub setupStage1C
{
	my $self = shift;

	vlog 1, "setting up stage1c for $self->{'vendor-os-name'}...";
	$self->stage1C_chrootAndInstallBasicSystem();
}

sub stage1C_chrootAndInstallBasicSystem
{
	my $self = shift;

	my $stage1bDir = "/$self->{stage1bSubdir}";
	vlog 2, "chrooting into $stage1bDir...";
	# chdir into stage1bDir...
	chdir $stage1bDir
		or die _tr("unable to chdir into <%s> (%s)", $stage1bDir, $!);
	# ...do chroot
	chroot "."
		or die _tr("unable to chroot into <%s> (%s)", $stage1bDir, $!);

	$ENV{PATH} = "/bin:/sbin:/usr/bin:/usr/sbin";
	my $stage1cDir = "/$self->{stage1cSubdir}";

	# install all prerequired bootstrap packages
	$self->{packager}->installPrerequiredPackages(
		$self->{'local-bootstrap-prereq-packages'}, $stage1cDir
	);

	# import any additional trusted package keys to rpm-DB:
	my $keyDir = "/trusted-package-keys";
	opendir(KEYDIR, $keyDir)
		or die _tr("unable to opendir <%s> (%s)", $keyDir, $!);
	my @keyFiles
		= map { "$keyDir/$_" }
		  grep { $_ !~ m[^(\.\.?|pubring.gpg)$] }
		  readdir(KEYDIR);
	closedir(KEYDIR);
	$self->{packager}->importTrustedPackageKeys(\@keyFiles, $stage1cDir);

	# install all other bootstrap packages
	$self->{packager}->installPackages(
		$self->{'local-bootstrap-packages'}, $stage1cDir
	);
}

sub stage1C_cleanupBasicSystem
{
	my $self = shift;

	my $stage1cDir
		= "$self->{'stage1aDir'}/$self->{'stage1bSubdir'}/$self->{'stage1cSubdir'}";
	if (system("mv $stage1cDir/* $self->{'system-path'}/")) {
		die _tr("unable to move final setup to <%s> (%s)",
				$self->{'system-path'}, $!);
	}
	if (system("rm -rf $self->{stage1aDir}")) {
		die _tr("unable to remove temporary folder <%s> (%s)",
				$self->{stage1aDir}, $!);
	}
}

sub setupStage1D
{
	my $self = shift;

	vlog 1, "setting up stage1d for $self->{'vendor-os-name'}...";
	$self->stage1D_setupPackageSources();
	$self->stage1D_updateBasicSystem();
	$self->stage1D_installPackageSelection();
}

sub updateStage1D
{
	my $self = shift;

	vlog 1, "updating $self->{'vendor-os-name'}...";
	$self->stage1D_updateBasicSystem();
}

sub stage1D_setupPackageSources()
{
	my $self = shift;

	vlog 1, "setting up package sources for meta packager...";
	my ($rk, $repo);
	while(($rk, $repo) = each %{$self->{'distro-info'}->{repository}}) {
		vlog 2, "setting up package source $rk...";
		$self->{'meta-packager'}->setupPackageSource($rk, $repo);
	}
}

sub stage1D_updateBasicSystem()
{
	my $self = shift;

	# chdir into systemDir...
	my $systemDir = $self->{'system-path'};
	vlog 2, "chrooting into $systemDir...";
	chdir $systemDir
		or die _tr("unable to chdir into <%s> (%s)", $systemDir, $!);
	# ...do chroot
	chroot "."
		or die _tr("unable to chroot into <%s> (%s)", $systemDir, $!);

	vlog 1, "updating basic system...";
	$self->{'meta-packager'}->updateBasicSystem();
}

sub stage1D_installPackageSelection
{
	my $self = shift;

	my $selectionName = $self->{'selection-name'};

	vlog 1, "installing package selection <$selectionName>...";
	my $pkgSelection = $self->{'distro-info'}->{selection}->{$selectionName};
	my @pkgs
		= grep { length($_) > 0 }
		  map { $_ =~ s[^\s*(.*?)\s*$][$1]; $_ }
		  split "\n", $pkgSelection;
	if (scalar(@pkgs) == 0) {
		vlog 0, _tr("No packages listed for selection <%s>, nothing to do.",
					$selectionName);
	} else {
		$self->{'meta-packager'}->installSelection(join " ", @pkgs);
	}
}

sub clone_fetchSource
{
	my $self = shift;
	my $source = shift;

	vlog 0, _tr("Cloning vendor-OS from <%s>...\n", $source);
	my (@includeList, @excludeList);
	foreach my $filterFile ("../lib/distro-info/clone-filter-common",
							"$self->{'distro-info-dir'}/clone-filter") {
		if (open(FILTER, "< $filterFile")) {
			while(<FILTER>) {
				push @includeList, $_ if /^\+\s+/;
				push @excludeList, $_ if /^\-\s+/;
			}
			close(FILTER);
		}
	}
	my $excludeIncludeList = join("", @includeList, @excludeList);
	vlog 1, "using exclude-include-filter:\n$excludeIncludeList\n";
	open(RSYNC, "| rsync -av --delete --exclude-from=- $source $self->{'system-path'}")
		or die _tr("unable to start rsync for source '%s', giving up! (%s)",
				   $source, $!);
	print RSYNC $excludeIncludeList;
	if (!close(RSYNC)) {
		die _tr("unable to clone from source '%s', giving up! (%s)",
				$source, $!);
	}
}

################################################################################
### utility functions
################################################################################
sub copyFile
{
	my $fileName = shift;
	my $dirName = shift;

	my $baseName = basename($fileName);
	my $targetName = "$dirName/$baseName";
	if (!-e $targetName) {
		my $targetDir = dirname($targetName);
		system("mkdir -p $targetDir") 	unless -d $targetDir;
		if (system("cp -p $fileName $targetDir/")) {
			die _tr("unable to copy file '%s' to dir '%s' (%s)",
					$fileName, $targetDir, $!);
		}
	}
}

sub fakeFile
{
	my $fullPath = shift;

	my $targetDir = dirname($fullPath);
	system("mkdir", "-p", $targetDir) 	unless -d $targetDir;
	if (system("touch", $fullPath)) {
		die _tr("unable to create file '%s' (%s)",
				$fullPath, $!);
	}
}

sub linkFile
{
	my $linkTarget = shift;
	my $linkName = shift;

	my $targetDir = dirname($linkName);
	system("mkdir -p $targetDir") 	unless -d $targetDir;
	if (system("ln -s $linkTarget $linkName")) {
		die _tr("unable to create link '%s' to '%s' (%s)",
				$linkName, $linkTarget, $!);
	}
}

sub slurpFile
{
	my $file = shift;
	open(F, "< $file")
		or die _tr("could not open file '%s' for reading! (%s)", $file, $!);
	$/ = undef;
	my $text = <F>;
	close(F);
	return $text;
}

sub string2Array
{
	my $str = shift;

	return
		grep { length($_) > 0 }
		map { $_ =~ s[^\s*(.+?)\s*$][$1]; $_ }
		split "\n", $str;
}

sub downloadFilesFrom
{
	my $files = shift;
	my $baseURL = shift;

	my @foundFiles;
	foreach my $fileVariantStr (@$files) {
		next unless $fileVariantStr =~ m[\S];
		my $foundFile;
		foreach my $file (split '\s+', $fileVariantStr) {
			vlog 2, "fetching <$file>...";
			if (system("wget", "$baseURL/$file") == 0) {
				$foundFile = basename($file);
				last;
			}
		}
		if (!defined $foundFile) {
			die _tr("unable to fetch <%s> from <%s> (%s)", $fileVariantStr,
					$baseURL, $!);
		}
		push @foundFiles, $foundFile;
	}
	return @foundFiles;
}

1;
################################################################################

=pod

=head1 NAME

OpenSLX::OSSetup::System::Base - the base class for all OSSetup backends

=head1 SYNOPSIS

  package OpenSLX::OSSetup::coolnewOS;

  use vars qw(@ISA $VERSION);
  @ISA = ('OpenSLX::OSSetup::Base');
  $VERSION = 1.01;

  use coolnewOS;

  sub new
  {
      my $class = shift;
      my $self = {};
      return bless $self, $class;
  }

  # override all methods of OpenSLX::OSSetup::Base in order to implement
  # a full OS-setup backend
  ...

I<The synopsis above outlines a class that implements a
OSSetup backend for the (imaginary) operating system B<coolnewOS>>

=head1 DESCRIPTION

This class defines the OSSetup interface for the OpenSLX.

Aim of the OSSetup abstraction is to make it possible to install a large set
of different operating systems transparently.

...

=cut
