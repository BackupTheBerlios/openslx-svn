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
# syslog/OpenSLX/Distro/Suse.pm
#    - provides SUSE-specific overrides of the Distro API for the syslog plugin.
# -----------------------------------------------------------------------------
package syslog::OpenSLX::Distro::Suse;

use strict;
use warnings;

use base qw(syslog::OpenSLX::Distro::Base);

use OpenSLX::Basics;

################################################################################
### interface methods
################################################################################

sub runlevelInfo
{
    my $self  = shift;
    my $attrs = shift;
    
    my $rlInfo = $self->SUPER::runlevelInfo($attrs);

    # SUSE uses a script named 'syslog', no matter if syslogd or syslog-ng 
    # is installed
    $rlInfo->{scriptName} = 'syslog';

    return $rlInfo;
}

1;
