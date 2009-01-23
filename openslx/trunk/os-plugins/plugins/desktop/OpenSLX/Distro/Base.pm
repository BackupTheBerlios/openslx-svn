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
# desktop/OpenSLX/Distro/Base.pm
#    - provides base implementation of the Distro API for the desktop plugin.
# -----------------------------------------------------------------------------
package desktop::OpenSLX::Distro::Base;

use strict;
use warnings;

our $VERSION = 1.01;        # API-version . implementation-version

use OpenSLX::Basics;
use OpenSLX::Utils;

################################################################################
### interface methods
################################################################################
sub new
{
    my $class = shift;
    my $self = {};
    return bless $self, $class;
}

sub initialize
{
    my $self        = shift;
    $self->{engine} = shift;
    
    return 1;
}

sub isInPath
{
    my $self   = shift;
    my $binary = shift;
    
    my $path = qx{which $binary 2>/dev/null};

    return $path ? 1 : 0;
}

sub isGNOMEInstalled
{
    my $self = shift;

    return $self->isInPath('gnome-session');
}

sub isGDMInstalled
{
    my $self = shift;

    return $self->isInPath('gdm');
}

sub installGNOME
{
    my $self = shift;

    $self->{engine}->installPackages(
        $self->{engine}->getInstallablePackagesForSelection('gnome')
    );

    return 1;
}

sub installGDM
{
    my $self = shift;

    $self->{engine}->installPackages('gdm');

    return 1;
}

sub GDMPathInfo
{
    my $self = shift;
    
    my $pathInfo = {
        config => '/etc/gdm/gdm.conf',
        paths => [
            '/var/lib/gdm',
            '/var/log/gdm',
        ],
    };

    return $pathInfo;
}

sub GDMRunlevelLinks
{
    my $self   = shift;
    
    return unshiftHereDoc(<<"    End-of-Here");
        rllinker gdm 15 15
    End-of-Here
}

sub GDMConfigHashForWorkstation
{
    my $self = shift;
    
    return {
        'chooser' => {
        },
        'daemon' => {
            AutomaticLoginEnable => 'false',
            BaseXsession => '/etc/X11/Xsession',
            Group => 'gdm',
            User => 'gdm',
        },
        'debug' => {
            Enable => 'false',
        },
        'greeter' => {
            AllowShutdown => 'true',
            Browser => 'false',
            MinimalUID => '500',
            SecureShutdown => 'false',
            ShowDomain => 'false',
        },
        'gui' => {
        },
        'security' => {
            AllowRemoteRoot => 'false',
            DisallowTCP => 'true',
            SupportAutomount => 'true',
        },
        'server' => {
        },
        'xdmcp' => {
            Enable => 'false',
        },
    };
}

sub GDMConfigHashForKiosk
{
    my $self = shift;
    
    my $configHash = $self->GDMConfigHashForWorkstation();

    $configHash->{daemon}->{AutomaticLoginEnable} = 'true';
    $configHash->{daemon}->{AutomaticLogin} = 'nobody';

    return $configHash;
}

sub GDMConfigHashForChooser
{
    my $self = shift;
    
    my $configHash = $self->GDMConfigHashForWorkstation();
    $configHash->{xdmcp}->{Enable} = 'true';

    return $configHash;
}

sub isKDEInstalled
{
    my $self = shift;
    
    return $self->isInPath('startkde');
}

sub isKDMInstalled
{
    my $self = shift;

    return $self->isInPath('kdm');
}

sub installKDE
{
    my $self = shift;

    $self->{engine}->installPackages(
        $self->{engine}->getInstallablePackagesForSelection('kde')
    );

    return 1;
}

sub installKDM
{
    my $self = shift;

    $self->{engine}->installPackages('kdm');

    return 1;
}

sub isXFCEInstalled
{
    my $self = shift;

    return $self->isInPath('startxfce4');
}

sub isXDMInstalled
{
    my $self = shift;

    return $self->isInPath('xdm');
}

sub installXFCE
{
    my $self = shift;

    $self->{engine}->installPackages(
        $self->{engine}->getInstallablePackagesForSelection('xfce')
    );

    return 1;
}

sub installXDM
{
    my $self = shift;

    $self->{engine}->installPackages('xdm');

    return 1;
}

1;
