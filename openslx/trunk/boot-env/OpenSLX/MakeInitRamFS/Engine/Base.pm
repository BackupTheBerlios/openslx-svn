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
# MakeInitialRamFS::Engine::Base.pm
#    - provides basic driver engine for MakeInitialRamFS API.
# -----------------------------------------------------------------------------
package OpenSLX::MakeInitRamFS::Engine::Base;

use strict;
use warnings;

use File::Basename;
use POSIX qw(strftime);

use OpenSLX::Basics;
use OpenSLX::LibScanner;
use OpenSLX::OSPlugin::Roster;
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
        'kernel-params'  => '!',
        'kernel-version' => '!',
        'plugins'        => '!',
        'root-path'      => '!',
        'slx-version'    => '!',
        'system-name'    => '!',
        'preboot-id'     => '?',
        'boot-uri'       => '?',
    } );

    my $self = $params;

    $self->{'system-name'} =~ m{^([^\-]+)-([^:\-]+)}
        or die "unable to extract distro-info from $self->{'system-name'}!";

    $self->{'distro-name'} = lc($1);
    $self->{'distro-ver'} = $2;
    
    my $fullDistroName = lc($1) . '-' . $2;

    $self->{distro} = loadDistroModule({
        distroName  => $fullDistroName,
        distroScope => 'OpenSLX::MakeInitRamFS::Distro',
    });
    if (!$self->{distro}) {
        die _tr(
            'unable to load any MakeInitRamFS::Distro module for system %s!',
            $self->{'system-name'}
        );
    }
    
    $self->{'lib-scanner'} 
        = OpenSLX::LibScanner->new({ 'root-path' => $self->{'root-path'} });
    
    $self->{'suggested-kernel-modules'} = [];
    $self->{'filtered-kernel-modules'}  = [];

    return bless $self, $class;
}

sub execute
{
    my $self   = shift;
    my $dryRun = shift;

    $self->_collectCMDs();

    vlog(1, _tr("creating initramfs '%s' ...", $self->{'initramfs'}));
    $self->_executeCMDs() unless $dryRun;

    return;
}

sub haveKernelParam
{
    my $self  = shift;
    my $param = shift;
    
    return ref $param eq 'Regexp'
        ? grep { $_ =~ $param } @{ $self->{'kernel-params'} }
        : grep { $_ eq $param } @{ $self->{'kernel-params'} };
}

sub addKernelParams
{
    my $self = shift;
    
    push @{ $self->{'kernel-params'} }, @_;
    
    return;
}

sub kernelParams
{
    my $self = shift;
    
    return @{ $self->{'kernel-params'} };
}

sub addKernelModules
{
    my $self = shift;
    
    push @{ $self->{'suggested-kernel-modules'} }, @_;
    
    return;
}

################################################################################
### implementation methods
################################################################################
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
        if (substr($path, 0, 5) ne '/lib/') {
            # some distros (e.g. ubuntu-9) use a local path instead of an
            # absolute path, we need to make it absolute:
            $path = "/lib/modules/$self->{'kernel-version'}/$path";
        }
        my $module = $2;
        my $dependentsList = $3;
        my $fullModulePath = "$path/$module.ko";
        $modulePath{$module} = [] if !exists $modulePath{$module};
        push @{$modulePath{$module}}, $fullModulePath;
        $dependentModules{$fullModulePath} = [
            map {
                if (substr($_, 0, 5) ne '/lib/') {
                    # some distros (e.g. ubuntu-9) use a local path instead of an
                    # absolute path, we need to make it absolute:
                    $_ = "/lib/modules/$self->{'kernel-version'}/$_";
                }
                $_;
            }
            split ' ', $dependentsList
        ];
    }

    my $targetPath 
        = "$self->{'build-path'}/lib/modules/$self->{'kernel-version'}";
    $self->addCMD("mkdir -p $targetPath");
    $self->addCMD("cp -p $sourcePath/modules.* $targetPath/");
    
    # add a couple of kernel modules that we expect to be used in stage3
    # (some of these modules do not exist on all distros, so they will be
    # filtered out again by the respective distro object):
    my @kernelModules = qw(
        af_packet unix hid usbhid uhci-hcd ohci-hcd vesafb fbcon
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
            if (! grep { $_ eq $kernelModule    } 
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
        my $source = followLink(
            "$self->{'root-path'}$moduleToBeCopied", $self->{'root-path'}
        );
        my $target = "$self->{'build-path'}$moduleToBeCopied";
        $self->addCMD("cp -p --dereference $source $target");
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

sub _writeInitramfsSetup
{
    my $self = shift;
    
    # generate initramfs-setup file containing attributes that are
    # relevant for the initramfs only (before there's a root-FS):
    my $initramfsAttrs = {
        'host_name'      => 'slx-client', # just to have something at all
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
    my $slxConf = unshiftHereDoc(<<"    End-of-Here");
        slxconf_date=$date
        slxconf_kernver=$self->{'kernel-version'}
        slxconf_listnwmod="$self->{attrs}->{ramfs_nicmods}"
        slxconf_distro_name=$self->{'distro-name'}
        slxconf_distro_ver=$self->{'distro-ver'}
        slxconf_system_name=$self->{'system-name'}
        slxconf_slxver="$self->{'slx-version'}"
    End-of-Here
    $self->addCMD( {
        file    => "$self->{'build-path'}/etc/slxsystem.conf", 
        content => $slxConf
    } );

    return;
}

sub _calloutToPlugins
{
    my $self = shift;

    my $pluginInitdPath = "$self->{'build-path'}/etc/plugin-init.d";
    my $initHooksPath   = "$self->{'build-path'}/etc/init-hooks";
    $self->addCMD("mkdir -p $pluginInitdPath $initHooksPath");

    foreach my $pluginName (@{$self->{'plugins'}}) {
        my $plugin = OpenSLX::OSPlugin::Roster->getPlugin($pluginName);
        next if !$plugin;

        # create a hash only containing the attributes relating to the
        # current plugin 
        my $allAttrs = $self->{attrs};
        my %pluginAttrs;
        for my $attrName (grep { $_ =~ m{^${pluginName}::} } keys %$allAttrs) {
            $pluginAttrs{$attrName} = $allAttrs->{$attrName};
        }

        # let plugin setup itself in the initramfs
        $plugin->setupPluginInInitramfs(\%pluginAttrs, $self);
    }
    return;
}

sub _createInitRamFS
{
    my $self = shift;

    my $buildPath = $self->{'build-path'};
    $self->addCMD("chroot $buildPath ldconfig");
    $self->addCMD(
        "cd $buildPath "
        . "&& find . "
            . "| cpio -H newc --quiet --create "
            . "| gzip -9 >$self->{initramfs}"
    );

    return;
}

1;
