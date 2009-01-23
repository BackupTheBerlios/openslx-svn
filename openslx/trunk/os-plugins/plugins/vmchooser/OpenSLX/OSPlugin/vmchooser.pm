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
# vmchooser.pm
#    - allows user to pick from a list of virtual machin images
# -----------------------------------------------------------------------------
package OpenSLX::OSPlugin::vmchooser;

use strict;
use warnings;

use base qw(OpenSLX::OSPlugin::Base);

use OpenSLX::Basics;
use OpenSLX::Utils;

sub new
{
    my $class = shift;

    my $self = {
        name => 'vmchooser',
    };

    return bless $self, $class;
}

sub getInfo
{
    my $self = shift;

    return {
        description => unshiftHereDoc(<<'        End-of-Here'),
            allows user to pick from a list of different virtual machine images
            based on xml-files, which tell about available images.
        End-of-Here
        precedence => 50,
    };
}

sub getAttrInfo
{
    my $self = shift;

    return {
        'vmchooser::active' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                should the 'vmchooser'-plugin be executed during boot?
            End-of-Here
            content_regex => qr{^(0|1)$},
            content_descr => '1 means active - 0 means inactive',
            default => '1',
        },
    };
}


sub installationPhase
{
    my $self = shift;
    my $info = shift;
    
    my $pluginRepoPath  = $info->{'plugin-repo-path'};
    my $openslxBasePath = $info->{'openslx-base-path'};

    # copy all needed files now:
    my $pluginName = $self->{'name'};
    my $pluginBasePath = "$openslxBasePath/lib/plugins/$pluginName/files";
    foreach my $file ( qw( vmchooser printer.sh scanner.sh ) ) {
        copyFile("$pluginBasePath/$file", "$pluginRepoPath/");
    }

    return;
}

sub removalPhase
{
    my $self = shift;
    my $info = shift;

    return;
}

1;

