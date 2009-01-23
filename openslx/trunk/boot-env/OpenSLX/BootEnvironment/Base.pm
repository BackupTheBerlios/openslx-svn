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
# BootEnvironment::Base.pm
#    - provides empty base of the BootEnvironment API.
# -----------------------------------------------------------------------------
package OpenSLX::BootEnvironment::Base;

use strict;
use warnings;

our $VERSION = 1.01;        # API-version . implementation-version

use Clone qw(clone);
use File::Basename;
use File::Path;

use OpenSLX::Basics;
use OpenSLX::ConfigDB;
use OpenSLX::MakeInitRamFS::Engine;
use OpenSLX::Utils;

our %initramfsMap;

sub new
{
    my $class  = shift;

    my $self = {};

    return bless $self, $class;
}

sub initialize
{
    my $self   = shift;
    my $params = shift;

    $self->{'dry-run'} = $params->{'dry-run'};

    return 1;
}

sub finalize
{
    my $self   = shift;
    my $delete = shift;

    return 1 if $self->{'dry-run'};
    
    my $rsyncDeleteClause = $delete ? '--delete' : '';
    my $rsyncCmd 
        = "rsync -a $rsyncDeleteClause --delay-updates $self->{'target-path'}/ $self->{'original-path'}/";
    slxsystem($rsyncCmd) == 0
        or die _tr(
            "unable to rsync files from '%s' to '%s'! (%s)", 
            $self->{'target-path'}, $self->{'original-path'}, $!
        );
    rmtree([$self->{'target-path'}]);

    return 1;
}

sub writeBootloaderMenuFor
{
    my $self             = shift;
    my $client           = shift;
    my $externalClientID = shift;
    my $systemInfos      = shift;

    return;
}

sub writeFilesRequiredForBooting
{
    my $self       = shift;
    my $info       = shift;
    my $buildPath  = shift;
    my $slxVersion = shift;

    my $kernelFile = $info->{'kernel-file'};
    my $kernelName = basename($kernelFile);

    my $vendorOSPath = "$self->{'target-path'}/$info->{'vendor-os'}->{name}";
    mkpath $vendorOSPath unless -e $vendorOSPath || $self->{'dry-run'};

    my $targetKernel = "$vendorOSPath/$kernelName";
    if (!-e $targetKernel) {
        vlog(1, _tr('copying kernel %s to %s', $kernelFile, $targetKernel));
        slxsystem(qq[cp -p "$kernelFile" "$targetKernel"])
            unless $self->{'dry-run'};
    }
    
    # reuse initramfs if it has already been created for another boot 
    # environment, create it otherwise:
    my $initramfsName = "$vendorOSPath/$info->{'initramfs-name'}";
    my $initramfsID = $info->{'initramfs-name'};
    my $cached = $initramfsMap{$initramfsID};
    if ($cached) {
        my $file = $cached->{file};
        vlog(1, _tr('copying initialramfs %s from %s', $initramfsName, $file));
        slxsystem("cp -a $file $initramfsName") unless $self->{'dry-run'};
        $info->{kernel_params} = $cached->{kernel_params};
        return 0;
    }
    else {
        vlog(1, _tr('generating initialramfs %s', $initramfsName));
        $self->_makeInitRamFS($info, $initramfsName, $slxVersion);
        $initramfsMap{$initramfsID} = {
            file          => $initramfsName,
            kernel_params => $info->{kernel_params},
        };
        return 1;
    }
}

sub _makeInitRamFS
{
    my $self       = shift;
    my $info       = shift;
    my $initramfs  = shift;
    my $slxVersion = shift;

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
