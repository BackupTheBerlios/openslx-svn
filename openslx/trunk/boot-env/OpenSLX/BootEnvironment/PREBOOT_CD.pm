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
# BootEnvironment::PREBOOT_CD.pm
#    - provides CD-specific implementation of the BootEnvironment API.
# -----------------------------------------------------------------------------
package OpenSLX::BootEnvironment::PREBOOT_CD;

use strict;
use warnings;

use base qw(OpenSLX::BootEnvironment::Base);

use Clone qw(clone);
use File::Basename;
use File::Path;

use OpenSLX::Basics;
use OpenSLX::MakeInitRamFS::Engine::PrebootCD;
use OpenSLX::Utils;

sub initialize
{
    my $self   = shift;
    my $params = shift;
    
    return if !$self->SUPER::initialize($params);

    $self->{'original-path'} = "$openslxConfig{'public-path'}/preboot-cd";
    $self->{'target-path'}   = "$openslxConfig{'public-path'}/preboot-cd.new";

    if (!$self->{'dry-run'}) {
        mkpath([$self->{'original-path'}]);
        rmtree($self->{'target-path'});
        mkpath("$self->{'target-path'}/client-config");
    }

    return 1;
}

sub finalize
{
    my $self   = shift;
    my $delete = shift;

    return $self->SUPER::finalize($delete);
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

#    my $pxePath       = $self->{'target-path'};
#    my $pxeConfigPath = "$pxePath/pxelinux.cfg";
#
#    my $pxeConfig    = $self->_getTemplate();
#    my $pxeFile      = "$pxeConfigPath/$externalClientID";
#    my $clientAppend = $client->{attrs}->{kernel_params_client} || '';
#    vlog(1, _tr("writing PXE-file %s", $pxeFile));
#
#    # set label for each system
#    foreach my $info (@$systemInfos) {
#        my $label = $info->{label} || '';
#        if (!length($label) || $label eq $info->{name}) {
#            if ($info->{name} =~ m{^(.+)::(.+)$}) {
#                my $system = $1;
#                my $exportType = $2;
#                $label = $system . ' ' x (40-length($system)) . $exportType;
#            } else {
#                $label = $info->{name};
#            }
#        }
#        $info->{label} = $label;
#    }
#    my $slxLabels = '';
#    foreach my $info (sort { $a->{label} cmp $b->{label} } @$systemInfos) {
#        my $vendorOSName = $info->{'vendor-os'}->{name};
#        my $kernelName   = basename($info->{'kernel-file'});
#        my $append       = $info->{attrs}->{kernel_params};
#        $append .= " initrd=$vendorOSName/$info->{'initramfs-name'}";
#        $append .= " $clientAppend";
#        $slxLabels .= "LABEL openslx-$info->{'external-id'}\n";
#        $slxLabels .= "\tMENU LABEL ^$info->{label}\n";
#        $slxLabels .= "\tKERNEL $vendorOSName/$kernelName\n";
#        $slxLabels .= "\tAPPEND $append\n";
#        $slxLabels .= "\tIPAPPEND 1\n";
#        my $helpText = $info->{description} || '';
#        if (length($helpText)) {
#            # make sure that text matches the given margin
#            my $margin = $openslxConfig{'pxe-theme-menu-margin'} || 0;
#            my $marginAsText = ' ' x $margin;
#            $helpText =~ s{^}{$marginAsText}gms;
#            $slxLabels .= "\tTEXT HELP\n$helpText\n\tENDTEXT\n";
#        }
#    }
#    # now add the slx-labels (inline or appended) and write the config file
#    if (!($pxeConfig =~ s{\@\@\@SLX_LABELS\@\@\@}{$slxLabels})) {
#        $pxeConfig .= $slxLabels;
#    }
#
#    # PXE uses 'cp850' (codepage 850) but our string is in utf-8, we have
#    # to convert in order to avoid showing gibberish on the client side...
#    spitFile($pxeFile, $pxeConfig, { 'io-layer' => 'encoding(cp850)' } );

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

sub _createImage
{
    my $self   = shift;
    my $client = shift;
    my $info   = shift;
    
    vlog(
        0, 
        _tr(
            "\ncreating CD-image for client %s (based on %s) ...", 
            $client->{name}, $info->{name}
        )
    );

    my $imageDir = "$openslxConfig{'public-path'}/images/$client->{name}";
    mkpath($imageDir)   unless $self->{'dry-run'};

    # copy static data and init script
    my $dataDir = "$openslxConfig{'base-path'}/share/boot-env/preboot-cd";
    slxsystem(qq{rsync -rlpt $dataDir/iso "$imageDir/"})
        unless $self->{'dry-run'};

    # copy kernel (take the one from the given system info)
    my $kernelFile = $info->{'kernel-file'};
    my $kernelName = basename($kernelFile);
    slxsystem(qq{cp -p "$kernelFile" "$imageDir/iso/isolinux/vmlinuz"})
        unless $self->{'dry-run'};

    # create initramfs
    my $initramfsName = qq{"$imageDir/iso/isolinux/initramfs"};
    $self->_makePrebootInitRamFS($info, $initramfsName);

    # write trivial isolinux config
    my $isolinuxConfig = unshiftHereDoc(<<"    End-of-Here");
        DEFAULT OpenSLX
        LABEL OpenSLX
        SAY Now loading OpenSLX preboot environment ...
        KERNEL vmlinuz
        APPEND initrd=initramfs
    End-of-Here
    spitFile("$imageDir/iso/isolinux/isolinux.cfg", $isolinuxConfig);

    my $mkisoCmd = unshiftHereDoc(<<"    End-of-Here");
        mkisofs 
            -o "$imageDir/../$client->{name}.iso"
            -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 
            -r -J -l -boot-info-table -joliet-long
            -publisher "OpenSLX Project - http://www.openslx.org" 
            -p "OpenSLX Project - openslx-devel\@openslx.org" 
            -V "OpenSLX BootCD"
            -volset "OpenSLX Project - PreBoot CD for non PXE/TFTP start of a Linux Stateless Client"
            -c isolinux/boot.cat "$imageDir/iso"
    End-of-Here
    $mkisoCmd =~ s{\n\s*}{ }gms;
    my $logFile = "$imageDir/../$client->{name}.iso.log";
    if (slxsystem(qq{$mkisoCmd 2>"$logFile"})) {
        my $log = slurpFile($logFile);
        die _tr("unable to create ISO-image - log follows:\n%s", $log);
    }

#    rmtree($imageDir);

    return 1;
}

sub _makePrebootInitRamFS
{
    my $self       = shift;
    my $info       = shift;
    my $initramfs  = shift;

    my $vendorOS = $info->{'vendor-os'};
    my $kernelFile = basename(followLink($info->{'kernel-file'}));

    my $attrs = clone($info->{attrs} || {});

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
    };

    # TODO: make debug-level an explicit attribute, it's used in many places!
    my $kernelParams = $info->{attrs}->{kernel_params} || '';
    if ($kernelParams =~ m{debug(?:=(\d+))?}) {
        my $debugLevel = defined $1 ? $1 : '1';
        $params->{'debug-level'} = $debugLevel;
    }

    my $makeInitRamFSEngine 
        = OpenSLX::MakeInitRamFS::Engine::PrebootCD->new($params);
    $makeInitRamFSEngine->execute($self->{'dry-run'});

    # copy back kernel-params, as they might have been changed (by plugins)
    $info->{attrs}->{kernel_params} 
        = join ' ', $makeInitRamFSEngine->kernelParams();

    return;
}

1;
