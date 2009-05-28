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
# BootEnvironment::PrebootCD.pm
#    - provides CD-specific implementation of the BootEnvironment API.
# -----------------------------------------------------------------------------
package OpenSLX::BootEnvironment::PrebootCD;

use strict;
use warnings;

use base qw(OpenSLX::BootEnvironment::Preboot);

use Clone qw(clone);
use File::Basename;
use File::Path;

use OpenSLX::Basics;
use OpenSLX::Utils;

sub initialize
{
    my $self   = shift;
    my $params = shift;
    
    return if !$self->SUPER::initialize($params);

    $self->{'original-path'} = "$openslxConfig{'public-path'}/preboot";
    $self->{'target-path'}   = "$openslxConfig{'public-path'}/preboot.new";

    if (!$self->{'dry-run'}) {
        mkpath([$self->{'original-path'}]);
        rmtree($self->{'target-path'});
        mkpath("$self->{'target-path'}/client-config");
    }

    return 1;
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

    # copy static data
    my $dataDir = "$openslxConfig{'base-path'}/share/boot-env/preboot/cd";
    slxsystem(qq{rsync -rlpt $dataDir/iso "$imageDir/"})
        unless $self->{'dry-run'};

    # copy kernel (take the one from the given system info)
    my $kernelFile = $info->{'kernel-file'};
    my $kernelName = basename($kernelFile);
    slxsystem(qq{cp -p "$kernelFile" "$imageDir/iso/isolinux/vmlinuz"})
        unless $self->{'dry-run'};

    # create initramfs
    my $initramfsName = qq{"$imageDir/iso/isolinux/initramfs"};
    $self->_makePrebootInitRamFS($info, $initramfsName, $client);

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

    rmtree($imageDir);

    return 1;
}

1;
