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
# bootlog.pm
#    - implementation of the 'bootlog' plugin, which installs  
#     all needed information for a displaymanager and for the bootlog. 
# -----------------------------------------------------------------------------
package OpenSLX::OSPlugin::bootlog;

use strict;
use warnings;

use base qw(OpenSLX::OSPlugin::Base);

use File::Basename;
use File::Path;

use OpenSLX::Basics;
use OpenSLX::Utils;

sub new
{
    my $class = shift;

    my $self = {
        name => 'bootlog',
    };

    return bless $self, $class;
}

sub getInfo
{
    my $self = shift;

    return {
        description => unshiftHereDoc(<<'        End-of-Here'),
            Sets up remote logging of boot process (via UPD).
        End-of-Here
        mustRunAfter => [],
    };
}

sub getAttrInfo
{
    my $self = shift;

    return {
        'bootlog::active' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                should the 'bootlog'-plugin be executed during boot?
            End-of-Here
            content_regex => qr{^(0|1)$},
            content_descr => '1 means active - 0 means inactive',
            default => '1',
        },
        'bootlog::target' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                ip:port where bootlog shall be sent to
            End-of-Here
            content_regex => undef,
            content_descr => 'allowed: gdm, kdm, xdm',
            default => undef,
        },
    };
}

1;
