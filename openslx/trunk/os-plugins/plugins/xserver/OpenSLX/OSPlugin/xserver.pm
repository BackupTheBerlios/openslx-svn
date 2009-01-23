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
# xserver.pm
# -----------------------------------------------------------------------------
package OpenSLX::OSPlugin::xserver;

use strict;
use warnings;

use base qw(OpenSLX::OSPlugin::Base);

use OpenSLX::Basics;
use OpenSLX::Utils;

################################################################################
# if you have any questions regarding the concept of OS-plugins and their
# implementation, please drop a mail to: ot@openslx.com, or join the IRC-channel
# '#openslx' (on freenode).
################################################################################
sub new
{
    my $class = shift;

    my $self = {
        name => 'xserver',
    };

    return bless $self, $class;
}

sub getInfo
{
    my $self = shift;

    return {
        description => unshiftHereDoc(<<'        End-of-Here'),
        This plugin tries to integrate binary graphics drivers into the system.
        Notice that you need to have kernel-headers installed to work properly.
        End-of-Here
        precedence => 80,
    };
}

sub getAttrInfo
{   # returns a hash-ref with information about all attributes supported
    # by this specific plugin
    my $self = shift;

    # This default configuration will be added as attributes to the default
    # system, such that it can be overruled for any specific system by means
    # of slxconfig.
    return {
        # attribute 'active' is mandatory for all plugins
        'xserver::active' => {
            applies_to_systems => 1,
            applies_to_clients => 0,
            description => unshiftHereDoc(<<'            End-of-Here'),
            should the 'xserver'-plugin be executed during boot?
            End-of-Here
            content_regex => qr{^(0|1)$},
            content_descr => '1 means active - 0 means inactive',
            default => '1',
        },
        'xserver::ddcinfo' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
            should the 'xserver'-plugin use the ddcinfo (if available) for
            the monitor/tft setup? Might help in scenarios with resolutions
            configured much lower than physically possible. (0 ignore, 1 use)
            End-of-Here
            content_regex => qr{^(0|1)$},
            content_descr => '0 ignore ddcinfo, 1 use ddcinfo if available',
            default => '0',
        },
        'xserver::prefnongpl' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
            should the 'xserver'-plugin use the non-gpl drivers for some graphic
            adaptors if available (0 prefer gpl, 1 use the nongpl)
            End-of-Here
            content_regex => qr{^(0|1)$},
            content_descr => '0 ignore ddcinfo, 1 use ddcinfo if available',
            default => '0',
        },
        'xserver::usexrandr' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
            should the 'xserver'-plugin use the "xrandr" extension of Xorg to
            make use of multi-head scenarios and dynamically added displays
            (not implemented yet)
            End-of-Here
            content_regex => qr{^(0|1)$},
            content_descr => '1 xrandr extension, 0 switch off',
            default => '1',
        },

        # plugin specific attributes start here ...

        # stage1
        'xserver::pkgpath' => {
            applies_to_vendor_os => 0,
            applies_to_vendor_os => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                Path to ATI or Nvidia package
            End-of-Here
            # TODO:
            #content_regex => qr{^0|1$},
            content_descr => 'Path to Nvidia or ATI packages',
            default => '/root/xserver-pkgs',
        },
        'xserver::ati' => {
            applies_to_vendor_os => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                should the non-gpl ATI drivers be available (installed in  vendor-OS - not implemented yet)?
            End-of-Here
            content_regex => qr{^0|1$},
            content_descr => '"0", "1"',
            default => '0',
        },
        'xserver::nvidia' => {
            applies_to_vendor_os => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                should the non-gpl NVidia drivers be available (installed in  vendor-OS - not implemented yet)?
            End-of-Here
            content_regex => qr{^0|1$},
            content_descr => '"0", "1"',
            default => '0',
        },
        #'xserver::matrox' => {
        #    applies_to_vendor_os => 1,
        #    description => unshiftHereDoc(<<'            End-of-Here'),
        #        should the non-gpl Matrox drivers (e.g. for the Parhelia) be 
        #        available (installed in vendor-OS)?
        #    End-of-Here
        #    content_regex => qr{^0|1$},
        #    content_descr => '"0", "1"',
        #    default => '0',
        #},
    };
}


