# Copyright (c) 2006, 2007 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your suggestions, praise, or complaints to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org/
# -----------------------------------------------------------------------------
# Engine.pm
#	- provides driver engine for the OSSetup API.
# -----------------------------------------------------------------------------
package OpenSLX::OSSetup::Engine;

use strict;
use warnings;

our (@ISA, @EXPORT, $VERSION);
$VERSION = 1.01;    # API-version . implementation-version

use Exporter;
@ISA = qw(Exporter);

@EXPORT = qw(
	%supportedDistros
);

use File::Basename;
use OpenSLX::Basics;
use OpenSLX::Utils;

use vars qw(%supportedDistros);

%supportedDistros = (
	'debian-3.1' => {
		module => 'Debian_3_1',       support => 'clone,install'
	},
	'debian-4.0' => {
		module => 'Debian_4_0',       support => 'clone,install'
	},
	'fedora-6' => {
		module => 'Fedora_6',         support => 'clone,install'
	},
	'fedora-6_x86_64' => {
		module => 'Fedora_6_x86_64',  support => 'clone,install'
	},
	'gentoo-2005.1' => {
		module => 'Gentoo',    		  support => 'clone'
	},
	'gentoo-2006.1' => {
		module => 'Gentoo',           support => 'clone'
	},
	'mandriva-2007.0' => {
		module => 'Mandriva_2007_0',  support => 'clone'
	},
	'suse-9.3' => {
		module => 'SUSE_9_3',         support => 'clone'
	},
	'suse-10.0'	=> {
		module => 'SUSE_10_0',        support => 'clone'
	},
	'suse-10.0_x86_64' => {
		module => 'SUSE_10_0_x86_64', support => 'clone'
	},
	'suse-10.1' => {
		module => 'SUSE_10_1',        support => 'clone,install'
	},
	'suse-10.1_x86_64' => {
		module => 'SUSE_10_1_x86_64', support => 'clone,install'
	},
	'suse-10.2' => {
		module => 'SUSE_10_2',        support => 'clone,install'
	},
	'suse-10.2_x86_64' => {
		module => 'SUSE_10_2_x86_64', support => 'clone,install'
	},
	'ubuntu-6.06' => {
		module => 'Ubuntu_6_06',      support => 'clone'
	},
	'ubuntu-6.10' => {
		module => 'Ubuntu_6_10',      support => 'clone,install'
	},
	'ubuntu-7.04' => { 
		module => 'Ubuntu_7_04',      support => 'clone,install'
	},
);

################################################################################
### interface methods
################################################################################
sub new
{
	my $class = shift;

	my $self = {};

	return bless $self, $class;
}

sub DESTROY
{
	my $self = shift;

	my $httpServerPID = $self->{'local-http-server-master-pid'} || '0';
	if ($httpServerPID == $$) {
		# we are the master process, so we clean up all the servers that we
		# have started:
		while (my ($localURL, $pid) = each %{$self->{'local-http-servers'}}) {
			vlog(1, _tr("stopping local HTTP-server for URL '%s'.", $localURL));
			kill TERM => $pid;
		}
	}
	return;
}

sub initialize
{
	my $self         = shift;
	my $vendorOSName = shift;
	my $actionType   = shift;

	if ($vendorOSName !~ m[^([^\-]+\-[^\-]+)(?:\-(.+))?]) {
		die _tr(    
			"Given vendor-OS has unknown format, expected '<name>-<release>[-<selection>]'\n"
		);
	}
	my $distroName = $1;
	my $selectionName = $2 || 'default';
	$self->{'vendor-os-name'} = $vendorOSName;
	$self->{'action-type'}    = $actionType;
	$self->{'distro-name'}    = lc($distroName);
	$self->{'selection-name'} = $selectionName;
	$self->{'clone-source'}   = '';
	if (!exists $supportedDistros{lc($distroName)}) {
		print _tr("Sorry, distro '%s' is unsupported.\n", $distroName);
		print _tr("List of supported distros:\n\t");
		print join("\n\t", sort keys %supportedDistros) . "\n";
		exit 1;
	}
	my $support = $supportedDistros{lc($distroName)}->{support};
	if ($support !~ m[install]i) {
		if ($actionType eq 'install') {
			print _tr(
				"Sorry, distro '%s' can not be installed, only cloned!\n", 
				$distroName
			);
			exit 1;
		}
		elsif ($actionType eq 'update') {
			print _tr(
				"Sorry, vendor-OS '%s' has been cloned, don't know how to update it!\n", 
				$distroName
			);
			exit 1;
		}
		elsif ($actionType eq 'shell') {
			print _tr(
				"Sorry, vendor-OS '%s' has been cloned, no support for chrooted shell available!\n", 
				$distroName
			);
			exit 1;
		}
	}

	# load module for the requested distro:
	my $distro;
	my $distroClass = $supportedDistros{lc($distroName)}->{module};
	if ($actionType =~ m{^(install|update|shell)}) {
		$distro = instantiateClass("OpenSLX::OSSetup::Distro::$distroClass");
	}
	else {
		if (!eval { 
			$distro = instantiateClass("OpenSLX::OSSetup::Distro::$distroClass") 
		}) {
			vlog(2, "could not load distro module '$distroClass' ($@) ...");
			vlog(2, "falling back to module 'Any_Clone'");
			# allow fallback to generic clone module, such that we can clone
			# distro's for which there is no specific distro-module yet
			# (like for example for Gentoo):
			$distro = instantiateClass("OpenSLX::OSSetup::Distro::Any_Clone") 
		}
	}

	$distro->initialize($self);
	$self->{distro} = $distro;

	if ($actionType =~ m{^(install|update|shell)}) {
		# setup path to distribution-specific info:
		my $sharedDistroInfoDir 
			= "$openslxConfig{'base-path'}/share/distro-info/$self->{'distro-name'}";
		if (!-d $sharedDistroInfoDir) {
			die _tr(
				"unable to find shared distro-info in '%s'\n",
				$sharedDistroInfoDir
			);
		}
		$self->{'shared-distro-info-dir'} = $sharedDistroInfoDir;
		my $configDistroInfoDir =
			"$openslxConfig{'config-path'}/distro-info/$self->{'distro-name'}";
		if (!-d $configDistroInfoDir) {
			die _tr(
				"unable to find configurable distro-info in '%s'\n",
				$configDistroInfoDir
			);
		}
		$self->{'config-distro-info-dir'} = $configDistroInfoDir;
		$self->_readDistroInfo();
	}

	if (!$self->{'action-type'} eq 'install'
		&& !exists $self->{'distro-info'}->{'selection'}->{$selectionName})
	{
		die(
			_tr(
				"selection '%s' is unknown to distro '%s'\n",
				$selectionName, $self->{'distro-name'}
			)
			. _tr("These selections are available:\n\t")
			. join("\n\t", keys %{$self->{'distro-info'}->{'selection'}})
			. "\n"
		);
	}

	$self->{'vendor-os-path'} 
		= "$openslxConfig{'private-path'}/stage1/$self->{'vendor-os-name'}";
	vlog(1, "vendor-OS path is '$self->{'vendor-os-path'}'");

	if ($actionType =~ m{^(install|update|shell)}) {
		$self->_createPackager();
		$self->_createMetaPackager();
	}
	return;
}

