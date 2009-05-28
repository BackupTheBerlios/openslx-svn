# Copyright (c) 2008 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your suggestions, praise, or complaints to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org/
# -----------------------------------------------------------------------------
# BootEnvironment::Preboot.pm
#    - provides general preboot implementation of the BootEnvironment API.
# -----------------------------------------------------------------------------
package OpenSLX::BootEnvironment::Preboot;

use strict;
use warnings;

use base qw(OpenSLX::BootEnvironment::Base);

use Clone qw(clone);
use File::Basename;
use File::Path;

use OpenSLX::Basics;
use OpenSLX::ConfigDB qw(:support);
use OpenSLX::MakeInitRamFS::Engine::Preboot;
use OpenSLX::Utils;

sub initialize
{
    my $self   = shift;
    my $params = shift;
    
    return if !$self->SUPER::initialize($params);

    $self->{'original-path'} = "$openslxConfig{'public-path'}/preboot";
    $self->{'target-path'}   = "$openslxConfig{'public-path'}/preboot.new";

    $self->{'requires-default-client-config'} = 0;
        # we do not need a default.tgz since there's always an explicit client
    
    if (!$self->{'dry-run'}) {
        mkpath([$self->{'original-path'}]);
        rmtree($self->{'target-path'});
        mkpath("$self->{'target-path'}/client-config");
    }

    return 1;
}

sub writeBootloaderMenuFor
{
    my $self             = shift;
    my $client           = shift;
    my $externalClientID = shift;
    my $systemInfos      = shift || [];

    $self->_prepareBootloaderConfigFolder() 
        unless $self->{preparedBootloaderConfigFolder};

    my $prebootSystemInfo
        = clone($self->_pickSystemWithNewestKernel($systemInfos));
    $self->_createImage($client, $prebootSystemInfo);

    my $externalClientName   = externalConfigNameForClient($client);
    my $bootloaderPath       = "$self->{'target-path'}/bootloader";
    my $bootloaderConfigPath = "$bootloaderPath/$externalClientName";
    mkpath($bootloaderConfigPath)   unless $self->{'dry-run'};
    my $menuFile = "$bootloaderConfigPath/bootmenu.dialog";
    
    my $clientAppend = $client->{attrs}->{kernel_params_client} || '';
    vlog(1, _tr("writing bootmenu %s", $menuFile));

    # set label for each system
    foreach my $info (@$systemInfos) {
        my $label = $info->{label} || '';
        if (!length($label) || $label eq $info->{name}) {
            $label = $info->{name};
        }
        $info->{label} = $label;
    }
    my $bootmenuEntries = '';
    my $entryState = 'on';
    my $counter = 1;
    foreach my $info (sort { $a->{label} cmp $b->{label} } @$systemInfos) {
        my $vendorOSName = $info->{'vendor-os'}->{name};
        my $kernelName   = basename($info->{'kernel-file'});
        my $append       = $info->{attrs}->{kernel_params} || '';
        $append .= " $clientAppend";
        $bootmenuEntries .= qq{ "$counter" "$info->{label}" };
        $entryState = 'off';

        # create a file containing the boot-configuration for this system
        my $systemDescr = unshiftHereDoc(<<"        End-of-Here");
            label="$info->{label}"
            kernel="$vendorOSName/$kernelName"
            initramfs="$vendorOSName/$info->{'initramfs-name'}"
            append="$append"
        End-of-Here
        my $systemFile = "$bootloaderConfigPath/$info->{name}";
        spitFile(
            $systemFile, $systemDescr, { 'io-layer' => 'encoding(iso8859-1)' } 
        )    unless $self->{'dry-run'};
        slxsystem(qq{ln -sf $info->{name} $bootloaderConfigPath/$counter});
        $counter++;
    }

    my $entryCount = @$systemInfos;
    my $bootmenu = unshiftHereDoc(<<"    End-of-Here");
        --no-cancel --menu "OpenSLX Boot Menu" 20 65 $entryCount $bootmenuEntries
    End-of-Here
    
    if (!$self->{'dry-run'}) {
        # default to iso encoding, let's see how uclibc copes with it ...
        spitFile($menuFile, $bootmenu, { 'io-layer' => 'encoding(iso8859-1)' });

        # copy the preboot script into the folder to be tared
        my $prebootBasePath 
            = "$openslxConfig{'base-path'}/share/boot-env/preboot";
        slxsystem(qq{cp $prebootBasePath/preboot.sh $bootloaderConfigPath/});
        slxsystem(qq{chmod a+x $bootloaderConfigPath/preboot.sh});

        # create a tar which can/will be downloaded by prebooting clients
        my $tarCMD 
            = qq{cd $bootloaderConfigPath; tar -czf "${bootloaderConfigPath}.env" *};
        slxsystem($tarCMD);
        rmtree($bootloaderConfigPath);
    }

    return 1;
}

