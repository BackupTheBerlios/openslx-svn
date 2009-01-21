# Engine.pm - provides driver engine for the OSSetup API.
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
use OpenSLX::Utils;

use vars qw(%supportedDistros);

%supportedDistros = (
	'debian-3.1'
		=> { module => 'Debian_3_1', support => 'clone' },
	'debian-4.0'
		=> { module => 'Debian_4_0', support => 'clone' },
	'fedora-6'
		=> { module => 'Fedora_6', support => 'clone,install' },
	'fedora-6-x86_64'
		=> { module => 'Fedora_6_x86_64', support => 'clone' },
	'gentoo-2005.1'
		=> { module => 'Gentoo_2005_1', support => 'clone' },
	'gentoo-2006.1'
		=> { module => 'Gentoo_2006_1', support => 'clone' },
	'mandriva-2007.0'
		=> { module => 'Mandriva_2007_0', support => 'clone' },
	'suse-9.3'
		=> { module => 'SUSE_9_3', support => 'clone' },
	'suse-10.0'
		=> { module => 'SUSE_10_0', support => 'clone' },
	'suse-10.0-x86_64'
		=> { module => 'SUSE_10_0_x86_64', support => 'clone' },
	'suse-10.1'
		=> { module => 'SUSE_10_1', support => 'clone,install' },
	'suse-10.1-x86_64'
		=> { module => 'SUSE_10_1_x86_64', support => 'clone' },
	'suse-10.2'
		=> { module => 'SUSE_10_2', support => 'clone,install' },
	'suse-10.2-x86_64'
		=> { module => 'SUSE_10_2_x86_64', support => 'clone,install' },
	'ubuntu-6.06'
		=> { module => 'Ubuntu_6_06', support => 'clone' },
	'ubuntu-6.10'
		=> { module => 'Ubuntu_6_10', support => 'clone' },
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
	my $vendorOSName = shift;
	my $actionType = shift;

	if ($vendorOSName !~ m[^([^\-]+\-[^\-]+)(?:\-(.+))?]) {
		die _tr("Given vendor-OS has unknown format, expected '<name>-<release>[-<selection>]'\n");
	}
	$self->{'vendor-os-name'} = $vendorOSName;
	$self->{'action-type'} = $actionType;
	my $distroName = $1;
	my $selectionName = $2 || 'default';
	$self->{'distro-name'} = $distroName;
	$self->{'selection-name'} = $selectionName;
	if (!exists $supportedDistros{lc($distroName)}) {
		print _tr("Sorry, distro '%s' is unsupported.\n", $distroName);
		print _tr("List of supported distros:\n\t");
		print join("\n\t", sort keys %supportedDistros)."\n";
		exit 1;
	}
	my $support = $supportedDistros{lc($distroName)}->{support};
	if ($actionType eq 'install' && $support !~ m[install]i) {
		print _tr("Sorry, distro '%s' can not be installed, only cloned.\n",
				  $distroName);
		exit 1;
	}

	# load module for the requested distro:
	my $distroModule
		= "OpenSLX::OSSetup::Distro::"
			.$supportedDistros{lc($distroName)}->{module};
	unless (eval "require $distroModule") {
		if ($! == 2) {
			die _tr("Distro-module <%s> not found!\n", $distroModule);
		} else {
			die _tr("Unable to load distro-module <%s> (%s)\n", $distroModule, $@);
		}
	}
	my $modVersion = $distroModule->VERSION;
	if ($modVersion < 1.01) {
		die _tr("Could not load module <%s> (Version <%s> required, but <%s> found)\n",
				$distroModule, 1.01, $modVersion);
	}
	my $distro = $distroModule->new;
	$distro->initialize($self);
	$self->{distro} = $distro;

	# setup path to distribution-specific info:
	my $distroInfoDir = "../lib/distro-info/$distro->{'base-name'}";
	if (!-d $distroInfoDir) {
		die _tr("unable to find distro-info for distro '%s'\n", $distro->{'base-name'});
	}
	$self->{'distro-info-dir'} = $distroInfoDir;
	$self->readDistroInfo();

	if (!$self->{'action-type'} eq 'install'
	&& !exists $self->{'distro-info'}->{'selection'}->{$selectionName}) {
		die _tr("selection '%s' is unknown to distro '%s'\n",
				$selectionName, $distro->{'base-name'})
			."These selections are available:\n\t"
			.join("\n\t", keys %{$self->{'distro-info'}->{'selection'}})
			."\n";
	}

	$self->{'vendor-os-path'}
		= "$openslxConfig{'stage1-path'}/$self->{'vendor-os-name'}";
	vlog 1, "vendor-OS will be installed to '$self-vendor-os-path'}'";

	$self->createPackager();
	$self->createMetaPackager();

}

