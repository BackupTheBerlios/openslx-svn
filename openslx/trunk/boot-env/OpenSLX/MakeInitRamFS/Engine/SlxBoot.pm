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
# MakeInitialRamFS::Engine::SlxBoot.pm
#    - provides driver engine for MakeInitialRamFS API, implementing the
#      standard slx boot behaviour (i.e. booting a system remotely).
# -----------------------------------------------------------------------------
package OpenSLX::MakeInitRamFS::Engine::SlxBoot;

use strict;
use warnings;

use base qw(OpenSLX::MakeInitRamFS::Engine::Base);

use File::Basename;
use File::Find;
use File::Path;
use POSIX qw(strftime);

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

    $self->_addRequiredFSMods();
    
    $self->_writeInitramfsSetup();
    $self->_writeSlxSystemConf();

    $self->_copyUclibcRootfs();
    $self->_copyHwinfo();
    $self->_copyDistroSpecificFiles();
    $self->_copyInitramfsFiles();
    
    $self->_copyPreAndPostinitFiles();

    $self->_calloutToPlugins();

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
        etc/init-hooks
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
    
    # concatenate default- and distro-specific functions into one file
    my $functions = slurpFile("$distroSpecsPath/$distroName/functions-default");
    $functions .= "\n";
    $functions .= slurpFile(
        "$distroSpecsPath/$distroName/functions-$distroVer",
        { failIfMissing => 0 }
    );
    $self->addCMD( {
        file    => "$self->{'build-path'}/etc/distro-functions",
        content => $functions,
    } );
    
    return 1;
}

sub _copyUclibcRootfs
{
    my $self = shift;

    my $uclibcRootfs = "$openslxConfig{'base-path'}/share/uclib-rootfs";

    $self->addCMD("rsync -rlpt $uclibcRootfs/ $self->{'build-path'}");
    
    return 1;
}

sub _copyHwinfo
{
    my $self = shift;

    my $baseDir = "$openslxConfig{'base-path'}/share/ramfstools/hwinfo";

    my $version = $self->{distro}->determineMatchingHwinfoVersion(
        $self->{'distro-ver'}
    );

    $self->addCMD("cp $baseDir/bin/hwinfo-$version $self->{'build-path'}/usr/bin/hwinfo");
    my $libHD = "libhd.so.$version";
    $self->addCMD("cp $baseDir/lib/$libHD $self->{'build-path'}/usr/lib");
    my $libName = $libHD;
    while($libName =~ s{\.\d+$}{}g) {
        $self->addCMD("ln -sf $libHD $self->{'build-path'}/usr/lib/$libName");
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

1;