sub installVendorOS
{
	my $self = shift;

	my $installInfoFile = "$self->{'vendor-os-path'}/.openslx-install-info";
	if (-e $installInfoFile) {
		die _tr("vendor-OS '%s' already exists, giving up!\n",
			$self->{'vendor-os-path'});
	}
	$self->_createVendorOSPath();

	$self->_startLocalURLServersAsNeeded();

	my $baseSystemFile = "$self->{'vendor-os-path'}/.openslx-base-system";
	if (-e $baseSystemFile) {
		vlog(0, _tr("found existing base system, continuing...\n"));
	}
	else {
		# basic setup, stage1a-c:
		$self->_setupStage1A();
		callInSubprocess(
			sub {
				# some tasks that involve a chrooted environment:
				$self->_changePersonalityIfNeeded();
				$self->_setupStage1B();
				$self->_setupStage1C();
			}
		);
		$self->_stage1C_cleanupBasicVendorOS();
		# just touch the file, in order to indicate a basic system:
		slxsystem("touch $baseSystemFile");
	}
	callInSubprocess(
		sub {
			# another task that involves a chrooted environment:
			$self->_changePersonalityIfNeeded();
			$self->_setupStage1D();
		}
	);

	# create the install-info file, in order to indicate a proper installation:
	spitFile($installInfoFile,
		"SLX_META_PACKAGER=$self->{distro}->{'meta-packager-type'}\n");
	slxsystem("rm $baseSystemFile");

	# no longer needed, we have a full system now
	vlog(
		0,
		_tr(
			"Vendor-OS '%s' installed succesfully.\n",
			$self->{'vendor-os-name'}
		)
	);

	$self->_touchVendorOS();
	$self->addInstalledVendorOSToConfigDB();
	return;
}

sub cloneVendorOS
{
	my $self   = shift;
	my $source = shift;

	if (substr($source, -1, 1) ne '/') {
		# make sure source path ends with a slash, as otherwise, the
		# last folder would be copied (but we only want its contents).
		$source .= '/';
	}

	$self->{'clone-source'} = $source;
	my $lastCloneSource = '';
	my $cloneInfoFile = "$self->{'vendor-os-path'}/.openslx-clone-info";
	my $isReClone;
	if (-e $self->{'vendor-os-path'}) {
		my $installInfoFile = "$self->{'vendor-os-path'}/.openslx-install-info";
		if (-e $installInfoFile) {
			# oops, given vendor-os has been installed, not cloned, we complain:
			croak(
				_tr(
					"The vendor-OS '%s' exists but it is no clone, refusing to clobber!\nPlease delete the folder manually, if that's really what you want...\n",
					$self->{'vendor-os-path'}
				)
			);
		}
		elsif (-e $cloneInfoFile) {
			# check if last and current source match:
			my $cloneInfo = slurpFile($cloneInfoFile);
			if ($cloneInfo =~ m[^source\s*=\s*(.+?)\s*$]ims) {
				$lastCloneSource = $1;
			}
			if ($source ne $lastCloneSource) {
				# protect user from confusing sources (still allowed, though):
				my $yes = _tr('yes');
				my $no  = _tr('no');
				print _tr(
					"Last time this vendor-OS was cloned, it has been cloned from '%s', now you specified a different source: '%s'\nWould you still like to proceed (%s/%s)? ",
					$lastCloneSource, $source, $yes, $no
				);
				my $answer = <STDIN>;
				exit 5 unless $answer =~ m[^\s*$yes]i;
			}
			$isReClone = 1;
		}
		else {
			# Neither the install-info nor the clone-info file exists. This
			# probably means that the folder has been created by an older
			# version of the tools. There's not much we can do, we simply
			# trust our user and assume that he knows what he's doing.
		}
	}

	$self->_createVendorOSPath();

	$self->_clone_fetchSource($source);
	if ($source ne $lastCloneSource) {
		spitFile($cloneInfoFile, "source=$source\n");
	}
	if ($isReClone) {
		vlog(
			0,
			_tr(
				"Vendor-OS '%s' has been re-cloned succesfully.\n",
				$self->{'vendor-os-name'}
			)
		);
	}
	else {
		vlog(
			0,
			_tr(
				"Vendor-OS '%s' has been cloned succesfully.\n",
				$self->{'vendor-os-name'}
			)
		);
	}

	$self->_touchVendorOS();
	$self->addInstalledVendorOSToConfigDB();
	return;
}