sub installVendorOS
{
	my $self = shift;

	my $installInfoFile = "$self->{'vendor-os-path'}/.openslx-install-info";
	if (-e $installInfoFile) {
		die _tr("vendor-OS '%s' already exists, giving up!\n", $self->{'vendor-os-path'});
	}
	$self->createVendorOSPath();

	$self->setupStage1A();
	executeInSubprocess( sub {
		# some tasks that involve a chrooted environment:
		changePersonalityIfNeeded($self->{distro}->{'base-name'});
		$self->setupStage1B();
		$self->setupStage1C();
	});
	$self->stage1C_cleanupBasicVendorOS();
	executeInSubprocess( sub {
		# another task that involves a chrooted environment:
		changePersonalityIfNeeded($self->{distro}->{'base-name'});
		$self->setupStage1D();
	});
	slxsystem("touch $installInfoFile");
		# just touch the file, in order to indicate a proper installation
	vlog 0, _tr("Vendor-OS <%s> installed succesfully.\n",
				$self->{'vendor-os-name'});

	$self->addInstalledVendorOSToConfigDB();
}

sub cloneVendorOS
{
	my $self = shift;
	my $source = shift;

	$self->{'clone-source'} = $source;
	my $lastCloneSource;
	my $cloneInfoFile = "$self->{'vendor-os-path'}/.openslx-clone-info";
	my $isReClone;
	if (-e $self->{'vendor-os-path'}) {
		my $installInfoFile = "$self->{'vendor-os-path'}/.openslx-install-info";
		if (-e $installInfoFile) {
			# oops, given vendor-os has been installed, not cloned, we complain:
			die _tr("The vendor-OS '%s' exists but it is no clone, refusing to clobber!\nPlease delete the folder manually, if that's really what you want...\n",
					$self->{'vendor-os-path'});
		} elsif (-e $cloneInfoFile) {
			# check if last and current source match:
			my $cloneInfo = slurpFile($cloneInfoFile);
			if ($cloneInfo =~ m[^source\s*=\s*(.+?)\s*$]ims) {
				$lastCloneSource = $1;
			}
			if ($source ne $lastCloneSource) {
				# protect user from confusing sources (still allowed, though):
				my $yes = _tr('yes');
				my $no = _tr('no');
				print _tr("Last time this vendor-OS was cloned, it has been cloned from '%s', now you specified a different source: '%s'\nWould you still like to proceed (%s/%s)? ",
						$lastCloneSource, $source, $yes, $no);
				my $answer = <STDIN>;
				exit 5		unless $answer =~ m[^\s*$yes]i;
			}
			$isReClone = 1;
		} else {
			# Neither the install-info nor the clone-info file exists. This
			# probably means that the folder has been created by an older
			# version of the tools. There's not much we can do, we simply
			# trust our user and assume that he knows what he's doing.
		}
	}

	$self->createVendorOSPath();

	$self->clone_fetchSource($source);
	if ($source ne $lastCloneSource) {
		open(CLONE_INFO, "> $cloneInfoFile")
			or die _tr("unable to create clone-info file '%s', giving up! (%s)\n",
					   $cloneInfoFile);
		print CLONE_INFO "source=$source";
		close CLONE_INFO;
	}
	if ($isReClone) {
		vlog 0, _tr("Vendor-OS <%s> has been re-cloned succesfully.\n",
					$self->{'vendor-os-name'});
	} else {
		vlog 0, _tr("Vendor-OS <%s> has been cloned succesfully.\n",
					$self->{'vendor-os-name'});
	}

	$self->addInstalledVendorOSToConfigDB();
}

sub updateVendorOS
{
	my $self = shift;

	if (!-e $self->{'vendor-os-path'}) {
		die _tr("can't update vendor-OS '%s', since it doesn't exist!\n",
				$self->{'vendor-os-path'});
	}
	executeInSubprocess( sub {
		changePersonalityIfNeeded($self->{distro}->{'base-name'});
		$self->updateStage1D();
	});
	vlog 0, _tr("Vendor-OS <%s> updated succesfully.\n",
				$self->{'vendor-os-name'});
}

