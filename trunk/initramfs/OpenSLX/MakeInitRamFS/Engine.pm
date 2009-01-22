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
# MakeInitialRamFS::Engine.pm
#	- provides driver engine for MakeInitialRamFS API.
# -----------------------------------------------------------------------------
package OpenSLX::MakeInitRamFS::Engine;

use strict;
use warnings;

use File::Basename;
use File::Find;
use File::Path;
use POSIX qw(strftime);

use OpenSLX::Basics;
use OpenSLX::LibScanner;
use OpenSLX::OSPlugin::Roster;
use OpenSLX::Utils;

# TODO: implement support for the following (either here or as plugin):
#			wlan
#			tpm
#			cdboot (must be implemented here!)

################################################################################
### interface methods
################################################################################
sub new
{
	my $class  = shift;
	my $params = shift || {};

	checkParams($params, { 
		'attrs'          => '!',
		'debug-level'    => '?',
		'export-name'    => '!',
		'export-uri'     => '!',
		'initramfs'      => '!',
		'kernel-params'  => '!',
		'kernel-version' => '!',
		'plugins'        => '!',
		'root-path'      => '!',
		'slx-version'    => '!',
		'system-name'    => '!',
	} );

	my $self = $params;

	$self->{'system-name'} =~ m{^([^\-]+)-([^:\-]+)}
		or die "unable to extract distro-info from $self->{'system-name'}!";

	$self->{'distro-name'} = $1;
	$self->{'distro-ver'} = $2;

	my %distroMap = (
		'debian' => 'Debian',
		'suse'   => 'SUSE',
		'ubuntu' => 'Ubuntu',
	);
	my $distroModule = $distroMap{$self->{'distro-name'}} || 'Base';
	$self->{distro} = instantiateClass(
		"OpenSLX::MakeInitRamFS::Distro::$distroModule"
	);
	
	$self->{'lib-scanner'} 
		= OpenSLX::LibScanner->new({ 'root-path' => $self->{'root-path'} });
	
	$self->{'required-libs'}            = {};
	$self->{'suggested-kernel-modules'} = [];
	$self->{'filtered-kernel-modules'}  = [];

	return bless $self, $class;
}

sub execute
{
	my $self   = shift;
	my $dryRun = shift;

	$self->_collectCMDs();

	$self->_executeCMDs() unless $dryRun;

	return;
}

################################################################################
### implementation methods
################################################################################
sub _collectCMDs
{
	my $self = shift;
	
	$self->{CMDs} = [];

	$self->_setupBuildPath();

	$self->_addRequiredFSModsAndTools();
	
	$self->_writeInitramfsSetup();
	$self->_writeSlxSystemConf();

	$self->_copyDistroSpecificFiles();
	$self->_copyInitramfsFiles();
	
	$self->_copyBusybox();
	
	$self->_copyDhcpClient();

	$self->_copyRamfsTools();
	
	$self->_copyRequiredFSTools();

	$self->_copyRequiredLayeredFSTools();

	$self->_copyPreAndPostinitFiles();

	if ($self->{'debug-level'}) {
		$self->_copyDebugTools();
	}

	$self->_handlePlugins();

	$self->{distro}->applyChanges($self);

	$self->_copyKernelModules();
	
	$self->_copyRequiredLibs();
	
	$self->_createInitRamFS();

	return;
}

sub _executeCMDs
{
	my $self = shift;
	
	foreach my $cmd (@{$self->{CMDs}}) {
		if (ref($cmd) eq 'HASH') {
			vlog(3, "writing $cmd->{file}");
			my $flags = defined $cmd->{mode} ? { mode => $cmd->{mode} } : undef;
			spitFile($cmd->{file}, $cmd->{content}, $flags);
		}
		else {
			vlog(3, "executing: $cmd");
			if (slxsystem($cmd)) {
				die _tr(
					"unable to execute shell-cmd\n\t%s", $cmd
				);
			}
		}
	}

	return;
}

sub addCMD
{
	my $self = shift;
	my $cmd  = shift;
	
	push @{$self->{CMDs}}, $cmd;

	return;
}
	
sub _setupBuildPath
{
	my $self = shift;
	
	my $buildPath = "$openslxConfig{'temp-path'}/slx-initramfs";
	$self->addCMD("rm -rf $buildPath");

	my @stdFolders = qw(
		bin 
		dev 
		etc
		etc/init-hooks
		etc/sysconfig
		lib
		mnt 
		proc 
		root 
		sys 
		tmp 
		usr/share
		var/lib
		var/lib/nfs/state
		var/run
	);
	$self->addCMD(
		'mkdir -p ' . join(' ', map { "$buildPath/$_"; } @stdFolders)
	);
	$self->addCMD("ln -sfn /bin $buildPath/sbin");
	
	$self->{'build-path'} = $buildPath;
	
	return;
}
	