sub updateVendorOS
{
	my $self = shift;

	if (!-e $self->{'vendor-os-path'}) {
		die _tr("can't update vendor-OS '%s', since it doesn't exist!\n",
			$self->{'vendor-os-path'});
	}

	$self->_startLocalURLServersAsNeeded();

	callInSubprocess(
		sub {
			$self->_changePersonalityIfNeeded();
			$self->_updateStage1D();
		}
	);

	$self->_touchVendorOS();
	vlog(
		0,
		_tr("Vendor-OS '%s' updated succesfully.\n", $self->{'vendor-os-name'})
	);
	return;
}

sub startChrootedShellForVendorOS
{
	my $self = shift;

	if (!-e $self->{'vendor-os-path'}) {
		die _tr(
			"can't start chrooted shell for vendor-OS '%s', since it doesn't exist!\n",
			$self->{'vendor-os-path'}
		);
	}

	$self->_startLocalURLServersAsNeeded();

	callInSubprocess(
		sub {
			$self->_changePersonalityIfNeeded();
			$self->_startChrootedShellInStage1D();
		}
	);

	$self->_touchVendorOS();
	vlog(
		0,
		_tr(
			"Chrooted shell for vendor-OS '%s' has been closed.\n",
			$self->{'vendor-os-name'}
		)
	);
	return;
}

sub callChrootedFunctionForVendorOS
{
	my $self         = shift;
	my $function     = shift;
	my $updateConfig = shift || 0;

	if (!-e $self->{'vendor-os-path'}) {
		die _tr(
			"can't call chrooted function for vendor-OS '%s', since it doesn't exist!\n",
			$self->{'vendor-os-path'}
		);
	}

	$self->_startLocalURLServersAsNeeded();

	callInSubprocess(
		sub {
			$self->_changePersonalityIfNeeded();
			$self->_callChrootedFunction({
				chrootDir    => $self->{'vendor-os-path'}, 
				function     => $function,
				updateConfig => $updateConfig,
			});
		}
	);

	$self->_touchVendorOS();
	vlog(
		0,
		_tr(
			"Chrooted function for vendor-OS '%s' has finished.\n",
			$self->{'vendor-os-name'}
		)
	);
	return;
}

sub removeVendorOS
{
	my $self = shift;

	vlog(
		0,
		_tr("removing vendor-OS folder '%s'...", $self->{'vendor-os-path'})
	);
	if (system("rm -r $self->{'vendor-os-path'}")) {
		vlog(
			0,
			_tr("* unable to remove vendor-OS '%s'!", $self->{'vendor-os-path'})
		);
	}
	else {
		vlog(
			0,
			_tr(
				"Vendor-OS '%s' removed succesfully.\n",
				$self->{'vendor-os-name'}
			)
		);
	}
	$self->removeVendorOSFromConfigDB();
	return;
}

sub addInstalledVendorOSToConfigDB
{
	my $self = shift;

	if (!-e $self->{'vendor-os-path'}) {
		die _tr(
			"can't import vendor-OS '%s', since it doesn't exist!\n",
			$self->{'vendor-os-path'}
		);
	}
	my $openslxDB = instantiateClass("OpenSLX::ConfigDB");
	$openslxDB->connect();

	# insert new vendor-os if it doesn't already exist in DB:
	my $vendorOSName = $self->{'vendor-os-name'};
	my $vendorOS = $openslxDB->fetchVendorOSByFilter({'name' => $vendorOSName});
	if (defined $vendorOS) {
		if ($vendorOS->{'clone_source'}
		&& $self->{'clone-source'} ne $vendorOS->{'clone_source'}) {
			$openslxDB->changeVendorOS(
				$vendorOS->{id},
				{ 'clone_source' => $self->{'clone-source'} }
			);
			vlog(
				0,
				_tr(
					"Vendor-OS '%s' has been updated in OpenSLX-database.\n",
					$vendorOSName
				)
			);
		}
		else {
			vlog(
				0,
				_tr(
					"No need to change vendor-OS '%s' in OpenSLX-database.\n",
					$vendorOSName
				)
			);
		}
	}
	else {
		my $data = {'name' => $vendorOSName,};
		if (length($self->{'clone-source'})) {
			$data->{'clone_source'} = $self->{'clone-source'};
		}
		my $id = $openslxDB->addVendorOS($data);

		vlog(
			0,
			_tr(
				"Vendor-OS '%s' has been added to DB (ID=%s).\n",
				$vendorOSName, $id
			)
		);
	}

	$openslxDB->disconnect();
	return;
}

