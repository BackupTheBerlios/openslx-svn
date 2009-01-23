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
# desktop.pm
#    - implementation of the 'desktop' plugin, which installs  
#     all needed information for a displaymanager and for the desktop. 
# -----------------------------------------------------------------------------
package OpenSLX::OSPlugin::desktop;

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
        name => 'desktop',
    };

    return bless $self, $class;
}

sub getInfo
{
    my $self = shift;

    return {
        description => unshiftHereDoc(<<'        End-of-Here'),
            Sets a desktop and creates needed configs, theme can be set as well.
        End-of-Here
        precedence => 40,
    };
}

sub getAttrInfo
{
    my $self = shift;

    return {
        'desktop::active' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                should the 'desktop'-plugin be executed during boot?
            End-of-Here
            content_regex => qr{^(0|1)$},
            content_descr => '1 means active - 0 means inactive',
            default => '1',
        },
        'desktop::manager' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                which display manager to start: gdm, kdm or xdm?
            End-of-Here
            content_regex => qr{^(g|k|x)dm$},
            content_descr => '"gdm", "kdm" or "xdm"',
            default => undef,
        },
        'desktop::kind' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                which desktop environment shall be used: gnome, kde, or xfce?
            End-of-Here
            content_regex => qr{^(gnome|kde|xfce)$},
            content_descr => '"gnome", "kde" or "xfce"',
            default => undef,
        },
        'desktop::mode' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                which type of operation mode shall be activated:
                    workstattion, kiosk or chooser?
            End-of-Here
            content_regex => qr{^(workstation|kiosk|chooser)$},
            content_descr => '"workstation", "kiosk" or "chooser"',
            default => 'workstation',
        },
        'desktop::theme' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                name of the theme to apply to the desktop (unset for no theme)
            End-of-Here
            content_descr => 'one of the entries in "supported_themes"',
            default => 'openslx',
        },
        'desktop::supported_themes' => {
            applies_to_vendor_os => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                name of all themes that shall be installed in vendor-OS (such
                that they can be selected via 'desktop::theme' in stage 3).
            End-of-Here
            content_descr => 'a comma-separated list of theme names',
            default => 'openslx',
        },
        'desktop::gdm' => {
            applies_to_vendor_os => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                should gdm be available (installed in vendor-OS)?
            End-of-Here
            content_regex => qr{^0|1$},
            content_descr => '"0", "1" or "-" (for unset)',
            default => undef,
        },
        'desktop::kdm' => {
            applies_to_vendor_os => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                should kdm be available (installed in vendor-OS)?
            End-of-Here
            content_regex => qr{^0|1$},
            content_descr => '"0", "1" or "-" (for unset)',
            default => undef,
        },
        'desktop::xdm' => {
            applies_to_vendor_os => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                should xdm be available (installed in vendor-OS)?
            End-of-Here
            content_regex => qr{^0|1$},
            content_descr => '"0", "1" or "-" (for unset)',
            default => undef,
        },
        'desktop::gnome' => {
            applies_to_vendor_os => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                should gnome be available (installed in vendor-OS)?
            End-of-Here
            content_regex => qr{^0|1$},
            content_descr => '"0", "1" or "-" (for unset)',
            default => undef,
        },
        'desktop::kde' => {
            applies_to_vendor_os => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                should kde be available (installed in vendor-OS)?
            End-of-Here
            content_regex => qr{^0|1$},
            content_descr => '"0", "1" or "-" (for unset)',
            default => undef,
        },
        'desktop::xfce' => {
            applies_to_vendor_os => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                should xfce be available (installed in vendor-OS)?
            End-of-Here
            content_regex => qr{^0|1$},
            content_descr => '"0", "1" or "-" (for unset)',
            default => undef,
        },
    };
}

sub getDefaultAttrsForVendorOS
{
    my $self         = shift;
    my $vendorOSName = shift;

    my $attrs = $self->getAttrInfo();
    
    if ($vendorOSName =~ m{kde}) {
        $attrs->{'desktop::manager'}->{default} = 'kdm';
        $attrs->{'desktop::kind'}->{default} = 'kde';
    }
    elsif ($vendorOSName =~ m{gnome}) {
        $attrs->{'desktop::manager'}->{default} = 'gdm';
        $attrs->{'desktop::kind'}->{default} = 'gnome';
    }
    elsif ($vendorOSName =~ m{xfce}) {
        $attrs->{'desktop::manager'}->{default} = 'xdm';
        $attrs->{'desktop::kind'}->{default} = 'xcfe';
    }
    else {
        $attrs->{'desktop::manager'}->{default}
            = $self->{distro}->getDefaultDesktopManager();
        $attrs->{'desktop::kind'}->{default}
            = $self->{distro}->getDefaultDesktopKind();
    }
    return $attrs;
}

