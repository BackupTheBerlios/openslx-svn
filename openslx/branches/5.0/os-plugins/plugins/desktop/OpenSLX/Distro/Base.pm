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
# desktop/OpenSLX/Distro/Base.pm
#    - provides base implementation of the Distro API for the desktop plugin.
# -----------------------------------------------------------------------------
package desktop::OpenSLX::Distro::Base;

use strict;
use warnings;

our $VERSION = 1.01;        # API-version . implementation-version

use File::Basename;

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

sub getDefaultDesktopManager
{
    my $self = shift;
    
    # the default implementation prefers GDM over KDM over XDM
    return $self->isGDMInstalled() ? 'gdm' 
        : $self->isKDMInstalled() ? 'kdm' 
        : $self->isXDMInstalled() ? 'xdm' : undef;
}

sub getDefaultDesktopKind
{
    my $self = shift;
    
    # the default implementation prefers GNOME over KDE over XFCE
    return $self->isGNOMEInstalled() ? 'gnome' 
        : $self->isKDEInstalled() ? 'kde' 
        : $self->isXFCEInstalled() ? 'xfce' : undef;
}

sub isGNOMEInstalled
{
    my $self = shift;

    return isInPath('gnome-session');
}

sub installGNOME
{
    my $self = shift;

    $self->{engine}->installPackages(
        $self->{engine}->getInstallablePackagesForSelection('gnome')
    );

    return 1;
}

sub isGDMInstalled
{
    my $self = shift;

    return isInPath('gdm');
}

sub installGDM
{
    my $self = shift;

    $self->{engine}->installPackages('gdm');

    return 1;
}

sub GDMPathInfo
{
    my $self = shift;
    
    my $pathInfo = {
        config => '/etc/gdm/gdm.conf',
        paths => [
            '/var/lib/gdm',
            '/var/log/gdm',
        ],
    };

    return $pathInfo;
}