sub removeVendorOSFromConfigDB
{
	my $self = shift;

	my $openslxDB = instantiateClass("OpenSLX::ConfigDB");
	$openslxDB->connect();

	my $vendorOSName = $self->{'vendor-os-name'};
	my $vendorOS = $openslxDB->fetchVendorOSByFilter({'name' => $vendorOSName});
	if (!defined $vendorOS) {
		vlog(
			0,
			_tr(
				"Vendor-OS '%s' didn't exist in OpenSLX-database.\n",
				$vendorOSName
			)
		);
	}
	else {
		# remove all exports (and systems) using this vendor-OS and then
		# remove the vendor-OS itself:
		my @exports = $openslxDB->fetchExportByFilter(
			{'vendor_os_id' => $vendorOS->{id}});
		foreach my $export (@exports) {
			my $osExportEngine = instantiateClass("OpenSLX::OSExport::Engine");
			$osExportEngine->initializeFromExisting($export->{name});
			vlog(
				0,
				_tr(
					"purging export '%s', since it belongs to the vendor-OS being deleted...",
					$export->{name}
				)
			);
			$osExportEngine->purgeExport();
		}

		$openslxDB->removeVendorOS($vendorOS->{id});
		vlog(
			0,
			_tr("Vendor-OS '%s' has been removed from DB!\n", $vendorOSName)
		);
	}

	$openslxDB->disconnect();
	return;
}

sub pickKernelFile
{
	my $self = shift;

	return $self->{distro}->pickKernelFile(@_);
}

################################################################################
### implementation methods
################################################################################
sub _readDistroInfo
{
	my $self = shift;

	vlog(1, "reading configuration info for $self->{'vendor-os-name'}...");

	# merge user-provided configuration distro defaults...
	my %repository = %{$self->{distro}->{config}->{repository}};
	my %selection  = %{$self->{distro}->{config}->{selection}};
	my %excludes 
		= defined $self->{distro}->{config}->{excludes}
			? %{$self->{distro}->{config}->{excludes}}
			: ();
	my $package_subdir  = $self->{distro}->{config}->{'package-subdir'};
	my $prereq_packages = $self->{distro}->{config}->{'prereq-packages'};
	my $bootstrap_packages = $self->{distro}->{config}->{'bootstrap-packages'};
	my $metapackager_packages =
		$self->{distro}->{config}->{'metapackager-packages'};

	my $file = "$self->{'config-distro-info-dir'}/settings";
	if (-e $file) {
		vlog(2, "reading configuration file $file...");
		my $config = slurpFile($file);
		if (!eval "$config" && length($@)) {
			die _tr("error in config-file '%s' (%s)", $file, $@) . "\n";
		}
	}

	# ...expand selection definitions...
	foreach my $selKey (keys %selection) {
		$selection{$selKey} =~ s[<<<([^>]+)>>>][$selection{$1}]eg;
	}

	# ...expand selection definitions...
	foreach my $exclKey (keys %excludes) {
		$excludes{$exclKey} =~ s[<<<([^>]+)>>>][$excludes{$1}]eg;
	}

	# ...and store merged config:
	$self->{'distro-info'} = {
		'package-subdir'            => $package_subdir,
		'prereq-packages'           => $prereq_packages,
		'bootstrap-packages'        => $bootstrap_packages,
		'metapackager-packages'     => $metapackager_packages,
		'repository'                => \%repository,
		'selection'                 => \%selection,
		'excludes'                  => \%excludes,
	};

	if ($openslxConfig{'verbose-level'} >= 2) {
		# dump distro-info, if asked for:
		foreach my $r (sort keys %repository) {
			vlog(2, "repository '$r':");
			foreach my $k (sort keys %{$repository{$r}}) {
				vlog(3, "\t$k = '$repository{$r}->{$k}'");
			}
		}
		foreach my $s (sort keys %selection) {
			my @selLines = split "\n", $selection{$s};
			vlog(2, "selection '$s':");
			foreach my $sl (@selLines) {
				vlog(3, "\t$sl");
			}
		}
		foreach my $e (sort keys %excludes) {
			my @exclLines = split "\n", $excludes{$e};
			vlog(2, "excludes for '$e':");
			foreach my $excl (@exclLines) {
				vlog(3, "\t$excl");
			}
		}
	}
	return;
}

sub _createVendorOSPath
{
	my $self = shift;

	if (slxsystem("mkdir -p $self->{'vendor-os-path'}")) {
		die _tr("unable to create directory '%s', giving up! (%s)\n",
			$self->{'vendor-os-path'}, $!);
	}
	return;
}

sub _touchVendorOS
{
	my $self = shift;

	# touch root folder, as we are using this folder to determine the
	# 'age' of the vendor-OS when trying to determine whether or not we
	# need to re-export this vendor-OS:
	slxsystem("touch $self->{'vendor-os-path'}");
	return;
}

sub _createPackager
{
	my $self = shift;

	my $packagerClass 
		= "OpenSLX::OSSetup::Packager::$self->{distro}->{'packager-type'}";
	my $packager = instantiateClass($packagerClass);
	$packager->initialize($self);
	$self->{'packager'} = $packager;
	return;
}