sub installationPhase
{
    my $self = shift;
    
    $self->{pluginRepositoryPath} = shift;
    $self->{pluginTempPath}       = shift;
    $self->{openslxPath}          = shift;
    $self->{attrs}                = shift;
    
    # We are going to change some of the stage1 attributes during installation
    # (basically we are filling the ones that are not defined). Since the result
    # of these changes might change between invocations, we do not want to store
    # the resulting values, but we want to store the original (undef).
    # In order to do so, we copy all stage1 attributes directly into the
    # object hash and change them there.
    $self->{gdm}   = $self->{attrs}->{'desktop::gdm'};
    $self->{kdm}   = $self->{attrs}->{'desktop::kdm'};
    $self->{xdm}   = $self->{attrs}->{'desktop::xdm'};
    $self->{gnome} = $self->{attrs}->{'desktop::gnome'};
    $self->{kde}   = $self->{attrs}->{'desktop::kde'};
    $self->{xcfe}  = $self->{attrs}->{'desktop::xfce'};
    
    $self->_installRequiredPackages();
    $self->_fillUnsetStage1Attrs();
    $self->_ensureSensibleStage3Attrs();

    # start to actually do something - according to current stage1 attributes
    if ($self->{gdm}) {
        $self->_setupGDM();
    }
    if ($self->{kdm}) {
        $self->_setupKDM();
    }
    if ($self->{xdm}) {
        $self->_setupXDM();
    }
    $self->_setupSupportedThemes();

    return;
}

sub removalPhase
{
    my $self = shift;
    my $pluginRepositoryPath = shift;
    my $pluginTempPath = shift;

    return;
}

sub copyRequiredFilesIntoInitramfs
{
    my $self                = shift;
    my $targetPath          = shift;
    my $attrs               = shift;
    my $makeInitRamFSEngine = shift;
    
    my $themeDir     = "$openslxConfig{'base-path'}/share/themes";
    my $desktopXdmcp = $attrs->{'desktop::xdmcp'} || '';
    my $xdmcpConfigDir 
        = "$openslxConfig{'base-path'}/lib/plugins/desktop/files/$desktopXdmcp";
    my $desktopTheme = $attrs->{'desktop::theme'} || '';
    if ($desktopTheme) {
        my $desktopThemeDir 
            = "$themeDir/$desktopTheme/desktop/$desktopXdmcp";
        if (-d $desktopThemeDir) {
            $makeInitRamFSEngine->addCMD(
                "mkdir -p $targetPath/usr/share/files"
            );
            $makeInitRamFSEngine->addCMD(
                "mkdir -p $targetPath/usr/share/themes"
            );
            $makeInitRamFSEngine->addCMD(
                "cp -a $desktopThemeDir $targetPath/usr/share/themes/"
            );
            $makeInitRamFSEngine->addCMD(
                "cp -a $xdmcpConfigDir $targetPath/usr/share/files"
            );
        }
    }
    else {
        $desktopTheme = '<none>';
    }

    vlog(
        1, 
        _tr(
            "desktop-plugin: desktop=%s", 
            $desktopTheme
        )
    );

    return;
}

sub _installRequiredPackages
{
    my $self  = shift;

    my $engine = $self->{'os-plugin-engine'};
    
    if ($self->{'gnome'} && !$self->{distro}->isGNOMEInstalled()) {
        $self->{distro}->installGNOME();
    }
    if ($self->{'gdm'} && !$self->{distro}->isGDMInstalled()) {
        $self->{distro}->installGDM();
    }
    if ($self->{'kde'} && !$self->{distro}->isKDEInstalled()) {
        $self->{distro}->installKDE();
    }
    if ($self->{'kdm'} && !$self->{distro}->isKDMInstalled()) {
        $self->{distro}->installKDM();
    }
    if ($self->{'xfce'} && !$self->{distro}->isXFCEInstalled()) {
        $self->{distro}->installXFCE();
    }
    if ($self->{'xdm'} && !$self->{distro}->isXDMInstalled()) {
        $self->{distro}->installXDM();
    }

    return 1;
}

sub _fillUnsetStage1Attrs
{
    my $self = shift;

    if (!defined $self->{'gnome'}) {
        $self->{'gnome'} = $self->{distro}->isGNOMEInstalled();
    }
    if (!defined $self->{'gdm'}) {
        $self->{'gdm'} = $self->{distro}->isGDMInstalled();
    }
    if (!defined $self->{'kde'}) {
        $self->{'kde'} = $self->{distro}->isKDEInstalled();
    }
    if (!defined $self->{'kdm'}) {
        $self->{'kdm'} = $self->{distro}->isKDMInstalled();
    }
    if (!defined $self->{'xfce'}) {
        $self->{'xfce'} = $self->{distro}->isXFCEInstalled();
    }
    if (!defined $self->{'xdm'}) {
        $self->{'xdm'} = $self->{distro}->isXDMInstalled();
    }

    return 1;
}

