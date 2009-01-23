# Copyright (c) 2007 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your suggestions, praise, or complaints to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org/
# -----------------------------------------------------------------------------
# xen.pm
#    - implementation of the 'xen' plugin
# -----------------------------------------------------------------------------
package OpenSLX::OSPlugin::xen;

use strict;
use warnings;

use base qw(OpenSLX::OSPlugin::Base);

use File::Path;

use OpenSLX::Basics;
use OpenSLX::Utils;

sub new
{
    my $class = shift;

    my $self = {
        name => 'bootsplash',
    };

    return bless $self, $class;
}

sub getInfo
{
    my $self = shift;

    return {
        description => unshiftHereDoc(<<'        End-of-Here'),
            Configures Xen diskless boot, no installation yet.
        End-of-Here
        precedence => 10,
    };
}

sub getAttrInfo
{
    my $self = shift;

    return {
        'xen::active' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                should the 'xen'-plugin be executed during boot?
            End-of-Here
            content_regex => qr{^(0|1)$},
            content_descr => '1 means active - 0 means inactive',
            default => '1',
        },
    };
}

sub suggestAdditionalKernelModules
{
    my $self                = shift;
    my $makeInitRamFSEngine = shift;

    my @suggestedModules;
    
    # Ubuntu needs vesafb and fbcon (which drags along some others)
    if ($makeInitRamFSEngine->{'distro-name'} =~ m{^suse}i) {
        push @suggestedModules, qw( bridge netloop )
    }
    
    return @suggestedModules;
}

1;
