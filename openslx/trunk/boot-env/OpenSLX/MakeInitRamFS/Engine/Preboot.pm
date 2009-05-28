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
    $self->_copyVariantSpecificFiles();

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

1;
