# Copyright (c) 2008-2009 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your suggestions, praise, or complaints to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org/
# -----------------------------------------------------------------------------
# BootEnvironment::Preboot::CD.pm
#    - provides CD-specific implementation of the Preboot-BootEnvironment API.
# -----------------------------------------------------------------------------
package OpenSLX::BootEnvironment::Preboot::CD;

use strict;
use warnings;

use base qw(OpenSLX::BootEnvironment::Preboot::Base);

use File::Basename;
use File::Path;

use OpenSLX::Basics;
use OpenSLX::Utils;

sub createImage
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

    my $imageDir = "$openslxConfig{'public-path'}/images/$client->{name}/cd";
    my $isoDir = "$imageDir/iso/isolinux";
    mkpath($isoDir)     unless $self->{'dry-run'};

    # copy static data
    my $dataDir = "$openslxConfig{'base-path'}/share/boot-env/syslinux";
    for my $file ('LICENSE', 'README.iso', 'vesamenu.c32', 'isolinux.bin') {
        if (!-e "$isoDir/$file") {
            slxsystem(
                qq[cp -p "$dataDir/$file" "$isoDir/"]
            )
                unless $self->{'dry-run'};
        }
    }

    # copy kernel (take the one from the given system info)
    my $kernelFile = $info->{'kernel-file'};
    my $kernelName = basename($kernelFile);
    slxsystem(qq{cp -p "$kernelFile" "$isoDir/vmlinuz"})
        unless $self->{'dry-run'};

    # create initramfs
    my $initramfsName = qq{"$isoDir/initramfs"};
    $self->makePrebootInitRamFS($info, $initramfsName, $client);

    # write trivial isolinux config
    # include static defaults
    my $isolinuxConfig = "DEFAULT vesamenu.c32\n";
    $isolinuxConfig .= "PROMPT 0\n";
    $isolinuxConfig .= "TIMEOUT 100\n";

    # theme stuff
    my $basePath   = $openslxConfig{'base-path'};
    my $configPath = $openslxConfig{'config-path'};
    my $isoTheme   = $openslxConfig{'syslinux-theme'};

    my $isoThemePath;
    my $isoThemeInConfig
        = "$configPath/boot-env/syslinux/themes/${isoTheme}";
    my $isoThemeInBase
        = "$basePath/share/boot-env/syslinux/themes/${isoTheme}";
    if (-e "$isoThemeInConfig/theme.conf") {
        $isoThemePath = $isoThemeInConfig;
    }
    else {
        if (-e "$isoThemeInBase/theme.conf") {
            $isoThemePath = $isoThemeInBase;
        }
    }
    # include theme specific stuff
    if (defined $isoThemePath) {
        $isolinuxConfig .= slurpFile("$isoThemePath/theme.conf");
    }

    # copy background picture if exists
    my $pic;
    if (defined $isoTheme) {
        while ($isolinuxConfig =~ m{^\s*MENU BACKGROUND (\S+?)\s*$}gims) {
            chomp($pic = $1);
        }
    }
    if (defined $pic) {
        my $isoBackground = "$isoThemePath/$pic";
        if (-e $isoBackground && !$self->{'dry-run'}) {
            slxsystem(qq[cp "$isoBackground" "$isoDir/"]);
        }
    }

    # write trivial isolinux config
    $isolinuxConfig .= unshiftHereDoc(<<"    End-of-Here");
        MENU TITLE Welcome to OpenSLX PreBoot ISO/CD (Mini Linux/Kexec)
        LABEL SLXSTDBOOT
            MENU LABEL OpenSLX PreBoot - Stateless Netboot Linux ...
            MENU DEFAULT
            KERNEL vmlinuz
            APPEND initrd=initramfs vga=0x317
            TEXT HELP
                 Use this (default) entry if you have configured your client.
                 You have chance to edit the kernel commandline by hitting
                 the TAB key (e.g. for adding debug=3 to it for bug hunting).
            ENDTEXT
        LABEL LOCALBOOT
            MENU LABEL Boot locally (skip OpenSLX PreBoot) ...
            LOCALBOOT -1
            TEXT HELP
                 Gets you out of here by booting from next device in BIOS
                 boot order.
            ENDTEXT
    End-of-Here
    spitFile("$isoDir/isolinux.cfg", $isolinuxConfig);

    my $mkisoCmd = unshiftHereDoc(<<"    End-of-Here");
        mkisofs 
            -o "$imageDir/../$client->{name}.iso"
            -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 
            -r -J -l -boot-info-table -joliet-long
            -publisher "OpenSLX Project - http://www.openslx.org" 
            -p "OpenSLX Project - openslx-devel\@openslx.org" 
            -V "OpenSLX BootISO"
            -volset "OpenSLX Project - PreBoot ISO/CD for non PXE/TFTP start of a Linux Stateless Client"
            -c isolinux/boot.cat "$imageDir/iso"
    End-of-Here
    $mkisoCmd =~ s{\n\s*}{ }gms;
    my $logFile = "$imageDir/../$client->{name}.iso.log";
    if (slxsystem(qq{$mkisoCmd 2>"$logFile"})) {
        my $log = slurpFile($logFile);
        die _tr("unable to create ISO-image - log follows:\n%s", $log);
    }

    rmtree($imageDir);

    return 1;
}

1;