sub _createMetaPackager
{
	my $self = shift;

	my $metaPackagerType = $self->{distro}->{'meta-packager-type'};

	my $installInfoFile = "$self->{'vendor-os-path'}/.openslx-install-info";
	if (-e $installInfoFile) {
		# activate the meta-packager that was used when installing the os:
		my $installInfo = slurpFile($installInfoFile);
		if ($installInfo =~ m[SLX_META_PACKAGER=(\w+)]) {
			$metaPackagerType = $1;
		}
	}

	my $metaPackagerClass = "OpenSLX::OSSetup::MetaPackager::$metaPackagerType";
	my $metaPackager      = instantiateClass($metaPackagerClass);
	$metaPackager->initialize($self);
	$self->{'meta-packager'} = $metaPackager;
	return;
}

sub _sortRepositoryURLs
{
	my $self     = shift;
	my $repoInfo = shift;

	if (defined $repoInfo->{'url'} && $repoInfo->{'avoid-mirrors'}) {
		# a local URL blocks all the others, in order to avoid causing
		# (external) network traffic, so we return the local URL only:
		return [$repoInfo->{'url'}];
	}

	my %urlInfo;

	# specified URL always has highest precedence:
	$urlInfo{$repoInfo->{url}} = 0 if defined $repoInfo->{url};

	# now add all others sorted by "closeness":
	my $index = 1;
	foreach my $url (string2Array($repoInfo->{urls})) {
		# TODO: insert a closest mirror algorithm here!
		$urlInfo{$url} = $index++;
	}
	my @URLs = sort { $urlInfo{$a} <=> $urlInfo{$b} } keys %urlInfo;
	return \@URLs;
}

sub _downloadBaseFiles
{
	my $self  = shift;
	my $files = shift;

	my $pkgSubdir   = $self->{'distro-info'}->{'package-subdir'};
	my @URLs        = @{$self->{'baseURLs'}};
	my $maxTryCount = $openslxConfig{'ossetup-max-try-count'};

	my @foundFiles;
	foreach my $fileVariantStr (@$files) {
		my $tryCount = 0;
		next unless $fileVariantStr =~ m[\S];
		my $foundFile;
	  try_next_url:
		my $url = $URLs[$self->{'baseURL-index'}];
		$url .= "/$pkgSubdir" if length($pkgSubdir);
		my @contFlags = ();
		push @contFlags, '-c' if ($url =~ m[^ftp]);

		# continuing is only supported with FTP, but not with HTTP
		foreach my $file (split '\s+', $fileVariantStr) {
			vlog(2, "fetching <$file>...");
			if (slxsystem("wget", @contFlags, "$url/$file") == 0) {
				$foundFile = basename($file);
				last;
			}
			elsif ($! == 17) {
				my $basefile = basename($file);
				vlog(2, "removing left-over '$basefile' and trying again...");
				unlink $basefile;
			}
		}
		if (!defined $foundFile) {
			if (!$ENV{SLX_NO_MIRRORS} && $tryCount < $maxTryCount) {
				$tryCount++;
				$self->{'baseURL-index'} 
					= ($self->{'baseURL-index'} + 1) % scalar(@URLs);
				vlog(
					0,
					_tr(
						"switching to mirror '%s'.",
						$URLs[$self->{'baseURL-index'}]
					)
				);
				goto try_next_url;
			}
			die _tr("unable to fetch '%s' from any source!\n", $fileVariantStr);
		}
		push @foundFiles, $foundFile;
	}
	return @foundFiles;
}

sub _startLocalURLServersAsNeeded
{
	my $self = shift;

	$self->{'local-http-server-master-pid'} = $$;

	my $port = 5080;
	foreach my $repoInfo (values %{$self->{'distro-info'}->{repository}}) {
		$repoInfo->{'avoid-mirrors'} = $ENV{SLX_NO_MIRRORS} || 0;
		my $localURL = $repoInfo->{url} || '';
		next if !$localURL;
		next if $localURL =~ m[^\w+:];	# anything with a protcol-spec is non-local
		if (!exists $self->{'local-http-servers'}->{$localURL}) {
			my $busyboxName =
				$self->_hostIs64Bit()
				? 'busybox.x86_64'
				: 'busybox.i586';
			my $busybox =
				"$openslxConfig{'base-path'}/share/busybox/$busyboxName";
			my $pid 
				= executeInSubprocess(
					$busybox, "httpd", '-p', $port, '-h', '/', '-f'
				);
			vlog(1, 
				_tr(
					"started local HTTP-server for URL '%s' on port '%s'.", 
					$localURL, $port
				)
			);
			$self->{'local-http-servers'}->{$localURL} = $pid;
			$repoInfo->{'url'} = "http://localhost:$port$localURL";
			$repoInfo->{'avoid-mirrors'} = 1;
			$port++;
		}
	}
	return;
}

sub _setupStage1A
{
	my $self = shift;

	vlog(1, "setting up stage1a for $self->{'vendor-os-name'}...");

	# specify individual paths for the respective substages:
	$self->{stage1aDir}    = "$self->{'vendor-os-path'}/stage1a";
	$self->{stage1bSubdir} = 'slxbootstrap';
	$self->{stage1cSubdir} = 'slxfinal';

	# we create *all* of the above folders by creating stage1cDir:
	my $stage1cDir 
		= "$self->{'stage1aDir'}/$self->{'stage1bSubdir'}/$self->{'stage1cSubdir'}";
	if (slxsystem("mkdir -p $stage1cDir")) {
		die _tr("unable to create directory '%s', giving up! (%s)\n",
			$stage1cDir, $!);
	}

	$self->_stage1A_createBusyboxEnvironment();
	$self->_stage1A_copyPrerequiredFiles();
	$self->_stage1A_copyTrustedPackageKeys();
	$self->_stage1A_createRequiredFiles();
	return;
}

