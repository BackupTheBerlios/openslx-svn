# Copyright (c) 2009 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your suggestions, praise, or complaints to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org/
# -----------------------------------------------------------------------------
# pvs.pm - plugin to use the pool video switch tools within OpenSLX environment
# -----------------------------------------------------------------------------
package OpenSLX::OSPlugin::pvs;

use strict;
use warnings;

use base qw(OpenSLX::OSPlugin::Base);

use OpenSLX::Basics;
use OpenSLX::Utils;

sub new
{
    my $class = shift;
    my $self = {
        name => 'pvs',
    };

    return bless $self, $class;
}

sub getInfo
{
    my $self = shift;
    return {
        description => unshiftHereDoc(<<'        End-of-Here'),
            enables pvs server (user or xorg)
        End-of-Here
        # waits for xorg to add configuration if needed
        precedence => 70,
    };
}

sub getAttrInfo
{
    my $self = shift;

    return {
        'pvs::active' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                should the 'pvs' plugin be executed during boot?
            End-of-Here
            content_regex => qr{^(0|1)$},
            content_descr => '1 means active - 0 means inactive',
            default => '1',
        },

        'pvs::mode' => {
            applies_to_systems => 1,
            applies_to_clients => 0,
            description => unshiftHereDoc(<<'            End-of-Here'),
                set pvs to listen on Xorg user sessions (default), general
                access to the Xorg server (including displaymanager login) and
                console framebuffer.
            End-of-Here
            content_regex => qr{^(x11user|x11mod|fb)$},
            content_descr => 'x11user for user, x11mod for access via Xorg module or fb',
            default => 'x11user',
        },

        'pvs::scale' => {
            applies_to_systems => 1,
            applies_to_clients => 0,
            description => unshiftHereDoc(<<'            End-of-Here'),
                scale screen size (e.g. as fraction 2/3 or as decimal 0.5)
            End-of-Here
            content_regex => undef,
            content_descr => undef,
            default => '',
        },

    };
}

sub installationPhase
{
    my $self = shift;
    my $info = shift;
    
    my $pluginRepositoryPath = $info->{'plugin-repo-path'};
    my $pluginTempPath       = $info->{'plugin-temp-path'};
    my $openslxBasePath      = $info->{'openslx-base-path'};

    # should we distinguish between the two different packages!?
    # libvnc should be part of the xorg package!? (so no check needed)
    #my $engine = $self->{'os-plugin-engine'};
    #if (!isInPath('pvs')) {
    #    $engine->installPackages(
    #        $engine->getInstallablePackagesForSelection('pvs')
    #    );
    #} else {
    #    vlog(3, "pvs is already installed");
    #}

    # get path of files we need to install
    my $pluginFilesPath = "$openslxBasePath/lib/plugins/$self->{'name'}/files";
    my $script = $self->{distro}->fillRunlevelScript();

    # copy all needed files now
    copyFile("$pluginFilesPath/*", "$pluginRepositoryPath");

    # link these files

    #chmod 0755, "/etc/init.d/pvs";

}

sub removalPhase
{
    my $self = shift;
    my $info = shift;
}

1;
