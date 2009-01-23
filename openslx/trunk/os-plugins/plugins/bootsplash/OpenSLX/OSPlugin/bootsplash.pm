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
# bootsplash.pm
#    - implementation of the 'bootsplash' plugin, which installs splashy 
#     into the ramfs, including changeing theme
# -----------------------------------------------------------------------------
package OpenSLX::OSPlugin::bootsplash;

use strict;
use warnings;

use base qw(OpenSLX::OSPlugin::Base);

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
            Installs Splashy as bootsplash into ramfs and sets a Theme.
        End-of-Here
        precedence => 30,
    };
}

sub getAttrInfo
{
    my $self = shift;

    return {
        'bootsplash::active' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                should the 'bootsplash'-plugin be executed during boot?
            End-of-Here
            content_regex => qr{^(0|1)$},
            content_descr => '1 means active - 0 means inactive',
            default => '1',
        },

        'bootsplash::theme' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                name of the theme to apply to bootsplash (unset for no theme)
            End-of-Here
            content_regex => undef,
            content_descr => undef,
            default => 'openslx',
        },
    };
}

sub suggestAdditionalKernelParams
{
    my $self                = shift;
    my $makeInitRamFSEngine = shift;

    my @suggestedParams;
    
    # add vga=0x317 unless explicit vga-mode is already set
    if (!$makeInitRamFSEngine->haveKernelParam(qr{\bvga=})) {
        push @suggestedParams, 'vga=0x317';
    }

    # add quiet, if not already set
    if (!$makeInitRamFSEngine->haveKernelParam('quiet')) {
        push @suggestedParams, 'quiet';
    }

    return @suggestedParams;
}

sub suggestAdditionalKernelModules
{
    my $self                = shift;
    my $makeInitRamFSEngine = shift;

    my @suggestedModules;
    
    # Ubuntu needs vesafb and fbcon (which drags along some others)
    if ($makeInitRamFSEngine->{'distro-name'} =~ m{^ubuntu}i) {
        push @suggestedModules, qw( vesafb fbcon )
    }
    
    return @suggestedModules;
}

sub copyRequiredFilesIntoInitramfs
{
    my $self                = shift;
    my $targetPath          = shift;
    my $attrs               = shift;
    my $makeInitRamFSEngine = shift;
    
    my $themeDir = "$openslxConfig{'base-path'}/share/themes";
    my $bootsplashTheme = $attrs->{'bootsplash::theme'} || '';
    if ($bootsplashTheme) {
        my $bootsplashThemeDir = "$themeDir/$bootsplashTheme/bootsplash";
        if (-d $bootsplashThemeDir) {
            my $splashyPath = "$openslxConfig{'base-path'}/share/splashy";
            $makeInitRamFSEngine->addCMD(
                "cp -p $splashyPath/* $targetPath/bin/"
            );
            $makeInitRamFSEngine->addCMD(
                "mkdir -p $targetPath/etc/splashy"
            );
            $makeInitRamFSEngine->addCMD(
                "cp -a $bootsplashThemeDir/* $targetPath/etc/splashy/"
            );
        }
    }
    else {
        $bootsplashTheme = '<none>';
    }

    vlog(
        1, 
        _tr(
            "bootsplash-plugin: bootsplash=%s", 
            $bootsplashTheme
        )
    );

    return;
}

1;
