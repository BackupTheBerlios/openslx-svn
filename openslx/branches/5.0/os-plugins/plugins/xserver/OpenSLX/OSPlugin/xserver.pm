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

use File::Basename;

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
        This plugin tries to configure the local Xorg-Server and 
	integrates binary graphics drivers (closed sourced) into the system.
        Notice that you need to have kernel-headers installed to work properly.
        in some cases. You need to download the driver packages yourself and 
        supply the download folder into the pkgpath option.
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
            applies_to_clients => 1,
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
        # Currently not needed in scenarios where distro specific packages are
        # available
        'xserver::pkgpath' => {
            applies_to_vendor_os => 0,
            applies_to_vendor_os => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                Path to downloaded ATI or Nvidia package
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

    #if (! -d $pkgpath && ($installAti == 1 || $installNvidia == 1)) {
    #    print "\n\n * xserver::pkgpath: no such directory!\n";
    #    print " * xserver plugin can't install ATI or Nvidia driver!\n\n";
    #    # exit 1 => xserver plugin is not getting installed because ati
    #    # or nvidia where selected but are not installable!
    #    exit 1;
    #}

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
    my $vendorOSName = $self->{'os-plugin-engine'}->{'vendor-os-name'};

    # write the distro specific extension (inclusion) of XX_xserver.sh
    my $script = $self->{distro}->setupXserverScript($pluginRepoPath);
    spitFile("$pluginRepoPath/xserver.sh", $script);

    # if defined: build nvidia or ati binarys
    my $pluginFilesPath =
        "$openslxBasePath/lib/plugins/$self->{'name'}/files";
    my $installationPath = "$pluginRepoPath/";
    my $binDrivers = 0;

    # TODO: handle it better. We know the distribution in stage1
    if ($attrs->{'xserver::nvidia'} == 1  || $attrs->{'xserver::ati'} == 1 ) {
        copyFile("$pluginFilesPath/ubuntu-gfx-install.sh", "$installationPath");
        copyFile("$pluginFilesPath/suse-gfx-install.sh", "$installationPath");
        copyFile("$pluginFilesPath/ubuntu-8.10-gfx-install.sh", "$installationPath");
        #copyFile("$pluginFilesPath/linkage.sh", "$installationPath");
        # be on the safe side (BASH) - Ubuntu sets some crazy stupid 'dash' shell otherwise
        #system("/bin/bash /opt/openslx/plugin-repo/$self->{'name'}/linkage.sh clean");

        # removeLinks is to remove Links to the files
        # otherwise some wrong files are created
        $self->removeLinks();
        $binDrivers = 1;
    }
    if ($attrs->{'xserver::ati'} == 1) {
        copyFile("$pluginFilesPath/ati-install.sh", "$installationPath");
        system("/bin/bash /opt/openslx/plugin-repo/$self->{'name'}/ati-install.sh");
        #system("/bin/bash /opt/openslx/plugin-repo/$self->{'name'}/linkage.sh ati");
    }
    if ($attrs->{'xserver::nvidia'} == 1) {
        copyFile("$pluginFilesPath/nvidia-install.sh", "$installationPath");
        system("/bin/bash /opt/openslx/plugin-repo/$self->{'name'}/nvidia-install.sh $vendorOSName");
        #system("/bin/bash /opt/openslx/plugin-repo/$self->{'name'}/linkage.sh nvidia");
    }

    if ($binDrivers == 1) {
        $self->linkLibs($info);
        `chmod -R 755 $installationPath`
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

    
    $self->removeLinks();

    return;
}


sub linkLibs
{
    my $self = shift;
    my $info = shift;

    my $pluginRepoPath = $info->{'plugin-repo-path'};
    my $divertFolder = "/var/X11R6/lib/";
    my $attrs = $info->{'plugin-attrs'};

    my @libList;
    unless( $attrs->{'xserver::nvidia'} == 1 ||
            $attrs->{'xserver::ati'} == 1    )
    {
       return;
    }

    my $command;
    if( $attrs->{'xserver::nvidia'} == 1 ) {
        $command = "find $pluginRepoPath\/nvidia ".
                   "-wholename \"*/xorg/modules\" -prune ".
                   "-a '!' -type d -o -name '*so*'";
        @libList = `$command`;
    }
    if( $attrs->{'xserver::ati'} == 1 ) {
        $command = "find $pluginRepoPath/ati -wholename ".
                    "\"*/xorg/modules\" -prune ".
                    "-a '!' -type d -o -name '*so*'";
        push @libList, `$command` ;
    }
    
    my $libname= '';
    my $divname= '';
    my $oldlib = '';
    my $dirname = '';
    for my $lib (@libList) {
        chomp($lib);
        if($lib =~ /.*(\/usr\/.*?lib\/.*?)$/) {
            # oldlib is the MESA lib
            $oldlib = $1;
            $dirname = dirname($oldlib);
            if( -e $oldlib ) {
                $oldlib =~ /\/usr\/.*?lib\/(.*)/;
                # libname is the Name of MESA lib
                $libname = $1;

                # we have to move the original (MESA) file
                # and symlink to a diversion folder
                $divname = $libname;

                $divname =~ s/\.so/_MESA.so/;
                
                # move only if both are real files !!
                if( -f $oldlib && ! -l $oldlib && ! -l $lib )
                {
                    rename($oldlib, $dirname."/".$divname);
                    symlink($divertFolder.$libname, $oldlib);
                    #print "DEBUG: symlink 1 $divertFolder.$libname, $oldlib\n";
                } 
                elsif( -l $oldlib && -l $lib ) 
                {
                    my $tmp1 = readlink $oldlib;
                    my $tmp2 = readlink $lib;
                    if( $tmp1 ne $tmp2 )
                    { 
                        # here the links are pointing to different files -
                        # as in libGLcore.so.1 in nvidia drivers
                        unlink($oldlib);
                        symlink($divertFolder.$libname, $oldlib);
                    }
                }
            }
            else {
                # this file does not exist
                # check for not existing folders
                unless( -d $dirname ) {
                   `mkdir -p $dirname`;
                }
                # just link
                symlink( $lib,  $oldlib );
                #print "DEBUG: symlink 2 $lib, $oldlib\n";
            }
        }
    }

}


sub removeLinks
{
    my $instFolders = "/usr/lib /usr/X11R6/lib";
    my $divertFolder = "/var/X11R6/lib";
    my $pluginFolder = "/opt/openslx/plugin-repo/xserver";

    # get all previously installed links
    my @linkedFiles = 
        `find $instFolders -lname "$divertFolder*" -o -lname "$pluginFolder*" `;


    # also remove _MESA backup files
    my @backupFiles =
        `find $instFolders -name "*_MESA.so*"`;
    my $origfile = '';
    for my $file (@backupFiles) {
        $origfile = $file;
        $file =~ s/_MESA//;
        rename($origfile,$file);
    }
    unlink "/usr/lib/libGL.so", "/usr/lib/libGL.so.1";
    symlink "/usr/lib/libGL.so.1.2", "/usr/lib/libGL.so.1";
    symlink "/usr/lib/libGL.so.1.2", "/usr/lib/libGL.so";

    my $number = unlink @linkedFiles;
    return;
}

1;