sub preInstallationPhase()
{
    my $self = shift;
    my $info = shift;

    $self->{pluginRepositoryPath} = $info->{'plugin-repo-path'};
    $self->{pluginTempPath}       = $info->{'plugin-temp-path'};
    $self->{openslxBasePath}      = $info->{'openslx-base-path'};
    $self->{openslxConfigPath}    = $info->{'openslx-config-path'};
    $self->{attrs}                = $info->{'plugin-attrs'};
    $self->{vendorOsPath}         = $info->{'vendor-os-path'};
                                        
    my $pkgpath = $self->{attrs}->{'xserver::pkgpath'};
    my $installAti = $self->{attrs}->{'xserver::ati'};
    my $installNvidia = $self->{attrs}->{'xserver::nvidia'};

    if (! -d $pkgpath && ($installAti == 1 || $installNvidia == 1)) {
        print "\n\n * xserver::pkgpath: no such directory!\n";
        print " * xserver plugin can't install ATI or Nvidia driver!\n\n";
        # exit 1 => xserver plugin is not getting installed because ati
        # or nvidia where selected but are not installable!
        exit 1;
    }

    if (-d $pkgpath && ($installNvidia == 1 || $installAti == 1)) {
        # Todo: use a openslx copy function!
        system("cp -r $pkgpath $self->{pluginRepositoryPath}/packages");
    }
}


sub installationPhase
{   # called while chrooted to the vendor-OS root in order to give the plugin
    # a chance to install required files into the vendor-OS.
    my $self = shift;
    my $info = shift;

    # ehh... every plugin has it's own different installationPhase
    # variable definition?
    my $pluginRepoPath = $info->{'plugin-repo-path'};
        # The folder where the stage1-plugin should store all files
        # required by the corresponding stage3 runlevel script.
        # As this method is being executed while chrooted into the vendor-OS,
        # this path is relative to that root (i.e. directly usable).
    my $pluginTempPath = $info->{'plugin-temp-path'};
        # A temporary playground that will be cleaned up automatically.
        # As this method is being executed while chrooted into the vendor-OS,
        # this path is relative to that root (i.e. directly usable).
    my $openslxBasePath = $info->{'openslx-base-path'};
        # the openslx base path (/opt/openslx) bind-mounted into the chroot
    my $openslxConfigPath = $info->{'openslx-config-path'};
        # the openslx config path (/etc/opt/openlsx) bind-mounted into the 
        # chroot
    my $attrs = $info->{'plugin-attrs'};
        # attributes in effect for this installation

    # write the distro specific extension (inclusion) of XX_xserver.sh
    my $script = $self->{distro}->setupXserverScript($pluginRepoPath);
    spitFile("$pluginRepoPath/xserver.sh", $script);

    # if defined: build nvidia or ati binarys
    my $pluginFilesPath =
        "$openslxBasePath/lib/plugins/$self->{'name'}/files";
    my $installationPath = "$pluginRepoPath/";
    if ($attrs->{'xserver::ati'} == 1) {
        copyFile("$pluginFilesPath/ati-install.sh", "$installationPath");
        #system("/bin/sh /opt/openslx/plugin-repo/$self->{'name'}/ati-install.sh");
    }
    if ($attrs->{'xserver::nvidia'} == 1) {
        copyFile("$pluginFilesPath/nvidia-install.sh", "$installationPath");
        #system("/bin/sh /opt/openslx/plugin-repo/$self->{'name'}/nvidia-install.sh");
    }

    # Some plugins have to copy files from their plugin folder into the
    # vendor-OS. Here's an example for how to do that:
    #
    # # get our own name:
    # my $pluginName = $self->{'name'};
    #
    # # get our own base path:
    # my $pluginBasePath = "$openslxBasePath/lib/plugins/$pluginName";
    #     
    # # copy all needed files now:
    # foreach my $file ( qw( file1, file2 ) ) {
    #     copyFile("$pluginBasePath/$file", "$pluginRepoPath/");
    # }

    # name of current os
    # my $vendorOSName = $self->{'os-plugin-engine'}->{'vendor-os-name'} 

    return;
}

sub removalPhase
{   # called while chrooted to the vendor-OS root in order to give the plugin
    # a chance to uninstall no longer required files from the vendor-OS.
    my $self = shift;
    my $info = shift;
    
    my $pluginRepoPath = $info->{'plugin-repo-path'};
        # The folder where the stage1-plugin should store all files
        # required by the corresponding stage3 runlevel script.
        # As this method is being executed while chrooted into the vendor-OS,
        # this path is relative to that root (i.e. directly usable).
    my $pluginTempPath = $info->{'plugin-temp-path'};
        # A temporary playground that will be cleaned up automatically.
        # As this method is being executed while chrooted into the vendor-OS,
        # this path is relative to that root (i.e. directly usable).

    return;
}

1;
