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
# BootEnvironment::Preboot::Base.pm
#    - base of the Preboot-BootEnvironment API.
# -----------------------------------------------------------------------------
package OpenSLX::BootEnvironment::Preboot::Base;

use strict;
use warnings;

use File::Basename;

use Clone qw(clone);

use OpenSLX::Basics;
use OpenSLX::MakeInitRamFS::Engine::Preboot;
use OpenSLX::Utils;

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

sub makePrebootInitRamFS
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

sub createImage
{
    my $self   = shift;
    my $client = shift;
    my $info   = shift;
    
    # override in subclasses!
    
    return 1;
}

1;
