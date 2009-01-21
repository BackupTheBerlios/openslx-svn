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
	
	return bless $self, $class;
}

sub execute
{
	my $self = shift;

	$self->_setupBuildPath();

	$self->_addRequiredFSMods();
	
	$self->_writeInitramfsSetup();

	$self->_copyDistroSpecificFiles();
	$self->_copyInitramfsFiles();

#	foreach my $plugin (@{$self->{'plugin-instances'}}) {
#		$plugin->specifyInitramfsAttrs($initramfsAttrs);
#	}

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
				my $relName 
					= length($File::Find::name) > $len
						? substr($File::Find::name, $len+1)
						: '';
				my $file = followLink($File::Find::name);
				if (-d) {
					mkpath("$self->{'build-path'}/$relName");
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
					);
					$text =~ s{\@\@\@([^\@]+)\@\@\@}{
						if (!exists $macro{$1}) {
							warn "unknown macro \@\@\@$1\@\@\@ found in $File::Find::name";
							'';
						} else {
							$macro{$1};
						}
					}eogms;
					
					# force sh shebang over to ash
					$text =~ s{^#!\s*/bin/sh}{#!/bin/ash};
					
					spitFile("$self->{'build-path'}/$relName", $text);
				}
			},
			no_chdir => 1,
		},
		$initramfsPath
	);

	return;
}

sub _addRequiredFSMods
{
	my $self = shift;
	
	my $osExportEngine = instantiateClass("OpenSLX::OSExport::Engine");
	$osExportEngine->initializeFromExisting($self->{'export-name'});
	my $fsMods = $self->{attrs}->{ramfs_fsmods} || '';
	foreach my $fsMod ($osExportEngine->requiredFSMods()) {
		$fsMods .= " $fsMod" if $fsMods !~ m{$fsMod};
	}
	$self->{attrs}->{ramfs_fsmods} = $fsMods;
	
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

