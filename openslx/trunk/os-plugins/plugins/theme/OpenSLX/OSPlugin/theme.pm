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
# theme.pm
#    - implementation of the 'theme' plugin, which applies theming to the 
#     following places:
#        + bootsplash (via splashy)
#        + displaymanager (gdm, kdm, ...)
#        + desktop (to be done)
# -----------------------------------------------------------------------------
package OpenSLX::OSPlugin::theme;

use strict;
use warnings;

use base qw(OpenSLX::OSPlugin::Base);

use OpenSLX::Basics;
use OpenSLX::Utils;

sub new
{
    my $class = shift;

    my $self = {
        name => 'theme',
    };

    return bless $self, $class;
}

sub getInfo
{
    my $self = shift;

    return {
        description => unshiftHereDoc(<<'        End-of-Here'),
            Applies a graphical theme to the displaymanager.
        End-of-Here
        precedence => 40,
    };
}

sub getAttrInfo
{
    my $self = shift;

    return {
        'theme::active' => {
            applies_to_systems => 1,
            applies_to_clients => 0,
            description => unshiftHereDoc(<<'            End-of-Here'),
                should the 'theme'-plugin be executed during boot?
            End-of-Here
            content_regex => qr{^(0|1)$},
            content_descr => '1 means active - 0 means inactive',
            default => '1',
        },
        'theme::displaymanager' => {
            applies_to_systems => 1,
            applies_to_clients => 0,
            description => unshiftHereDoc(<<'            End-of-Here'),
                name of the theme to apply to displaymanager (unset for no theme)
            End-of-Here
            content_regex => undef,
            content_descr => undef,
            default => 'openslx',
        },
        'theme::desktop' => {
            applies_to_systems => 1,
            applies_to_clients => 0,
            description => unshiftHereDoc(<<'            End-of-Here'),
                name of the theme to apply to desktop (unset for no theme)
            End-of-Here
            content_regex => undef,
            content_descr => undef,
            default => 'openslx',
        },
    };
}

sub copyRequiredFilesIntoInitramfs
{
    my $self                = shift;
    my $targetPath          = shift;
    my $attrs                = shift;
    my $makeInitRamFSEngine = shift;
    
    my $themeDir = "$openslxConfig{'base-path'}/share/themes";

    my $displayManagerTheme = $attrs->{'theme::displaymanager'} || '';
    if ($displayManagerTheme) {
        my $displayManagerThemeDir 
            = "$themeDir/$displayManagerTheme/displaymanager";
        if (-d $displayManagerThemeDir) {
            $makeInitRamFSEngine->addCMD(
                "mkdir -p $targetPath/usr/share/themes"
            );
            $makeInitRamFSEngine->addCMD(
                "cp -a $displayManagerThemeDir $targetPath/usr/share/themes/"
            );
        }
    }
    else {
        $displayManagerTheme = '<none>';
    }

    vlog(
        1, 
        _tr(
            "theme-plugin: displaymanager=%s", $displayManagerTheme)
    );

    return;
}

1;
