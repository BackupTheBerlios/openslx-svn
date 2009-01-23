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
# BootEnvironment::CD.pm
#    - provides CD-specific implementation of the BootEnvironment API.
# -----------------------------------------------------------------------------
package OpenSLX::BootEnvironment::CD;

use strict;
use warnings;

use base qw(OpenSLX::BootEnvironment::Base);

use Clone qw(clone);
use File::Basename;
use File::Path;

use OpenSLX::Basics;
use OpenSLX::MakeInitRamFS::Engine;
use OpenSLX::Utils;

sub writeFilesRequiredForBooting
{
    my $self          = shift;
    my $info          = shift;
    my $tftpbuildPath = shift;
    my $slxVersion    = shift;

print "CD-boot not implemented yet\n";

return 1;

    my $kernelFile = $info->{'kernel-file'};
    my $kernelName = basename($kernelFile);

    my $vendorOSPath = "$tftpbuildPath/$info->{'vendor-os'}->{name}";
    mkpath $vendorOSPath unless -e $vendorOSPath || $self->{'dry-run'};

    my $targetKernel = "$vendorOSPath/$kernelName";
    if (!-e $targetKernel) {
        vlog(1, _tr('copying kernel %s to %s', $kernelFile, $targetKernel));
        slxsystem(qq[cp -p "$kernelFile" "$targetKernel"])
            unless $self->{'dry-run'};
    }
    my $initramfs = "$vendorOSPath/$info->{'initramfs-name'}";
    $self->_makeInitRamFS($info, $initramfs, $slxVersion);
    
    return 1;
}

sub _makeInitRamFS
{
    my $self       = shift;
    my $info       = shift;
    my $initramfs  = shift;
    my $slxVersion = shift;

    vlog(1, _tr('generating initialramfs %s', $initramfs));

    my $vendorOS = $info->{'vendor-os'};
    my $kernelFile = basename(followLink($info->{'kernel-file'}));

    my $attrs = clone($info->{attrs} || {});

    my $params = {
        'attrs'          => $attrs,
        'export-name'    => $info->{export}->{name},
        'export-uri'     => $info->{'export-uri'},
        'initramfs'      => $initramfs,
        'kernel-params'  => [ split ' ', ($info->{kernel_params} || '') ],
        'kernel-version' => $kernelFile =~ m[-(.+)$] ? $1 : '',
        'plugins'        => $info->{'active-plugins'},
        'root-path'
            => "$openslxConfig{'private-path'}/stage1/$vendorOS->{name}",
        'slx-version'    => $slxVersion,
        'system-name'    => $info->{name},
    };

    # TODO: make debug-level an explicit attribute, it's used in many places!
    my $kernelParams = $info->{kernel_params} || '';
    if ($kernelParams =~ m{debug(?:=(\d+))?}) {
        my $debugLevel = defined $1 ? $1 : '1';
        $params->{'debug-level'} = $debugLevel;
    }

    my $makeInitRamFSEngine = OpenSLX::MakeInitRamFS::Engine->new($params);
    $makeInitRamFSEngine->execute($self->{'dry-run'});

    # copy back kernel-params, as they might have been changed (by plugins)
    $info->{kernel_params} = join ' ', $makeInitRamFSEngine->kernelParams();

    return;
}

1;