sub addInstalledVendorOSToConfigDB
{
	my $self = shift;

	if (!-e $self->{'vendor-os-path'}) {
		die _tr("can't import vendor-OS '%s', since it doesn't exist!\n",
				$self->{'vendor-os-path'});
	}
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
			die _tr("Could not load module <%s> (Version <%s> required, but <%s> found)\n",
					$configDBModule, 1.01, $modVersion);
		}
		my $openslxDB = $configDBModule->new();
		$openslxDB->connect();
		# insert new vendor-os if it doesn't already exist in DB:
		my $vendorOSName = $self->{'vendor-os-name'};
		my $vendorOS
			= $openslxDB->fetchVendorOSByFilter({ 'name' => $vendorOSName });
		if (defined $vendorOS) {
			if ($self->{'clone-source'} ne $vendorOS->{'clone_source'}) {
				$openslxDB->changeVendorOS($vendorOS->{id}, {
					'clone_source' => $self->{'clone-source'},
				});
				vlog 0, _tr("Vendor-OS '%s' has been updated in OpenSLX-database.\n",
							$vendorOSName);
			} else {
				vlog 0, _tr("No need to change vendor-OS '%s' in OpenSLX-database.\n",
							$vendorOSName);
			}
		} else {
			my $data = {
				'name' => $vendorOSName,
			};
			if (length($self->{'clone-source'})) {
				$data->{'clone_source'} = $self->{'clone-source'};
			}
			my $id = $openslxDB->addVendorOS($data);

			vlog 0, _tr("Vendor-OS '%s' has been added to DB (ID=%s).\n",
						$vendorOSName, $id);
		}

		$openslxDB->disconnect();
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