sub _copyDistroSpecificFiles
{
	my $self = shift;

	my $distroSpecsPath = "$openslxConfig{'base-path'}/share/distro-specs";

	my $distroName = $self->{'distro-name'};
	my $distroVer = $self->{'distro-ver'};
	
	# concatenate default- and distro-specific configuration into one file
	my $config = slurpFile("$distroSpecsPath/$distroName/config-default");
	$config .= "\n";
	$config .= slurpFile("$distroSpecsPath/$distroName/config-$distroVer");
	$self->addCMD( {
		file    => "$self->{'build-path'}/etc/sysconfig/config",
		content => $config,
	} );
		
	# concatenate default- and distro-specific functions into one file
	my $functions = slurpFile("$distroSpecsPath/$distroName/functions-default");
	$functions .= "\n";
	$functions 
		.= slurpFile("$distroSpecsPath/$distroName/functions-$distroVer");
	$self->addCMD( {
		file    => "$self->{'build-path'}/etc/distro-functions",
		content => $functions,
	} );
	
	my $defaultsPath = "$distroSpecsPath/$distroName/files-default";
	if (-e $defaultsPath) {
		$self->addCMD(
			"cp -a $defaultsPath $self->{'build-path'}/etc/sysconfig/files"
		);
	}
		
	return 1;
}