sub _ensureSensibleStage3Attrs
{
    my $self = shift;

    # check if current desktop kind is enabled at all and select another
    # one, if it isn't
    my $kind = $self->{attrs}->{'desktop::kind'} || '';
    if (!$self->{$kind}) {
        my @desktops = map { $self->{$_} ? $_ : () } qw( gnome kde xfce );
        if (!@desktops) {
            die _tr(
                "no desktop kind is possible, plugin 'desktop' wouldn't work!"
            );
        }
        print _tr("selecting %s as desktop kind\n", $desktops[0]);
        $self->{attrs}->{'desktop::kind'} = $desktops[0];
    }

    # check if current desktop manager is enabled at all and select another
    # one, if it isn't
    my $manager = $self->{attrs}->{'desktop::manager'} || '';
    if (!$self->{$manager}) {
        my @managers = map { $self->{$_} ? $_ : () } qw( gdm kdm xdm );
        if (!@managers) {
            die _tr(
                "no desktop manager is possible, plugin 'desktop' wouldn't work!"
            );
        }
        print _tr("selecting %s as desktop manager\n", $managers[0]);
        $self->{attrs}->{'desktop::manager'} = $managers[0];
    }

    return 1;
}

sub _setupGDM
{
    my $self = shift;
    
    my $repoPath = $self->{pluginRepositoryPath};
    mkpath([ 
        "$repoPath/gdm/workstation",
        "$repoPath/gdm/kiosk",
        "$repoPath/gdm/chooser",
    ]);
    
    $self->_setupGDMScript();

    my $configHash = $self->{distro}->GDMConfigHashForWorkstation();
    $self->_writeConfigHash($configHash, "$repoPath/gdm/workstation/gdm.conf");
    
    $configHash = $self->{distro}->GDMConfigHashForKiosk();
    $self->_writeConfigHash($configHash, "$repoPath/gdm/kiosk/gdm.conf");

    $configHash = $self->{distro}->GDMConfigHashForChooser();
    $self->_writeConfigHash($configHash, "$repoPath/gdm/chooser/gdm.conf");

    return;    
}

sub _setupGDMScript
{
    my $self = shift;
    
    my $repoPath = $self->{pluginRepositoryPath};
    my $script = $self->{distro}->setupGDMScript($repoPath);

    spitFile("$repoPath/gdm/desktop.sh", $script);

    return;
}

sub _setupKDM
{
    my $self = shift;

    my $repoPath = $self->{pluginRepositoryPath};
    mkpath([ 
        "$repoPath/kdm/workstation",
        "$repoPath/kdm/kiosk",
        "$repoPath/kdm/chooser",
    ]);
    
    $self->_setupKDMScript();

    my $configHash = $self->{distro}->KDMConfigHashForWorkstation();
    $self->_writeConfigHash($configHash, "$repoPath/kdm/workstation/kdmrc");
    
    $configHash = $self->{distro}->KDMConfigHashForKiosk();
    $self->_writeConfigHash($configHash, "$repoPath/kdm/kiosk/kdmrc");

    $configHash = $self->{distro}->KDMConfigHashForChooser();
    $self->_writeConfigHash($configHash, "$repoPath/kdm/chooser/kdmrc");

    return;
}

sub _setupKDMScript
{
    my $self = shift;
    
    my $repoPath = $self->{pluginRepositoryPath};
    my $script = $self->{distro}->setupKDMScript($repoPath);

    spitFile("$repoPath/kdm/desktop.sh", $script);

    return;
}

sub _setupXDM
{
    my $self = shift;
}

sub _writeConfigHash
{
    my $self = shift;
    my $hash = shift || {};
    my $file = shift;
    
    my $content = '';
    for my $domain (sort keys %$hash) {
        $content .= "[$domain]\n";
        for my $key (sort keys %{$hash->{$domain}}) {
            my $value 
                = defined $hash->{$domain}->{$key} 
                    ? $hash->{$domain}->{$key}
                    : '';
            $content .= "$key=$value\n";
        }
        $content .= "\n";
    }
    spitFile($file, $content);
}

sub _setupSupportedThemes
{
    my $self = shift;

    my $supportedThemes = $self->{attrs}->{'desktop::supported_themes'} || '';
    my @supportedThemes = split m{\s*,\s*}, $supportedThemes;
    return if !@supportedThemes;

    my $themeBaseDir = "$self->{openslxPath}/lib/plugins/desktop/themes";
    THEME:
    for my $theme (@supportedThemes) {
        my $themeDir = "$themeBaseDir/$theme";
        if (!-e $themeDir) {
            warn _tr('theme "%s" not found - skipped!', $theme);
            next;
        }
        my $themeTargetPath = "$self->{pluginRepositoryPath}/themes";
        mkpath($themeTargetPath);
        vlog(1, "installing theme '$theme'...");
        slxsystem("cp -a $themeDir $themeTargetPath/$theme") == 0
            or die _tr('unable to copy theme %s (%s)', $theme, $!);
    }
}

1;