sub createVendorOSPath
{
	my $self = shift;

	if (slxsystem("mkdir -p $self->{'vendor-os-path'}")) {
		die _tr("unable to create directory '%s', giving up! (%s)\n",
				$self->{'vendor-os-path'}, $!);
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
		die _tr("Could not load module <%s> (Version <%s> required, but <%s> found)\n",
				$packagerModule, 1.01, $modVersion);
	}
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
		die _tr("Could not load module <%s> (Version <%s> required, but <%s> found)\n",
				$metaPackagerModule, 1.01, $modVersion);
	}
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
	$self->{stage1aDir} = "$self->{'vendor-os-path'}/stage1a";
	$self->{stage1bSubdir} = 'slxbootstrap';
	$self->{stage1cSubdir} = 'slxfinal';

	# we create *all* of the above folders by creating stage1cDir:
	my $stage1cDir
		= "$self->{'stage1aDir'}/$self->{'stage1bSubdir'}/$self->{'stage1cSubdir'}";
	if (slxsystem("mkdir -p $stage1cDir")) {
		die _tr("unable to create directory '%s', giving up! (%s)\n",
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
	if (slxsystem($cmd)) {
		die _tr("unable to copy folder with pre-required files to folder <%s> (%s)\n",
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
	if (slxsystem($cmd)) {
		die _tr("unable to copy folder with trusted package keys to folder <%s> (%s)\n",
				$stage1bDir, $!);
	}
	slxsystem("chmod 444 $stage1bDir/trusted-package-keys/*");

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
	if (!-e "$stage1cDir/dev/null" && slxsystem("mknod $stage1cDir/dev/null c 1 3")) {
		die _tr("unable to create node <%s> (%s)\n", "$stage1cDir/dev/null", $!);
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
		or die _tr("unable to chdir into <%s> (%s)\n", $self->{stage1aDir}, $!);
	# ...do chroot
	chroot "."
		or die _tr("unable to chroot into <%s> (%s)\n", $self->{stage1aDir}, $!);

	$ENV{PATH} = "/bin:/sbin:/usr/bin:/usr/sbin";

	# chdir into slxbootstrap, as we want to drop packages into there:
	chdir "/$self->{stage1bSubdir}"
		or die _tr("unable to chdir into <%s> (%s)\n", "/$self->{stage1bSubdir}", $!);

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
	$self->stage1C_chrootAndInstallBasicVendorOS();
}

sub stage1C_chrootAndInstallBasicVendorOS
{
	my $self = shift;

	my $stage1bDir = "/$self->{stage1bSubdir}";
	vlog 2, "chrooting into $stage1bDir...";
	# chdir into stage1bDir...
	chdir $stage1bDir
		or die _tr("unable to chdir into <%s> (%s)\n", $stage1bDir, $!);
	# ...do chroot
	chroot "."
		or die _tr("unable to chroot into <%s> (%s)\n", $stage1bDir, $!);

	$ENV{PATH} = "/bin:/sbin:/usr/bin:/usr/sbin";
	my $stage1cDir = "/$self->{stage1cSubdir}";

	# install all prerequired bootstrap packages
	$self->{packager}->installPrerequiredPackages(
		$self->{'local-bootstrap-prereq-packages'}, $stage1cDir
	);

	# import any additional trusted package keys to rpm-DB:
	my $keyDir = "/trusted-package-keys";
	opendir(KEYDIR, $keyDir)
		or die _tr("unable to opendir <%s> (%s)\n", $keyDir, $!);
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

sub stage1C_cleanupBasicVendorOS
{
	my $self = shift;

	my $stage1cDir
		= "$self->{'stage1aDir'}/$self->{'stage1bSubdir'}/$self->{'stage1cSubdir'}";
	if (slxsystem("mv $stage1cDir/* $self->{'vendor-os-path'}/")) {
		die _tr("unable to move final setup to <%s> (%s)\n",
				$self->{'vendor-os-path'}, $!);
	}
	if (slxsystem("rm -rf $self->{stage1aDir}")) {
		die _tr("unable to remove temporary folder <%s> (%s)\n",
				$self->{stage1aDir}, $!);
	}
}

sub setupStage1D
{
	my $self = shift;

	vlog 1, "setting up stage1d for $self->{'vendor-os-name'}...";
	$self->stage1D_setupPackageSources();
	$self->stage1D_updateBasicVendorOS();
	$self->stage1D_installPackageSelection();
}

sub updateStage1D
{
	my $self = shift;

	vlog 1, "updating $self->{'vendor-os-name'}...";
	$self->stage1D_updateBasicVendorOS();
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

sub stage1D_updateBasicVendorOS()
{
	my $self = shift;

	# chdir into vendor-os folder...
	my $osDir = $self->{'vendor-os-path'};
	vlog 2, "chrooting into $osDir...";
	chdir $osDir
		or die _tr("unable to chdir into <%s> (%s)\n", $osDir, $!);
	# ...do chroot
	chroot "."
		or die _tr("unable to chroot into <%s> (%s)\n", $osDir, $!);

	vlog 1, "updating basic vendor-os...";
	$self->{'meta-packager'}->updateBasicVendorOS();
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

	vlog 0, _tr("Cloning vendor-OS from '%s' to '%s'...\n", $source,
				$self->{'vendor-os-path'});
	my $excludeIncludeList = $self->clone_determineIncludeExcludeList();
	vlog 1, "using exclude-include-filter:\n$excludeIncludeList\n";
	open(RSYNC, "| rsync -av --delete --exclude-from=- $source $self->{'vendor-os-path'}")
		or die _tr("unable to start rsync for source '%s', giving up! (%s)\n",
				   $source, $!);
	print RSYNC $excludeIncludeList;
	if (!close(RSYNC)) {
		die _tr("unable to clone from source '%s', giving up! (%s)\n",
				$source, $!);
	}
}

sub clone_determineIncludeExcludeList
{
	my $self = shift;

	my $localFilterFile = "../lib/distro-info/clone-filter.local";
	my $includeExcludeList = slurpFile($localFilterFile, 1);
	$includeExcludeList .= $self->{distro}->{'clone-filter'};
	$includeExcludeList =~ s[^\s+][]igms;
		# remove any leading whitespace, as rsync doesn't like it
	return $includeExcludeList;
}


################################################################################
### utility functions
################################################################################
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
	my @contFlags = ('-c');
		# default to trying to continue partial downloads
	foreach my $fileVariantStr (@$files) {
		next unless $fileVariantStr =~ m[\S];
		my $foundFile;
		foreach my $file (split '\s+', $fileVariantStr) {
			vlog 2, "fetching <$file>...";
retry:
			if (slxsystem("wget", @contFlags, "$baseURL/$file") == 0) {
				$foundFile = basename($file);
				last;
			}
			if (scalar(@contFlags)) {
				# server probably doesn't support continuing downloads, so we
				# remove the continue-flag and retry:
				shift @contFlags;
				goto retry;
			}
		}
		if (!defined $foundFile) {
			die _tr("unable to fetch <%s> from <%s> (%s)\n", $fileVariantStr,
					$baseURL, $!);
		}
		push @foundFiles, $foundFile;
	}
	return @foundFiles;
}

sub changePersonalityIfNeeded {
	my $distroName = shift;

	my $arch = `uname -m`;
	if ($arch =~ m[64] && $distroName !~ m[_64]) {
		# trying to handle a 32-bit vendor-OS on a 64-bit machine, so we change 
		# the personality accordingly (from 64-bit to 32-bit):
		require 'syscall.ph'
			or die _tr("unable to load '%s'\n", 'syscall.ph');
		require 'linux/personality.ph'
			or die _tr("unable to load '%s'\n", 'linux/personality.ph');
		no strict;
		syscall &SYS_personality, PER_LINUX32();
	}
}

1;
################################################################################

=pod

=head1 NAME

OpenSLX::OSSetup::Engine - driver engine for OSSetup API

=head1 SYNOPSIS

...

=cut