sub _stage1A_createBusyboxEnvironment
{
	my $self = shift;

	# copy busybox and all required binaries into stage1a-dir:
	vlog(1, "creating busybox-environment...");
	my $busyboxName = $self->_hostIs64Bit() ? 'busybox.x86_64' : 'busybox.i586';
	my $requiredLibs = copyBinaryWithRequiredLibs({
		'binary' => "$openslxConfig{'base-path'}/share/busybox/$busyboxName",
		'targetFolder'    => "$self->{stage1aDir}/bin",
		'libTargetFolder' => "$self->{stage1aDir}",
		'targetName'      => 'busybox',
	});
	my $libcFolder;
	foreach my $lib (split "\n", $requiredLibs) {
		if ($lib =~ m[/libc.so.\d\s*$]) {
			# note target folder of libc, as we need to copy the resolver libs
			# into the same place:
			$libcFolder = dirname($lib);
		}
	}

	# create all needed links to busybox:
	my $links 
		= slurpFile("$openslxConfig{'base-path'}/share/busybox/busybox.links");
	foreach my $linkTarget (split "\n", $links) {
		linkFile('/bin/busybox', "$self->{stage1aDir}/$linkTarget");
	}
	if ($self->_hostIs64Bit()) { 
		if (!-e "$self->{stage1aDir}/lib64") {
			linkFile('/lib', "$self->{stage1aDir}/lib64");
		}
		if (!-e "$self->{stage1aDir}/usr/lib64") {
			linkFile('/usr/lib', "$self->{stage1aDir}/usr/lib64");
		}
	}

	$self->_stage1A_setupResolver($libcFolder);
	return;
}

sub _stage1A_setupResolver
{
	my $self       = shift;
	my $libcFolder = shift;

	if (!defined $libcFolder) {
		warn _tr("unable to determine libc-target-folder, will use /lib!");
		$libcFolder = '/lib';
	}

	copyFile('/etc/resolv.conf', "$self->{stage1aDir}/etc");
	spitFile("$self->{stage1aDir}/etc/hosts", '127.0.0.1 localhost');
	copyFile("$libcFolder/libresolv*",    "$self->{stage1aDir}$libcFolder");
	copyFile("$libcFolder/libnss_dns*",   "$self->{stage1aDir}$libcFolder");
	copyFile("$libcFolder/libnss_files*", "$self->{stage1aDir}$libcFolder");

	my $stage1cDir 
		= "$self->{'stage1aDir'}/$self->{'stage1bSubdir'}/$self->{'stage1cSubdir'}";
	copyFile('/etc/resolv.conf', "$stage1cDir/etc");
	return;
}

sub _stage1A_copyPrerequiredFiles
{
	my $self = shift;

	return unless -d "$self->{'shared-distro-info-dir'}/prereqfiles";

	vlog(2, "copying folder with pre-required files...");
	my $stage1cDir 
		= "$self->{'stage1aDir'}/$self->{'stage1bSubdir'}/$self->{'stage1cSubdir'}";
	my $cmd = qq[
		tar -cp -C $self->{'shared-distro-info-dir'}/prereqfiles . \\
		| tar -xp -C $stage1cDir
	];
	if (slxsystem($cmd)) {
		die _tr(
			"unable to copy folder with pre-required files to folder '%s' (%s)\n",
			$stage1cDir, $!
		);
	}
	$self->{distro}->fixPrerequiredFiles($stage1cDir);
	return;
}

sub _stage1A_copyTrustedPackageKeys
{
	my $self = shift;

	vlog(2, "copying folder with trusted package keys...");
	my $stage1bDir = "$self->{'stage1aDir'}/$self->{'stage1bSubdir'}";
	foreach my $folder (
		$self->{'shared-distro-info-dir'}, $self->{'config-distro-info-dir'}
	) {
		next unless -d "$folder/trusted-package-keys";
		my $cmd = qq[
			tar -cp -C $folder trusted-package-keys \\
		| tar -xp -C $stage1bDir
		];
		if (slxsystem($cmd)) {
			die _tr(
				"unable to copy folder with trusted package keys to folder '%s' (%s)\n",
				"$stage1bDir/trusted-package-keys", $!
			);
		}
		slxsystem("chmod 444 $stage1bDir/trusted-package-keys/*");

		# install ultimately trusted keys (from distributor):
		my $stage1cDir = "$stage1bDir/$self->{'stage1cSubdir'}";
		my $keyDir = "$self->{'shared-distro-info-dir'}/trusted-package-keys";
		if (-e "$keyDir/pubring.gpg") {
			copyFile("$keyDir/pubring.gpg", "$stage1cDir/usr/lib/rpm/gnupg");
		}
	}
	return;
}