sub setupGDMScript
{
    my $self     = shift;
    my $repoPath = shift;

    my $pathInfo   = $self->GDMPathInfo();
    my $configFile = $pathInfo->{config};
    
    my $paths 
        = join(
            ' ', 
            map  { '/mnt' . $_ } ( dirname($configFile), @{$pathInfo->{paths}} )
        );
    my $script = unshiftHereDoc(<<"    End-of-Here");
        # written by OpenSLX-plugin 'desktop'
        
        for i in $paths; do
          testmkd \$i
        done

        cp /mnt$repoPath/gdm/\$desktop_mode/gdm.conf /mnt$configFile

        # activate theme only if the corresponding xml file is found
        # (otherwise fall back to default theme of vendor-OS)
        if [ -n "\$desktop_theme" ]; then
          thdir=/opt/openslx/plugin-repo/desktop/themes/gdm
          theme=\$desktop_theme
          if [ -e /mnt\$thdir/\$theme/*.xml ]; then
            sed -i "s,\\[greeter\\],[greeter]\\nGraphicalThemeDir=\$thdir," \\
              /mnt$configFile
            sed -i "s,\\[greeter\\],[greeter]\\nGraphicalTheme=\$theme," \\
              /mnt$configFile
          fi
        fi
        case "\${desktop_allowshutdown}" in
          none)
          ;;
          root)
            sed "s|AllowShutdown.*|AllowShutdown=true|;\\
                 s|SecureShutdown.*|SecureShutdown=true|" \\
              -i /mnt$configFile
          ;;
          users)
            sed "s|AllowShutdown.*|AllowShutdown=true|;\\
                 s|SecureShutdown.*|SecureShutdown=false|" \\
              -i /mnt$configFile
          ;;
        esac
        [ "\${desktop_rootlogin}" -ne 0 ] && \\
          sed "s|AllowRoot.*|AllowRoot=true|" -i /mnt$configFile
    End-of-Here
    
    return $script;
}

sub GDMConfigHashForWorkstation
{
    my $self = shift;
    
    return {
        'chooser' => {
        },
        'daemon' => {
            AutomaticLoginEnable => 'false',
            Group => 'gdm',
            User => 'gdm',
            DefaultSession => 'default.desktop',
        },
        'debug' => {
            Enable => 'false',
        },
        'greeter' => {
            AllowShutdown => 'false',
            Browser => 'false',
            MinimalUID => '500',
            SecureShutdown => 'false',
            ShowDomain => 'false',
            DefaultWelcome => 'false',
            Welcome => 'OpenSLX Workstation (%n)',
        },
        'gui' => {
        },
        'security' => {
            AllowRoot => 'false',
            AllowRemoteRoot => 'false',
            DisallowTCP => 'true',
            SupportAutomount => 'true',
        },
        'server' => {
        },
        'xdmcp' => {
            Enable => 'false',
        },
    };
}

sub GDMConfigHashForKiosk
{
    my $self = shift;
    
    my $configHash = $self->GDMConfigHashForWorkstation();
    $configHash->{daemon}->{AutomaticLoginEnable} = 'true';
    $configHash->{daemon}->{AutomaticLogin} = 'nobody';

    return $configHash;
}

sub GDMConfigHashForChooser
{
    my $self = shift;
    
    my $configHash = $self->GDMConfigHashForWorkstation();
    $configHash->{xdmcp}->{Enable} = 'true';

    return $configHash;
}

sub isKDEInstalled
{
    my $self = shift;
    
    return isInPath('startkde');
}

sub installKDE
{
    my $self = shift;

    $self->{engine}->installPackages(
        $self->{engine}->getInstallablePackagesForSelection('kde')
    );

    return 1;
}

sub isKDMInstalled
{
    my $self = shift;

    return isInPath('kdm');
}

sub installKDM
{
    my $self = shift;

    $self->{engine}->installPackages('kdm');

    return 1;
}

sub KDMPathInfo
{
    my $self = shift;
    
    my $pathInfo = {
        config => '/etc/opt/kdm/kdmrc',
        paths => [
            '/var/lib/kdm',
        ],
    };

    return $pathInfo;
}

sub setupKDMScript
{
    my $self     = shift;
    my $repoPath = shift;

    my $pathInfo   = $self->KDMPathInfo();
    my $configFile = $pathInfo->{config};
    
    my $paths 
        = join(
            ' ', 
            map  { '/mnt' . $_ } ( dirname($configFile), @{$pathInfo->{paths}} )
        );
    my $script = unshiftHereDoc(<<"    End-of-Here");
        #!/bin/ash
        # written by OpenSLX-plugin 'desktop'

        for i in $paths; do
          testmkd \$i
        done

        cp /mnt$repoPath/kdm/\$desktop_mode/kdmrc /mnt$configFile

        # activate theme only if the corresponding xml file is found
        # (otherwise fall back to default theme of vendor-OS)
        if [ -n "\$desktop_theme" ]; then
          theme=\$desktop_theme
          thdir=/opt/openslx/plugin-repo/desktop/themes/kdm/\$theme
          if [ -e /mnt\$thdir/*.xml ]; then
            sed -i "s,\\[X-\\*-Greeter\\],[X-*-Greeter]\\nTheme=\$thdir," \\
              /mnt$configFile
            sed -i "s,\\[X-\\*-Greeter\\],[X-*-Greeter]\\nUseTheme=true," \\
              /mnt$configFile
          fi
        fi
        case "\${desktop_allowshutdown}" in
          none)
            sed "s|AllowShutdown.*|AllowShutdown=None|" \\
              -i /mnt$configFile
          ;;
          root)
            sed "s|AllowShutdown.*|AllowShutdown=Root|" \\
              -i /mnt$configFile
          ;;
          users)
            sed "s|AllowShutdown.*|AllowShutdown=All|" \\
              -i /mnt$configFile
          ;;
        esac
        [ "\${desktop_rootlogin}" -ne 0 ] && \\
          sed "s|AllowRootLogin.*|AllowRootLogin=true|" -i /mnt$configFile
    End-of-Here
    
    return $script;
}

sub KDMConfigHashForWorkstation
{
    my $self = shift;
    
    return {
#        'General' => {
#            StaticServers => ':0',
#            ReserveServers => ':1,:2,:3',
#            ServerVTs => '-7',
#            ConsoleTTYs => 'tty1,tty2,tty3,tty4,tty5,tty6',
#        },
        'X-:0-Core' => {
            AutoLoginEnable => 'false',
            AllowRootLogin => 'false',
            AllowShutdown => 'All',
        },
        'X-*-Greeter' => {
            GreetString => 'OpenSLX Workstation (%h)',
            SelectedUsers => '',
            UserList => 'false',
        },
        'X-:*-Greeter' => {
            AllowClose => 'false',
            UseAdminSession => 'true',
        },
        'X-:0-Greeter' => {
            LogSource => '/dev/xconsole',
            UseAdminSession => 'false',
            PreselectUser => 'None',
        },
        'xdmcp' => {
            Enable => 'false',
        },
    };
}

sub KDMConfigHashForKiosk
{
    my $self = shift;
    
    my $configHash = $self->KDMConfigHashForWorkstation();
    $configHash->{'X-:0-Core'}->{AutoLoginEnable} = 'true';
    $configHash->{'X-:0-Core'}->{AutoLoginUser} = 'nobody';

    return $configHash;
}

sub KDMConfigHashForChooser
{
    my $self = shift;
    
    my $configHash = $self->KDMConfigHashForWorkstation();
    $configHash->{xdmcp}->{Enable} = 'true';

    return $configHash;
}

sub isXFCEInstalled
{
    my $self = shift;

    return isInPath('startxfce4');
}

sub installXFCE
{
    my $self = shift;

    $self->{engine}->installPackages(
        $self->{engine}->getInstallablePackagesForSelection('xfce')
    );

    return 1;
}

sub isXDMInstalled
{
    my $self = shift;

    return isInPath('xdm');
}

sub installXDM
{
    my $self = shift;

    $self->{engine}->installPackages('xdm');

    return 1;
}

1;