sub _copyInitramfsFiles
{
	my $self = shift;

	my $initramfsPath = "$openslxConfig{'base-path'}/share/initramfs";

	find(
		{
			wanted => sub {
				my $len = length($initramfsPath);
				my $file = $File::Find::name;
				my $relName = length($file) > $len ? substr($file, $len+1) : '';
				if (-d) {
					$self->addCMD("mkdir -p $self->{'build-path'}/$relName");
				} elsif (-l $file) {
					my $target = readlink $file;
					$self->addCMD(
						"ln -sf $target $self->{'build-path'}/$relName"
					);
				} elsif (qx{file $file} =~ m{ELF}) {
					$self->addCMD(
						"cp -p $file $self->{'build-path'}/$relName"
					);
				} else {
					my $text = slurpFile($file, { 'io-layer' => 'bytes' } );

					# replace macros
					# TODO: find out what these mean and maybe find a
					#       different, better solution
					my %macro = (
						'COMDIRINDXS' => '/tmp/scratch /var/lib/nobody',
						'COMETCEXCL'  => "XF86Config*\nissue*\nmtab*\nfstab*\n",
						'KERNVER'     => $self->{'kernel-version'},
						# keep serverip as it is (it is handled by init itself)
						'serverip'    => '@@@serverip@@@',
					);
					$text =~ s{\@\@\@([^\@]+)\@\@\@}{
						if (!exists $macro{$1}) {
							warn _tr(
								'unknown macro @@@%s@@@ found in %s', 
								$1, $File::Find::name
							);
							'';
						} else {
							$macro{$1};
						}
					}eogms;
					
					# force shebang with ash
					$text =~ s{\A#!\s*/bin/.+?$}{#!/bin/ash}ms;
					
					$self->addCMD( {
						file    => "$self->{'build-path'}/$relName",
						content => $text,
						mode    => (-x $file ? 0755 : undef),
					} );
				}
			},
			no_chdir => 1,
		},
		$initramfsPath
	);

	return;
}

sub _copyBusybox
{
	my $self = shift;

	$self->_copyPlatformSpecificBinary(
		"$openslxConfig{'base-path'}/share/busybox/busybox", '/bin/busybox'
	);
	
	my @busyboxApplets = qw(
		ar arping ash bunzip2 cat chmod chown chroot cp cpio cut
	    date dd df dmesg du echo env expr fdisk free grep gunzip hwclock
	    insmod id ip kill killall ln ls lsmod mdev mkdir mknod mkswap 
	    modprobe mount mv nice ping printf ps rdate rm rmmod sed sleep 
	    sort swapoff swapon switch_root tar test tftp time touch tr 
	    udhcpc umount uptime usleep vconfig vi wget zcat zcip
	);
	foreach my $applet (@busyboxApplets) {
		$self->addCMD("ln -sf /bin/busybox $self->{'build-path'}/bin/$applet");
	}
	
	# fake the sh link in busybox environment
	my $shFake = "#!/bin/ash\n/bin/ash \$\@";
	$self->addCMD( {
		file    => "$self->{'build-path'}/bin/sh", 
		content => $shFake,
		mode    => 0755
	} );

	return;
}

sub _copyRamfsTools
{
	my $self = shift;
	
	my @ramfsTools = qw(ddcprobe 915resolution);
	foreach my $tool (@ramfsTools) {
		$self->_copyPlatformSpecificBinary(
			"$openslxConfig{'base-path'}/share/ramfstools/$tool", 
			"/bin/$tool"
		);
	}
	
	return;
}
	
sub _copyDebugTools
{
	my $self = shift;
	
	my @debugTools = qw(strace);
	foreach my $tool (@debugTools) {
		my $toolPath = $self->_findBinary($tool);
		if (!$toolPath) {
			warn _tr('debug-tool "%s" is not available', $tool);
			next;
		}
		$self->addCMD("cp -p $toolPath $self->{'build-path'}/bin");
		$self->_addRequiredLibsFor($toolPath);
	}
	
	return;
}
	
sub _copyDhcpClient
{
	my $self = shift;
	
	# TODO: instead of using dhclient, we should check if the client
	#       provided by busybox still does not support fetching NIS stuff
	#       (and implement that if it doesn't)

	my $toolPath = $self->_findBinary('dhclient');
	if (!$toolPath) {
		warn _tr('tool "dhclient" is not available, using "udhcpc" instead');
		return;
	}
	$self->addCMD("cp -p $toolPath $self->{'build-path'}/bin");
	$self->_addRequiredLibsFor($toolPath);
	
	return;
}
	
sub _findBinary
{
	my $self   = shift;
	my $binary = shift;
	
	my @binDirs = qw(
		bin sbin usr/bin usr/sbin usr/local/bin usr/local/sbin usr/bin/X11
	);
	foreach my $binDir (@binDirs) {
		my $binPath = "$self->{'root-path'}/$binDir/$binary";
		return $binPath if -f $binPath && -x $binPath;
	}
	
	return;
}
	
sub _copyPlatformSpecificBinary
{
	my $self       = shift;
	my $binaryPath = shift;
	my $targetPath = shift;

	my $binary = $self->_platformSpecificFileFor($binaryPath);
	
	$self->addCMD("cp -p $binary $self->{'build-path'}$targetPath");
	$self->_addRequiredLibsFor($binary);

	return;
}

sub _copyRequiredFSTools
{
	my $self = shift;

	foreach my $tool (@{$self->{'fs-tools'}}) {
		my $toolPath = $self->_findBinary($tool);
		if (!$toolPath) {
			die _tr('filesystem-tool "$tool" is not available, giving up!');
		}
		$self->addCMD("cp -p $toolPath $self->{'build-path'}/bin");
		$self->_addRequiredLibsFor($toolPath);
	}

	return;
}

sub _copyRequiredLayeredFSTools
{
	my $self = shift;

	my @tools;
	if ($self->{'kernel-params'} =~ m{\bunionfs\b}) {
		push @tools, 'unionctl';
	}
	if ($self->{'kernel-params'} =~ m{\bcowloop\b}) {
		push @tools, 'cowdev';
	}
	foreach my $tool (@tools) {
		my $toolPath = $self->_findBinary($tool);
		if (!$toolPath) {
			die _tr('layered-fs-tool "$tool" is not available, giving up!');
		}
		$self->addCMD("cp -p $toolPath $self->{'build-path'}/bin");
		$self->_addRequiredLibsFor($toolPath);
	}

	return;
}

sub _copyRequiredLibs
{
	my $self = shift;

	# separate 64-bit libs from 32-bit libs and copy them into different
	# destination folders
	my @libs64 = grep { $_ =~ m{/lib64/} } keys %{$self->{'required-libs'}};
	my @libs32 = grep { $_ !~ m{/lib64/} } keys %{$self->{'required-libs'}};
	if (@libs64) {
		$self->addCMD("mkdir -p $self->{'build-path'}/lib64");
		foreach my $lib (@libs64) {
			$self->addCMD("cp -p $lib $self->{'build-path'}/lib64/");
		}
	}
	foreach my $lib (@libs32) {
		$self->addCMD("cp -p $lib $self->{'build-path'}/lib/");
	}

	return;
}

sub _addRequiredLibsFor
{
	my $self   = shift;
	my $binary = shift;

	my @libs = $self->{'lib-scanner'}->determineRequiredLibs($binary);
	foreach my $lib (@libs) {
		$self->_addRequiredLib($lib);
	}

	return;
}

sub _addRequiredLib
{
	my $self = shift;
	my $lib  = shift;

	$self->{'required-libs'}->{$lib} = 1;

	return;
}

sub _addFilteredKernelModules
{
	my $self   = shift;

	push @{ $self->{'filtered-kernel-modules'} }, @_;

	return;
}

sub _copyKernelModules
{
	my $self = shift;
	
	# read modules.dep and use it to determine module dependencies
	my $sourcePath = "$self->{'root-path'}/lib/modules/$self->{'kernel-version'}";
	my @modulesDep = slurpFile("$sourcePath/modules.dep")
		or die _tr('unable to open %s!', "$sourcePath/modules.dep");
	my (%dependentModules, %modulePath, %modulesToBeCopied);
	foreach my $modulesDep (@modulesDep) { 
		next if $modulesDep !~ m{^(.+?)/([^/]+)\.ko:\s*(.*?)\s*$};
		my $path = $1;
		my $module = $2;
		my $dependentsList = $3;
		my $fullModulePath = "$path/$module.ko";
		$modulePath{$module} = [] if !exists $modulePath{$module};
		push @{$modulePath{$module}}, $fullModulePath;
		$dependentModules{$fullModulePath} = [ split ' ', $dependentsList ];
	}

	my $targetPath 
		= "$self->{'build-path'}/lib/modules/$self->{'kernel-version'}";
	$self->addCMD("mkdir -p $targetPath");
	$self->addCMD("cp -p $sourcePath/modules.* $targetPath/");
	
	# TODO: find out what's the story behing the supposedly required
	#       modules 'af_packet', 'unix' and 'hid' (which seem to be
	#       missing at least on some systems
	my @kernelModules = qw(
		af_packet unix hid usbhid uhci-hcd ohci-hcd
	);
	push @kernelModules, @{ $self->{'suggested-kernel-modules'} };

	push @kernelModules, split ' ', $self->{attrs}->{ramfs_fsmods};
	push @kernelModules, split ' ', $self->{attrs}->{ramfs_miscmods};
	push @kernelModules, split ' ', $self->{attrs}->{ramfs_nicmods};

	# a function that determines dependent modules recursively
	my $addDependentsSub;
	$addDependentsSub = sub {
		my $modulePath = shift;
		foreach my $dependentModule (@{$dependentModules{$modulePath}}) {
			next if $modulesToBeCopied{$dependentModule};
			$modulesToBeCopied{$dependentModule} = 1;
			$addDependentsSub->($dependentModule);
		}
	};

	# start with the given kernel modules (names) and build a list of all
	# required modules
	foreach my $kernelModule (@kernelModules) {
		if (!$modulePath{$kernelModule}) {
			if (! grep { $_ eq $kernelModule	} 
				@{ $self->{'filtered-kernel-modules'} }
			) {
				warn _tr(
					'kernel module "%s" not found (in modules.dep)', 
					$kernelModule
				);
			}
		}
		foreach my $modulePath (@{$modulePath{$kernelModule}}) {
			next if $modulesToBeCopied{$modulePath};
			$modulesToBeCopied{$modulePath} = 1;
			$addDependentsSub->($modulePath);
		}
	}
	
	# copy all the modules that we think are required
	foreach my $moduleToBeCopied (sort keys %modulesToBeCopied) {
		my $targetDir = "$self->{'build-path'}" . dirname($moduleToBeCopied);
		$self->addCMD("mkdir -p $targetDir");
		my $source = "$self->{'root-path'}$moduleToBeCopied";
		my $target = "$self->{'build-path'}$moduleToBeCopied";
		$self->addCMD("cp -p --dereference $source $target");
	}
	
	return;
}

sub _copyPreAndPostinitFiles
{
	my $self = shift;

	foreach my $cfg (
		'default/initramfs/preinit.local',
		"$self->{'system-name'}/initramfs/preinit.local",
		'default/initramfs/postinit.local',
        "$self->{'system-name'}/initramfs/postinit.local"
	) {
		my $cfgPath = "$openslxConfig{'private-path'}/config/$cfg";
		next if !-f $cfgPath;
		$self->addCMD("cp -p $cfgPath $self->{'build-path'}/bin/");
	}
	return;
}

sub _platformSpecificFileFor
{
	my $self   = shift;
	my $binary = shift;

	if ($self->{'system-name'} =~ m{64}) {
		return $binary . '.x86_64';
	}
	return $binary . '.i586';
}

sub _addRequiredFSModsAndTools
{
	my $self = shift;
	
	my $osExportEngine = instantiateClass("OpenSLX::OSExport::Engine");
	$osExportEngine->initializeFromExisting($self->{'export-name'});
	my $fsMods = $self->{attrs}->{ramfs_fsmods} || '';
	foreach my $fsMod ($osExportEngine->requiredFSMods()) {
		$fsMods .= " $fsMod" if $fsMods !~ m{$fsMod};
	}
	$self->{attrs}->{ramfs_fsmods} = $fsMods;
	
	my @fsTools = $osExportEngine->requiredFSTools();
	$self->{'fs-tools'} = \@fsTools;

	return;
}

sub _writeInitramfsSetup
{
	my $self = shift;
	
	# generate initramfs-setup file containing attributes that are
	# relevant for the initramfs only (before there's a root-FS):
	my $initramfsAttrs = {
		'host_name'		 => 'slx-client', # just to have something at all
		'ramfs_fsmods'   => $self->{attrs}->{ramfs_fsmods} || '',
		'ramfs_miscmods' => $self->{attrs}->{ramfs_miscmods} || '',
		'ramfs_nicmods'  => $self->{attrs}->{ramfs_nicmods} || '',
		'rootfs'         => $self->{'export-uri'} || '',
	};
	my $content = "# attributes set by slxconfig-demuxer:\n";
	foreach my $attr (keys %$initramfsAttrs) {
		$content .= qq[$attr="$initramfsAttrs->{$attr}"\n];
	}
	$self->addCMD( {
		file    => "$self->{'build-path'}/etc/initramfs-setup", 
		content => $content
	} );
	
	return;
}

sub _writeSlxSystemConf
{
	my $self = shift;
	
	# generate slxsystem.conf file with variables that are needed
	# in stage3 init.
	# TODO: either put this stuff into initramfs-setup or find another solution
	my $date = strftime("%d.%m.%Y", localtime);
	my $slxConf = unshiftHereDoc(<<"	End-of-Here");
		slxconf_date=$date
		slxconf_kernver=$self->{'kernel-version'}
		slxconf_listnwmod="$self->{attrs}->{ramfs_nicmods}"
		slxconf_distro_name=$self->{'distro-name'}
		slxconf_distro_ver=$self->{'distro-ver'}
		slxconf_system_name=$self->{'system-name'}
		slxconf_slxver="$self->{'slx-version'}"
	End-of-Here
	$self->addCMD( {
		file    => "$self->{'build-path'}/etc/sysconfig/slxsystem.conf", 
		content => $slxConf
	} );

	return;
}

sub _handlePlugins
{
	my $self = shift;

	my $pluginSrcPath = "$openslxConfig{'base-path'}/lib/plugins";
	my $buildPath = $self->{'build-path'};
	foreach my $pluginName (@{$self->{'plugins'}}) {
		if (-d "$pluginSrcPath/$pluginName/init-hooks") {
			my $hookSrcPath = "$pluginSrcPath/$pluginName/init-hooks";
			$self->addCMD("cp -r $hookSrcPath/* $buildPath/etc/init-hooks/");
		}
		my $plugin = OpenSLX::OSPlugin::Roster->getPlugin($pluginName);
		next if !$plugin;

		my @suggestedKernelParams 
			= $plugin->suggestAdditionalKernelParams($self->{'kernel-params'});
		if (@suggestedKernelParams) {
			my $paramsList = join ' ', @suggestedKernelParams;
			vlog(
				2, 
				"plugin $pluginName suggests these kernel params: $paramsList"
			);
			$self->{'kernel-params'} 
				.= ($self->{'kernel-params'} ? ' ' : '') . $paramsList;
		}

		my @suggestedModules = $plugin->suggestAdditionalKernelModules($self);
		if (@suggestedModules) {
			vlog(
				2, 
				"plugin $pluginName suggests these kernel modules: "
				. join(',', @suggestedModules)
			);
			push @{ $self->{'suggested-kernel-modules'} }, @suggestedModules;
		}

		$plugin->copyRequiredFilesIntoInitramfs(
			$self->{'build-path'}, $self->{attrs}, $self
		);
	}
	return;
}

sub _createInitRamFS
{
	my $self = shift;

	my $buildPath = $self->{'build-path'};
	$self->addCMD(
		"cd $buildPath "
		. "&& find . "
			. "| cpio -H newc --quiet --create "
			. "| gzip -9 >$self->{initramfs}"
	);

	return;
}

1;
################################################################################

=pod

=head1 NAME

OpenSLX::MakeInitRamFS::Engine

=head1 SYNOPSIS

=head1 DESCRIPTION

...

=cut