sub _prepareBootloaderConfigFolder
{
    my $self = shift;
    
    my $bootloaderPath = "$self->{'target-path'}/bootloader";
    if (!$self->{'dry-run'}) {
        rmtree($bootloaderPath);
        mkpath($bootloaderPath);
    }

    $self->{preparedBootloaderConfigFolder} = 1;

    return 1;
}

sub _pickSystemWithNewestKernel
{
    my $self        = shift;
    my $systemInfos = shift;

    my $systemWithNewestKernel;
    my $newestKernelFileSortKey = '';
    foreach my $system (@$systemInfos) {
        next unless $system->{'kernel-file'} =~ m{
            (?:vmlinuz|x86)-(\d+)\.(\d+)\.(\d+)(?:\.(\d+))?-(\d+(?:\.\d+)?)
        }x;
        my $sortKey 
            = sprintf("%02d.%02d.%02d.%02d-%2.1f", $1, $2, $3, $4||0, $5);
        if ($newestKernelFileSortKey lt $sortKey) {
            $systemWithNewestKernel  = $system;
            $newestKernelFileSortKey = $sortKey;
        }
    }

    if (!defined $systemWithNewestKernel) {
        die _tr("unable to pick a system to be used for preboot!");
    }
    return $systemWithNewestKernel;
}

sub _makePrebootInitRamFS
{
    my $self       = shift;
    my $info       = shift;
    my $initramfs  = shift;
    my $client     = shift;

    my $vendorOS = $info->{'vendor-os'};
    my $kernelFile = basename(followLink($info->{'kernel-file'}));

    my $attrs = clone($info->{attrs} || {});

    my $bootURI = $client->{attrs}->{boot_uri};
    if (!$bootURI) {
        die _tr("client $client->{name} needs an URI in attribute 'boot_uri' to be used for preboot!");
    }

    chomp(my $slxVersion = qx{slxversion});

    my $params = {
        'attrs'          => $attrs,
        'export-name'    => undef,
        'export-uri'     => undef,
        'initramfs'      => $initramfs,
        'kernel-params'  
            => [ split ' ', ($info->{attrs}->{kernel_params} || '') ],
        'kernel-version' => $kernelFile =~ m[-(.+)$] ? $1 : '',
        'plugins'        => '',
        'root-path'
            => "$openslxConfig{'private-path'}/stage1/$vendorOS->{name}",
        'slx-version'    => $slxVersion,
        'system-name'    => $info->{name},
        'preboot-id'     => $client->{name},
        'boot-uri'       => $bootURI,
    };

    # TODO: make debug-level an explicit attribute, it's used in many places!
    my $kernelParams = $info->{attrs}->{kernel_params} || '';
    if ($kernelParams =~ m{debug(?:=(\d+))?}) {
        my $debugLevel = defined $1 ? $1 : '1';
        $params->{'debug-level'} = $debugLevel;
    }

    my $makeInitRamFSEngine 
        = OpenSLX::MakeInitRamFS::Engine::Preboot->new($params);
    $makeInitRamFSEngine->execute($self->{'dry-run'});

    # copy back kernel-params, as they might have been changed (by plugins)
    $info->{attrs}->{kernel_params} 
        = join ' ', $makeInitRamFSEngine->kernelParams();

    return;
}

1;
