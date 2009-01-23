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
# xserver/OpenSLX/Distro/Base.pm
#    - provides base implementation of the Distro API for the xserver plugin.
# -----------------------------------------------------------------------------
package xserver::OpenSLX::Distro::Base;

use strict;
use warnings;

our $VERSION = 1.01;        # API-version . implementation-version

use File::Basename;

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

sub setupXserverScript
{
    my $self     = shift;
    my $repoPath = shift;

    my $pathInfo   = $self->XserverPathInfo();
    my $configFile = $pathInfo->{config};

    my $script = unshiftHereDoc(<<"    End-of-Here");
        # xserver.sh (base part)
        # written by OpenSLX-plugin 'xserver'
        # repoPath is $repoPath

    End-of-Here
    
    return $script;
}

# not used yet, kept as example
sub XserverPathInfo
{
    my $self = shift;
    
    my $pathInfo = {
        config => '/etc/X11/xorg.conf',
        paths => [
            '/usr/bin',
        ],
    };

    return $pathInfo;
}

1;
