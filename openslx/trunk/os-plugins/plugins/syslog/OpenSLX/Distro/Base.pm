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
# syslog/OpenSLX/Distro/Base.pm
#    - provides base implementation of the Distro API for the syslog plugin.
# -----------------------------------------------------------------------------
package syslog::OpenSLX::Distro::Base;

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

sub runlevelInfo
{
    my $self  = shift;
    my $attrs = shift;
    
    # most distros (well: Debian & Ubuntu) use a different initscript depending
    # on which version of syslog is installed ('syslogd' or 'syslog-ng')
    my $kind = lc($attrs->{'syslog::kind'});
    my %nameMap = (
        'syslogd'   => 'sysklogd',
        'syslog-ng' => 'syslog-ng',
    );
    my $rlInfo = {
        scriptName => $nameMap{$kind},
        startAt    => 2,
        stopAt     => 15,
    };

    return $rlInfo;
}

1;