sub _stage1A_createRequiredFiles
{
	my $self = shift;

	vlog(2, "creating required files...");

	# fake all files required by stage1b (by creating them empty):
	my $stage1bDir = "$self->{'stage1aDir'}/$self->{'stage1bSubdir'}";
	foreach my $fake (@{$self->{distro}->{'stage1b-faked-files'}}) {
		fakeFile("$stage1bDir/$fake");
	}

	# fake all files required by stage1c (by creating them empty):
	my $stage1cDir = "$stage1bDir/$self->{'stage1cSubdir'}";
	foreach my $fake (@{$self->{distro}->{'stage1c-faked-files'}}) {
		fakeFile("$stage1cDir/$fake");
	}

	mkdir "$stage1cDir/dev";
	if (!-e "$stage1cDir/dev/null"
		&& slxsystem("mknod $stage1cDir/dev/null c 1 3"))
	{
		die _tr(
			"unable to create node '%s' (%s)\n", "$stage1cDir/dev/null", $!
		);
	}
	return;
}

sub _setupStage1B
{
	my $self = shift;

	vlog(1, "setting up stage1b for $self->{'vendor-os-name'}...");
	$self->_stage1B_chrootAndBootstrap();
	return;
}

sub _stage1B_chrootAndBootstrap
{
	my $self = shift;

	# give packager a chance to copy required files into stage1a-folder:
	$self->{packager}->prepareBootstrap($self->{stage1aDir});
	
	$self->_callChrootedFunction({
		chrootDir => $self->{stage1aDir},
		function  => sub {
			# chdir into slxbootstrap, as we want to drop packages into there:
			chdir "/$self->{stage1bSubdir}"
				or die _tr(
					"unable to chdir into '%s' (%s)\n", 
					"/$self->{stage1bSubdir}", $!
				);

			# fetch prerequired packages and use them to bootstrap the packager:
			$self->{'baseURLs'} = $self->_sortRepositoryURLs(
				$self->{'distro-info'}->{repository}->{base}
			);
			$self->{'baseURL-index'} = 0;
			my @pkgs = string2Array($self->{'distro-info'}->{'prereq-packages'});
			my @prereqPkgs = $self->_downloadBaseFiles(\@pkgs);
			$self->{packager}->bootstrap(\@prereqPkgs);
		
			@pkgs = string2Array($self->{'distro-info'}->{'bootstrap-packages'});
			push(
				@pkgs, 
				string2Array(
					$self->{'distro-info'}->{'metapackager-packages'}
						->{$self->{distro}->{'meta-packager-type'}}
				)
			);
			my @bootstrapPkgs = $self->_downloadBaseFiles(\@pkgs);
			$self->{'bootstrap-packages'} = \@bootstrapPkgs;
		},
	});
	return;
}

sub _setupStage1C
{
	my $self = shift;

	vlog(1, "setting up stage1c for $self->{'vendor-os-name'}...");
	$self->_stage1C_chrootAndInstallBasicVendorOS();
	return;
}

sub _stage1C_chrootAndInstallBasicVendorOS
{
	my $self = shift;

	my $stage1bDir = "/$self->{stage1bSubdir}";
	chrootInto($stage1bDir);

	my $stage1cDir = "/$self->{stage1cSubdir}";

	# import any additional trusted package keys to rpm-DB:
	my $keyDir = "/trusted-package-keys";
	my $keyDirDH;
	if (opendir($keyDirDH, $keyDir)) {
		my @keyFiles 
			= map { "$keyDir/$_" }
			  grep { $_ !~ m[^(\.\.?|pubring.gpg)$] } 
			  readdir($keyDirDH);
		closedir($keyDirDH);
		$self->{packager}->importTrustedPackageKeys(\@keyFiles, $stage1cDir);
	}

	# install all bootstrap packages
	$self->{packager}->installPackages(
		$self->{'bootstrap-packages'}, $stage1cDir
	);
	return;
}

sub _stage1C_cleanupBasicVendorOS
{
	my $self = shift;

	my $stage1cDir 
		= "$self->{'stage1aDir'}/$self->{'stage1bSubdir'}/$self->{'stage1cSubdir'}";
	if (slxsystem("mv $stage1cDir/* $self->{'vendor-os-path'}/")) {
		die _tr(
			"unable to move final setup to '%s' (%s)\n",
			$self->{'vendor-os-path'}, $!
		);
	}
	if (slxsystem("rm -rf $self->{stage1aDir}")) {
		die _tr(
			"unable to remove temporary folder '%s' (%s)\n",
			$self->{stage1aDir}, $!
		);
	}
	return;
}

sub _setupStage1D
{
	my $self = shift;

	vlog(1, "setting up stage1d for $self->{'vendor-os-name'}...");

	$self->_callChrootedFunction({
		chrootDir    => $self->{'vendor-os-path'},
		function     => sub {
			$self->{distro}->preSystemInstallationHook();
			$self->_stage1D_setupPackageSources();
			$self->_stage1D_updateBasicVendorOS();
			$self->_stage1D_installPackageSelection();
			$self->{distro}->postSystemInstallationHook();
		},
		updateConfig => 1,
	});
	return;
}

sub _updateStage1D
{
	my $self = shift;

	vlog(1, "updating $self->{'vendor-os-name'}...");

	$self->_callChrootedFunction({
		chrootDir    => $self->{'vendor-os-path'},
		function     => sub {
			$self->_stage1D_updateBasicVendorOS();
		},
		updateConfig => 1,
	});
	return;
}

