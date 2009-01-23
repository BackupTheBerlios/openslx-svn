# Copyright (c) 2006, 2007 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your suggestions, praise, or complaints to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org/
# -----------------------------------------------------------------------------
# desktop/OpenSLX/Distro/Suse_10_2.pm
#    - provides SUSE-10.2-specific overrides of the Distro API for the desktop
#      plugin.
# -----------------------------------------------------------------------------
package desktop::OpenSLX::Distro::Suse_10_2;

use strict;
use warnings;

use base qw(desktop::OpenSLX::Distro::Suse);

use OpenSLX::Basics;
use OpenSLX::Utils;

################################################################################
### interface methods
################################################################################

sub GDMPathInfo
{
    my $self = shift;
    
    my $pathInfo = $self->SUPER::GDMPathInfo();
    
    # link gdm.conf-custom instead of gdm.conf
    $pathInfo->{config} = '/etc/opt/gnome/gdm/custom.conf';

    return $pathInfo;
}

sub GDMConfigHashForWorkstation
{
    my $self = shift;
    
    my $configHash = $self->SUPER::GDMConfigHashForWorkstation();
    $configHash->{'daemon'}->{SessionDesktopDir} =
        '/usr/share/xsessions/:/etc/X11/sessions/';
                    
    return $configHash;
}                        

1;
