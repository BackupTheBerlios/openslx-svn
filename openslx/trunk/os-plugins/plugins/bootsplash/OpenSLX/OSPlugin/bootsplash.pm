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

use File::Path;

use OpenSLX::Basics;
use OpenSLX::Utils;
use OpenSLX::DistroUtils;

sub new
{
    my $class = shift;

    my $self = {
        name => 'bootsplash',
    };

    mkpath("$openslxConfig{'config-path'}/plugins/bootsplash/themes");

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

sub installationPhase
{
    my $self = shift;
    my $info = shift;

    $self->{pluginRepositoryPath} = $info->{'plugin-repo-path'};
    $self->{openslxBasePath}      = $info->{'openslx-base-path'};
    
    my $splashyBinPath =
        "$self->{openslxBasePath}/lib/plugins/bootsplash/files/bin";
    my $pluginRepoPath = "$self->{pluginRepositoryPath}";
    
    my $initFile = newInitFile();
    my $do_stop = unshiftHereDoc(<<"  End-of-Here");
        /opt/openslx/plugin-repo/bootsplash/bin/splashy shutdown 
        sleep 1
        /opt/openslx/plugin-repo/bootsplash/bin/splashy_update \\
        "progress 100\" 2>/dev/null
    End-of-Here
   
    # add helper function to initfile
    # first parameter name of the function
    # second parameter content of the function
    $initFile->addFunction('do_start', '# do nothing here');
    $initFile->addFunction('do_stop', $do_stop);
    
    # place a call of the helper function in the stop block
    # of the init file
    # first parameter name of the function
    # second parameter name of the block
    $initFile->addFunctionCall('do_stop', 'stop');
    
    my $distro = (split('-',$self->{'os-plugin-engine'}->distroName()))[0];
    
    # write initfile to filesystem
    spitFile(
        "$pluginRepoPath/bootsplash.halt",
        getInitFileForDistro($initFile, ucfirst($distro))
    );

    # copy splashy(_update) into plugin-repo folder
    mkpath("$pluginRepoPath/bin");
    mkpath("$pluginRepoPath/lib");
    slxsystem("cp -a $splashyBinPath/* $pluginRepoPath/bin") == 0
        or die _tr(
                "unable to copy splashy to $pluginRepoPath/bin"
        );
    # create a proper (distro specific) runlevel script for halt
    #my $initfile = newInitFile();
    #$initfile->addDaemon("");
    #
    #my $runlevelscript = getInitFileForDistro($initfile, "ubuntu");

    return;
}

sub removalPhase
{
    my $self = shift;
    my $info = shift;

    return;
}


sub copyRequiredFilesIntoInitramfs
{
    my $self                = shift;
    my $targetPath          = shift;
    my $attrs               = shift;
    my $makeInitRamFSEngine = shift;
    
    my $bootsplashDir = "$openslxConfig{'base-path'}/lib/plugins/bootsplash";
    my $bootsplashConfigDir 
        = "$openslxConfig{'config-path'}/plugins/bootsplash";
    my $bootsplashTheme = $attrs->{'bootsplash::theme'} || '';
    my $splashyThemeDir = '';

    if ($bootsplashTheme) {
        my $bootsplashThemeDir = "$bootsplashDir/files/themes/$bootsplashTheme";
        my $altThemeDir = "$bootsplashConfigDir/themes/$bootsplashTheme";
        if (-d $bootsplashThemeDir) {
            $splashyThemeDir = "$bootsplashThemeDir";
        }
        elsif (-d $altThemeDir) {
            $splashyThemeDir = "$altThemeDir";
        }
        if (-d $splashyThemeDir) {
            my $splashyPath = "$bootsplashDir/files/bin";
            $makeInitRamFSEngine->addCMD(
                "cp -p $splashyPath/splashy* $targetPath/bin/"
            );
            $makeInitRamFSEngine->addCMD(
                "mkdir -p $targetPath/etc/splashy/themes"
            );
            $makeInitRamFSEngine->addCMD(
                "cp -a $splashyThemeDir $targetPath/etc/splashy/themes/"
            );
            my $defSplashyTheme = "/etc/splashy/themes/$bootsplashTheme";
            my $splashyConfig = unshiftHereDoc(<<"            End-of-Here");
                <?xml version="1.0" encoding="UTF-8"?>
                <!-- Autogenerated by OpenSLX-plugin 'bootsplash' -->
                <splashy>
                    <!-- themes directory: -->
                    <themes>/etc/splashy/themes</themes>
                    <!-- current theme (relative path) -->
                    <current_theme>$bootsplashTheme</current_theme>
                    <!-- full path to theme, fall back in case of problems -->
                    <default_theme>$defSplashyTheme</default_theme>
                    <pid>/etc/splashy/splashy.pid</pid>
                    <fifo>/dev/.initramfs/splashy.fifo</fifo>
                </splashy>
            End-of-Here
            $makeInitRamFSEngine->addCMD( {
                file    => "$targetPath/etc/splashy/config.xml",
                content => $splashyConfig,
            } );
        }
    }
    else {
        $bootsplashTheme = '<none>';
    }

    vlog(1, _tr("bootsplash-plugin: bootsplash=%s", $bootsplashTheme));

    return;
}

1;
