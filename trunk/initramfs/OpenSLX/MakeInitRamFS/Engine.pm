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

use File::Find;
use File::Path;

use OpenSLX::Basics;
use OpenSLX::LibScanner;
use OpenSLX::Utils;

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
		'kernel-version' => '!',
		'plugins'        => '!',
		'root-path'      => '!',
		'slx-version'    => '!',
		'system-name'    => '!',
	} );

	my $self = $params;

	if ($self->{'system-name'} =~ m{^([^\-]+)-([^:\-]+)}) {
		$self->{'distro-name'} = $1;
		$self->{'distro-ver'} = $2;
	}
	
	$self->{'lib-scanner'} 
		= OpenSLX::LibScanner->new({ 'root-path' => $self->{'root-path'} });
	
	$self->{'required-libs'} = {};

	return bless $self, $class;
}

sub execute
{
	my $self = shift;

	$self->_setupBuildPath();

	$self->_addRequiredFSModsAndTools();
	
	$self->_writeInitramfsSetup();

	$self->_copyDistroSpecificFiles();
	$self->_copyInitramfsFiles();
	
	$self->_copyBusybox();
	
	$self->_copyDhcpClient();

	$self->_copyRamfsTools();
	
	$self->_copyRequiredFSTools();

	if ($self->{'debug-level'}) {
		$self->_copyDebugTools();
	}

#	foreach my $plugin (@{$self->{'plugin-instances'}}) {
#		$plugin->specifyInitramfsAttrs($initramfsAttrs);
#	}

	$self->_copyRequiredLibs();

	return;
}

################################################################################
### implementation methods
################################################################################
sub _setupBuildPath
{
	my $self = shift;
	
	my $buildPath = "$openslxConfig{'temp-path'}/slx-initramfs";
	rmtree($buildPath);

	my @stdFolders = qw(
		bin 
		dev 
		etc
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
	mkpath([ map { "$buildPath/$_"; } @stdFolders ]);
	link '/bin', "$buildPath/sbin";
	
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
	spitFile("$self->{'build-path'}/etc/sysconfig/config");
		
	# concatenate default- and distro-specific functions into one file
	my $functions = slurpFile("$distroSpecsPath/$distroName/functions-default");
	$functions .= "\n";
	$functions 
		.= slurpFile("$distroSpecsPath/$distroName/functions-$distroVer");
	spitFile("$self->{'build-path'}/etc/distro-functions");
	
	my $defaultsPath = "$distroSpecsPath/$distroName/files-default";
	slxsystem("cp -a $defaultsPath $self->{'build-path'}/etc/sysconfig/files");
		
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
					mkpath("$self->{'build-path'}/$relName");
				} elsif (-l $file) {
					my $target = readlink $file;
					slxsystem("ln -sf $target $self->{'build-path'}/$relName");
				} elsif (qx{file $file} =~ m{ELF}) {
					slxsystem("cp -p $file $self->{'build-path'}/$relName");
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
					
					# force sh shebang over to ash
					$text =~ s{^#!\s*/bin/sh}{#!/bin/ash};
					
					spitFile("$self->{'build-path'}/$relName", $text);
					if (-x $file) {
						chmod 0755, "$self->{'build-path'}/$relName";
					}
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
		slxsystem("ln -sf /bin/busybox $self->{'build-path'}/bin/$applet");
	}
	
	# fake the sh link in busybox environment
	my $shFake = '#!/bin/ash\n/bin/ash $@';
	spitFile("$self->{'build-path'}/bin/sh", $shFake, { mode => 755 });

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
			warn _tr('debug-tool "%s" is not available.', $tool);
			next;
		}
		slxsystem("cp -p $toolPath $self->{'build-path'}/bin");
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
		warn _tr('tool "dhclient" is not available, using "udhcpc" instead.');
		return;
	}
	slxsystem("cp -p $toolPath $self->{'build-path'}/bin");
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
	
	slxsystem("cp -p $binary $self->{'build-path'}$targetPath");
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
		slxsystem("cp -p $toolPath $self->{'build-path'}/bin");
		$self->_addRequiredLibsFor($toolPath);
	}

	return;
}

sub _copyRequiredLibs
{
	my $self = shift;

	foreach my $lib (keys %{$self->{'required-libs'}}) {
		slxsystem("cp -p $lib $self->{'build-path'}/lib/");
	}

	return;
}

sub _addRequiredLibsFor
{
	my $self   = shift;
	my $binary = shift;

	my @libs = $self->{'lib-scanner'}->determineRequiredLibs($binary);
	foreach my $lib (@libs) {
		$self->{'required-libs'}->{$lib} = 1;
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
	spitFile("$self->{'build-path'}/etc/initramfs-setup", $content);
	
	return;
}

sub _writeSlxSystemConf
{
	my $self = shift;
	
	# generate slxsystem.conf file with variables that are needed
	# in stage3 init.
	# TODO: either put this stuff in initramfs-setup or find another solution
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
	spitFile("$self->{'build-path'}/etc/sysconfig/slxsystem.conf", $slxConf);

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

