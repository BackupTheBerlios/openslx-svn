# Copyright (c) 2006-2008 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your suggestions, praise, or complaints to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org/
# -----------------------------------------------------------------------------
# MakeInitialRamFS::Engine::Preboot.pm
#    - provides driver engine for MakeInitialRamFS API, implementing the
#      base of all preboot variants.
# -----------------------------------------------------------------------------
package OpenSLX::MakeInitRamFS::Engine::Preboot;

use strict;
use warnings;

use base qw(OpenSLX::MakeInitRamFS::Engine::Base);

use OpenSLX::Basics;
use OpenSLX::Utils;

################################################################################
### implementation methods
################################################################################
sub _collectCMDs
{
    my $self = shift;
    
    $self->{CMDs} = [];

    $self->_setupBuildPath();

    $self->_writeInitramfsSetup();
    $self->_writeSlxSystemConf();

    $self->_copyUclibcRootfs();
    $self->_copyPrebootSpecificFiles();

    $self->{distro}->applyChanges($self);

    $self->_copyKernelModules();
    
    $self->_createInitRamFS();

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
        lib
        mnt 
        proc 
        root 
        sbin
        sys 
        tmp 
        var/lib
        var/run
    );
    $self->addCMD(
        'mkdir -p ' . join(' ', map { "$buildPath/$_"; } @stdFolders)
    );
    
    $self->{'build-path'} = $buildPath;
    
    return;
}
    
sub _writeInitramfsSetup
{
    my $self = shift;
    
    # generate initramfs-setup file containing attributes that are
    # relevant for the initramfs only (before there's a root-FS) -
    # this override adds the name of the client such that the booting
    # system has an ID to use for accessing the corresponding boot environment
    # on the server
    my $initramfsAttrs = {
        'host_name'      => 'slx-client', # just to have something at all
        'ramfs_miscmods' => $self->{attrs}->{ramfs_miscmods} || '',
        'ramfs_nicmods'  => $self->{attrs}->{ramfs_nicmods} || '',
        'preboot_id'     => $self->{'preboot-id'} || '',
        'boot_uri'       => $self->{'boot-uri'} || '',
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

sub _copyUclibcRootfs
{
    my $self = shift;

    my $uclibcRootfs = "$openslxConfig{'base-path'}/share/uclib-rootfs";
    
    my @excludes = qw(
    );

    # exclude strace unless this system is in debug mode
    if (!$self->{'debug-level'}) {
        push @excludes, 'strace';
    }

    my $exclOpts = join ' ', map { "--exclude $_" } @excludes;

    $self->addCMD("rsync $exclOpts -rlpt $uclibcRootfs/ $self->{'build-path'}");
    
    return 1;
}

sub _copyPrebootSpecificFiles
{
    my $self = shift;

    # write secondary rootfs-layer (including init) on top of base layer
    my $prebootRootfs 
        = "$openslxConfig{'base-path'}/share/boot-env/preboot/uclib-rootfs";
    $self->addCMD("rsync -rlpt $prebootRootfs/ $self->{'build-path'}");

    return 1;
}

1;