sub _startChrootedShellInStage1D
{
	my $self = shift;

	vlog(0, "starting chrooted shell for $self->{'vendor-os-name'}");
	vlog(0, "---------------------------------------");
	vlog(0, "- please type 'exit' if you are done! -");
	vlog(0, "---------------------------------------");

	$self->_callChrootedFunction({
		chrootDir    => $self->{'vendor-os-path'},
		function     => sub {
			# will hang until user exits manually:
			slxsystem($openslxConfig{'default-shell'});
		},
		updateConfig => 1,
	});
	return;
}

sub _callChrootedFunction
{
	my $self   = shift;
	my $params = shift;
	
	checkParams($params, {
		'chrootDir'    => '!',
		'function'     => '!',
		'updateConfig' => '?',
	});

	$self->{'distro'}->startSession($params->{chrootDir});

	# invoke given function:
	$params->{function}->();

	if ($params->{updateConfig}) {
		$self->{'distro'}->updateDistroConfig();
	}
	$self->{'distro'}->finishSession();
	return;
}

sub _stage1D_setupPackageSources
{
	my $self = shift;

	vlog(1, "setting up package sources for meta packager...");
	my $selectionName = $self->{'selection-name'};
	my $pkgExcludes   = $self->{'distro-info'}->{excludes}->{$selectionName};
	my $excludeList   = join ' ', string2Array($pkgExcludes);
	$self->{'meta-packager'}->initPackageSources();
	my ($rk, $repo);
	while (($rk, $repo) = each %{$self->{'distro-info'}->{repository}}) {
		vlog(2, "setting up package source $rk...");
		$self->{'meta-packager'}->setupPackageSource(
			$rk, $repo, $excludeList, $self->_sortRepositoryURLs($repo)
		);
	}
	return;
}

sub _stage1D_updateBasicVendorOS
{
	my $self = shift;

	vlog(1, "updating basic vendor-os...");
	$self->{'meta-packager'}->updateBasicVendorOS();
	return;
}

sub _stage1D_installPackageSelection
{
	my $self = shift;

	my $selectionName = $self->{'selection-name'};

	vlog(1, "installing package selection <$selectionName>...");
	my $pkgSelection  = $self->{'distro-info'}->{selection}->{$selectionName};
	my @pkgs          = string2Array($pkgSelection);
	my @installedPkgs = $self->{'packager'}->getInstalledPackages();
	@pkgs = grep {
		my $pkg = $_;
		if (grep { $_ eq $pkg; } @installedPkgs) {
			vlog(1, "package '$pkg' filtered, it is already installed.");
			0;
		}
		else {
			1;
		}
	} @pkgs;
	if (!@pkgs) {
		vlog(
			0,
			_tr(
				"No packages listed for selection '%s', nothing to do.",
				$selectionName
			)
		);
	}
	else {
		vlog(1, "installing these packages:\n" . join("\n\t", @pkgs));
		$self->{'meta-packager'}->installSelection(join " ", @pkgs);
	}
	return;
}

sub _clone_fetchSource
{
	my $self   = shift;
	my $source = shift;

	vlog(
		0,
		_tr(
			"Cloning vendor-OS from '%s' to '%s'...\n", $source,
			$self->{'vendor-os-path'}
		)
	);
	my $excludeIncludeList = $self->_clone_determineIncludeExcludeList();
	vlog(1, "using exclude-include-filter:\n$excludeIncludeList\n");
	my $rsyncCmd 
		= "rsync -av --delete --exclude-from=- $source $self->{'vendor-os-path'}";
	vlog(2, "executing: $rsyncCmd\n");
	my $rsyncFH;
	open($rsyncFH, '|-', $rsyncCmd)
		or croak(
			_tr(
				"unable to start rsync for source '%s', giving up! (%s)\n",
				$source, $!
			)
		);
	print $rsyncFH $excludeIncludeList;
	close($rsyncFH)
		or croak _tr(
			"unable to clone from source '%s', giving up! (%s)\n", $source, $!
		);
	return;
}

sub _clone_determineIncludeExcludeList
{
	my $self = shift;

	my $localFilterFile 
		= "$openslxConfig{'config-path'}/distro-info/clone-filter";
	my $includeExcludeList 
		= slurpFile($localFilterFile, { failIfMissing => 0 });
	$includeExcludeList .= $self->{distro}->{'clone-filter'};
	$includeExcludeList =~ s[^\s+][]igms;

	# remove any leading whitespace, as rsync doesn't like it
	return $includeExcludeList;
}

################################################################################
### utility methods
################################################################################
sub _changePersonalityIfNeeded
{
	my $self = shift;

	my $distroName = $self->{'distro-name'};
	if ($self->_hostIs64Bit() && $distroName !~ m[_64]) {
		# trying to handle a 32-bit vendor-OS on a 64-bit machine, so we change
		# the personality accordingly (from 64-bit to 32-bit):
		my $syscallPH = 'syscall.ph';
		eval { require $syscallPH }
			or die _tr("unable to load '%s'\n", $syscallPH);
		my $personalityPH = 'linux/personality.ph';
		eval { require $personalityPH }
			or die _tr("unable to load '%s'\n", $personalityPH);

		syscall &SYS_personality, PER_LINUX32();
	}
	return;
}

sub _hostIs64Bit
{
	my $self = shift;

	$self->{arch} = `uname -m` unless defined $self->{arch};
	return ($self->{arch} =~ m[64]);
}

1;

=pod

=head1 NAME

OpenSLX::OSSetup::Engine - driver engine for OSSetup API

=head1 SYNOPSIS

...

=cut

