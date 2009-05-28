# Copyright (c) 2008, 2009 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your suggestions, praise, or complaints to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org/
# -----------------------------------------------------------------------------
# vmware.pm
#    - declares necessary information for the vmware plugin
# -----------------------------------------------------------------------------
package OpenSLX::OSPlugin::vmware;

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
        name => 'vmware',
    };

    return bless $self, $class;
}

sub getInfo
{
    my $self = shift;

    return {
        description => unshiftHereDoc(<<'        End-of-Here'),
           Module for enabling services of VMware Inc. on an OpenSLX stateless
           client. This plugin might use pre-existing installations of VMware
           tools or install addional variants and versions.
        End-of-Here
        precedence => 70,
        required => [ qw( desktop ) ],
    };
}

sub getAttrInfo
{
    # returns a hash-ref with information about all attributes supported
    # by this specific plugin
    my $self = shift;

    # This default configuration will be added as attributes to the default
    # system, such that it can be overruled for any specific system by means
    # of slxconfig.
    return {
        # attribute 'active' is mandatory for all plugins
        'vmware::active' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                should the 'vmware'-plugin be executed during boot?
            End-of-Here
            content_regex => qr{^(0|1)$},
            content_descr => '1 means active - 0 means inactive',
            default => '1',
        },
        # attribute 'imagesrc' defines where we can find vmware images
        'vmware::imagesrc' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                Where do we store our vmware images? NFS? Filesystem?
            End-of-Here
            #TODO: check if the input is valid
            #content_regex => qr{^(0|1)$},
            content_descr => 'Allowed values: path or URI',
            default => '',
        },
        # attribute 'bridge' defines if bridged network mode should be
        # switched on
        'vmware::bridge' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                Should the bridging (direct access of the vmware clients
                to the ethernet the host is connected to) be enabled
            End-of-Here
            content_regex => qr{^(0|1)$},
            content_descr => 'Allowed values: 0 or 1',
            default => '1',
        },
        # attribute 'vmnet1' defines if the host connection network mode 
        # should be switched on and NAT should be enabled
        'vmware::vmnet1' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                Format ServerIP/Netprefix without NAT
                Format ServerIP/Netprefix,NAT enables NAT/Masquerading
            End-of-Here
            #TODO: check if the input is valid
            #content_regex => qr{^(0|1)$},
            content_descr => 'Allowed value: IP/Prefix[,NAT]',
            default => '192.168.101.1/24,NAT',
        },
        # attribute 'vmnet8' defines if vmware specific NATed network mode
        # should be switched on
        'vmware::vmnet8' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                Format ServerIP/Netprefix. Last octet will be omitted
            End-of-Here
            #TODO: check if the input is valid
            #content_regex => qr{^(0|1)$},
            content_descr => 'Allowed value: IP/Prefix. Last octet will be omitted',
            default => '192.168.102.x/24',
        },
        # attribute 'kind' defines which set of VMware binaries should be 
        # activated ('local' provided with the main installation set).
        'vmware::kind' => {
            applies_to_vendor_os => 0,
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                Which set of VMware binaries to use: installed (local) or provided by the
                plugin itself (vmpl1.0, vmpl2.0, vmpl2.5)?
            End-of-Here
            # only allow the supported once...
            # TODO: modify if we know which of them work
            #content_regex => qr{^(local|vmws(5\.5|6.0)|vmpl(1\.0|2\.0))$},
            content_regex => qr{^(local|vmpl2\.0|vmpl1\.0|vmpl2\.5)$},
            content_descr => 'Allowed values: local, vmpl2.0',
            #TODO: what if we don't have a local installation. default
            #      is still local. Someone has a clue how to test
            #      it and change the default value?
            default => 'local',
        },
        ##
        ## only stage1 setup options: different kinds to setup
        'vmware::local' => {
            applies_to_vendor_os => 1,
            applies_to_system => 0,
            applies_to_clients => 0,
            description => unshiftHereDoc(<<'            End-of-Here'),
                Set's up stage1 configuration for a local installed
                vmplayer or vmware workstation
            End-of-Here
            content_regex => qr{^(1|0)$},
            content_descr => '1 means active - 0 means inactive',
            default => '1',
        },
        'vmware::vmpl2.0' => {
            applies_to_vendor_os => 1,
            applies_to_system => 0,
            applies_to_clients => 0,
            description => unshiftHereDoc(<<'            End-of-Here'),
                Install and configure vmplayer v2
            End-of-Here
            content_regex => qr{^(1|0)$},
            content_descr => '1 means active - 0 means inactive',
            default => '0',
        },
        'vmware::vmpl2.5' => {
            applies_to_vendor_os => 1,
            applies_to_system => 0,
            applies_to_clients => 0,
            description => unshiftHereDoc(<<'            End-of-Here'),
                Install and configure vmplayer v2
            End-of-Here
            content_regex => qr{^(1|0)$},
            content_descr => '1 means active - 0 means inactive',
            default => '0',
        },
        'vmware::vmpl1.0' => {
            applies_to_vendor_os => 1,
            applies_to_system => 0,
            applies_to_clients => 0,
            description => unshiftHereDoc(<<'            End-of-Here'),
                Install and configure vmplayer v1
            End-of-Here
            content_regex => qr{^(1|0)$},
            content_descr => '1 means active - 0 means inactive',
            default => '0',
        },
        'vmware::pkgpath' => {
            applies_to_vendor_os => 1,
            applies_to_system => 0,
            applies_to_clients => 0,
            description => unshiftHereDoc(<<'            End-of-Here'),
                Path to VMware packages
            End-of-Here
            #TODO
            #content_regex => qr{^(1|0)$},
            content_descr => '1 means active - 0 means inactive',
            default => '/root/vmware-pkgs',
        },
        # ** set of attributes for the installation of VM Workstation/Player
        # versions. More than one package could be installed in parallel.
        # To be matched to/triggerd by 'vmware::kind'
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
    
    my $pkgpath = $self->{attrs}->{'vmware::pkgpath'};
    my $vmpl10 = $self->{attrs}->{'vmware::vmpl1.0'};
    my $vmpl20 = $self->{attrs}->{'vmware::vmpl2.0'};
    my $vmpl25 = $self->{attrs}->{'vmware::vmpl2.5'};
    my $local = $self->{attrs}->{'vmware::local'};

    if ($local == 0 && $vmpl10 == 0 && $vmpl20 == 0 && $vmpl25 == 0) {
        print "\n\n * At least one kind needs to get installed/activated:\n";
        print "     vmware::local=1  or\n";
        print "     vmware::vmpl1.0=1  or\n";
        print "     vmware::vmpl2.0=1\n";
        print "     vmware::vmpl2.5=1\n";
        print " * vmware plugin was not installed!\n\n";
        exit 1;
    }

    if (! -d $pkgpath && ($vmpl10 == 1 || $vmpl20 == 1 || $vmpl25 == 1)) {
        print "\n\n * vmware::pkgpath: no such directory $pkgpath!\n";
        print "   See wiki about vmware Plugin\n";
        print " * vmware plugin was not installed!\n\n";
        exit 1;
    }

    # test just for the case we only set up local vmware
    if (-d $pkgpath && ($vmpl10 == 1 || $vmpl20 == 1 || $vmpl25 == 1)) {
        # todo: ask oliver about a similiar function
        #       like copyFile() just for directorys
        #       or fix the manual after checked the source of
        #       copyFile() function. check if copyFile etc. perldoc
        #       is somewhere in the wiki documented else do it!
        system("cp -r $pkgpath $self->{pluginRepositoryPath}/packages");
    }
}


sub installationPhase
{
    my $self = shift;
    my $info = shift;
    
    $self->{pluginRepositoryPath} = $info->{'plugin-repo-path'};
    $self->{pluginTempPath}       = $info->{'plugin-temp-path'};
    $self->{openslxBasePath}      = $info->{'openslx-base-path'};
    $self->{openslxConfigPath}    = $info->{'openslx-config-path'};
    $self->{attrs}                = $info->{'plugin-attrs'};
    
    # copy common part of run-virt.include to the appropriate place for
    # inclusion in stage4
    copyFile("$self->{openslxBasePath}/lib/plugins/vmware/files/run-virt.include",
        "$self->{pluginRepositoryPath}/");        

    # kinds we will configure and install
    # TODO: write a list of installed/setted up and check it in stage3
    #       this will avoid conflict of configured vmware version in
    #       stage3 which are not setted up or installed in stage1
    if ($self->{attrs}->{'vmware::local'} == 1) {
        $self->_localInstallation();
    }
    if ($self->{attrs}->{'vmware::vmpl2.0'} == 1) {
        $self->_vmpl2Installation();
    }
    if ($self->{attrs}->{'vmware::vmpl1.0'} == 1) {
        $self->_vmpl1Installation();
    }
    if ($self->{attrs}->{'vmware::vmpl2.5'} == 1) {
        $self->_vmpl25Installation();
    }
        
    ## prepration for our faster wrapper script
    # rename the default vmplayer script and create a link. 
    # uninstall routine takes care about plugin remove.
    # stage3 copys our own wrapper script
    if (-e "/usr/bin/vmplayer" && ! -e "/usr/bin/vmplayer.slx-back") {
        rename("/usr/bin/vmplayer", "/usr/bin/vmplayer.slx-bak");
        linkFile("/var/X11R6/bin/vmplayer", "/usr/bin/vmplayer");
    }
    # the same with vmware, if ws is installed
    if (-e "/usr/bin/vmware" && ! -e "/usr/bin/vmware.slx-bak") {
        linkFile("/var/X11R6/bin/vmware", "/usr/bin/vmware");
        rename("/usr/bin/vmware", "/usr/bin/vmware.slx-bak");
    }
}

sub removalPhase
{
    my $self = shift;
    my $info = shift;

    # restore old start scripts - to be discussed
    my @files = qw( vmware vmplayer );
    foreach my $file (@files) {
        if (-e "/usr/bin/$file.slx-bak") {
            unlink("/usr/bin/$file");
            rename("/usr/bin/$file.slx-bak", "/usr/bin/$file");
        }
    }
    return;
}

sub checkStage3AttrValues
{
    my $self          = shift;
    my $stage3Attrs   = shift;
    my $vendorOSAttrs = shift;
    my @problems;

    my $vm_kind = $stage3Attrs->{'vmware::kind'} || '';
    
    
    my $vmimg = $stage3Attrs->{'vmware::imagesrc'} || '';

    if ($vm_kind eq 'local' && ! -x "/usr/lib/vmware/bin/vmplayer") {
        push @problems, _tr(
            "No local executeable installation of vmware found! Using it as virtual machine wouldn't work!"
        );
    }

    if ($vm_kind eq 'local' &&
        ! -d "/opt/openslx/plugin-repo/vmware/local") {
        push @problems, _tr(
            "local vmware installation not configured by slxos-plugin!"
        );
    }

    if ($vm_kind eq 'vmpl2.0' &&
        ! -d "/opt/openslx/plugin-repo/vmware/vmpl2.0/vmroot") {
        push @problems, _tr(
            "No OpenSLX installation of VMware Player 2.0 found or installation failed. Using it as virtual machine wouldn't work!"
        );
    }
    
    if ($vm_kind eq 'vmpl2.5' &&
        ! -d "/opt/openslx/plugin-repo/vmware/vmpl2.5/vmroot") {
        push @problems, _tr(
            "No OpenSLX installation of VMware Player 2.5 found or installation failed. Using it as virtual machine wouldn't work!"
        );
    }

    if ($vm_kind eq 'vmpl1.0' &&
        ! -d "/opt/openslx/plugin-repo/vmware/vmpl1.0/vmroot") {
        push @problems, _tr(
            "No OpenSLX installation of VMware Player 1 found or installation failed. Using it as virtual machine wouldn't work!"
        );
    }

    return if !@problems;

    return \@problems;
}


#######################################
## local, non-general OpenSLX functions
#######################################

# write the runlevelscript depending on the version
sub _writeRunlevelScript
{
    my $self     = shift;
    my $location = shift;
    my $file     = shift;
    my $kind     = shift;
    
    # $location points to the path where vmware helpers are installed
    # call the distrospecific fillup
    my $runlevelScript = $self->{distro}->fillRunlevelScript($location, $kind);

    spitFile($file, $runlevelScript);
}


# writes the wrapper script for vmware workstation and player, depending
# on the flag. If player: just player wrapper, if ws: ws+player wrapper
# usage: _writeWrapperScript("$vmpath", "$kind", "player")
#        _writeWrapperScript("$vmpath", "$kind", "ws")
sub _writeWrapperScript
{
    my $self   = shift;
    my $vmpath = shift;
    my $kind   = shift;
    my $type   = shift;
    my @files;

    if ("$type" eq "ws") {
        @files = qw(vmware vmplayer);
    } else {
        @files = qw(vmplayer);
    }

    foreach my $file (@files) {
        # create our own simplified version of the vmware and player wrapper
        # Depending on the configured kind it will be copied in stage3
        # because of tempfs of /var but not /usr we link the file
        # to /var/..., where we can write in stage3
        my $script = unshiftHereDoc(<<"        End-of-Here");
            #!/bin/sh
            # written by OpenSLX-plugin 'vmware' in Stage1
            # radically simplified version of the original script $file by VMware Inc.
        End-of-Here

        # kinda ugly and we only need it for local. Preserves errors
        if ($kind ne "local") {
            $script .= unshiftHereDoc(<<"            End-of-Here");
                export LD_LIBRARY_PATH=$vmpath/lib
                export GDK_PIXBUF_MODULE_FILE=$vmpath/libconf/etc/gtk-2.0/gdk-pixbuf.loaders
                export GTK_IM_MODULE_FILE=$vmpath/libconf/etc/gtk-2.0/gtk.immodules
                export FONTCONFIG_PATH=$vmpath/libconf/etc/fonts
                export PANGO_RC_FILE=$vmpath/libconf/etc/pango/pangorc
                # possible needed... but what are they good for?
                #export GTK_DATA_PREFIX=
                #export GTK_EXE_PREFIX=
                #export GTK_PATH=
            End-of-Here
        }

        $script .= unshiftHereDoc(<<"        End-of-Here");
            PREFIX=$vmpath # depends on the vmware location
            exec "\$PREFIX"'/lib/wrapper-gtk24.sh' \\
                 "\$PREFIX"'/lib' \\
                 "\$PREFIX"'/bin/$file' \\
                 "\$PREFIX"'/libconf' "\$@"
        End-of-Here

        # TODO: check if these will be overwritten if we have more as
        # local defined (add the version/type like vmpl1.0, vmws5.5, ...)
        # then we have a lot of files easily distinguishable by there suffix
        spitFile("$self->{'pluginRepositoryPath'}/$kind/$file", $script);
        chmod 0755, "$self->{'pluginRepositoryPath'}/$kind/$file";
    }
}

sub _writeVmwareConfigs {
    my $self   = shift;
    my $kind   = shift;
    my $vmpath = shift;
    my %versionhash = (vmversion => "", vmbuildversion => "");
    my $vmversion = "";
    my $vmbuildversion = "";
    my $config = "";

    %versionhash = _getVersion($vmpath);

    $config .= "version=\"".$versionhash{vmversion}."\"\n";
    $config .= "buildversion=\"".$versionhash{vmbuildversion}."\"\n";
    spitFile("$self->{'pluginRepositoryPath'}/$kind/slxvmconfig", $config);
    chmod 0755, "$self->{'pluginRepositoryPath'}/$kind/slxvmconfig";

    $config = "libdir = \"$vmpath\"\n";
    spitFile("$self->{'pluginRepositoryPath'}/$kind/config", $config);
    chmod 0755, "$self->{'pluginRepositoryPath'}/$kind/config";
}

sub _getVersion {

    my $vmpath       = shift;
    my $vmversion = "";
    my $vmbuildversion = "";
    my %versioninfo = (vmversion => "", vmbuildversion => "");

    # get version information about installed vmplayer
    if (open(FH, "$vmpath/bin/vmplayer")) {
        $/ = undef;
        my $data = <FH>;
        close FH;
        # depending on the installation it could differ and has multiple build
        # strings
        if ($data =~ m{[^\d\.](\d\.\d) build-(\d+)}) {
            $vmversion = $1;
            $vmbuildversion = $2;
        }
        if ($data =~ m{\0(2\.[05])\.[0-9]}) {
            $vmversion = $1;
        }
        # else { TODO: errorhandling if file or string doesn't exist }
        chomp($vmversion);
        chomp($vmbuildversion);

        $versioninfo{vmversion} = $vmversion;
        $versioninfo{vmbuildversion} = $vmbuildversion;
     }
     return %versioninfo;
}

########################################################################
## Functions, which setup the different environments (local, ws-v(5.5|6),
##                                                    player-v(1|2)
## Seperation makes this file more readable. Has a bigger benefit as
## one big copy function. Makes integration of new versions easier.
########################################################################

# local installation
sub _localInstallation
{
    my $self     = shift;

    my $kind   = "local";
    my $vmpath = "/usr/lib/vmware";
    my $vmbin  = "/usr/bin";
    my %versionhash = (vmversion => "", vmbuildversion => "");
    my $vmversion = "";
    my $vmbuildversion = "";

    my $pluginFilesPath 
        = "$self->{'openslxBasePath'}/lib/plugins/$self->{'name'}/files";
    my $installationPath = "$self->{'pluginRepositoryPath'}/$kind";

    mkpath($installationPath);

    # if vmware ws is installed, vmplayer is installed, too.
    # we will only use vmplayer
    if (-e "/usr/lib/vmware/bin/vmplayer") {

        ## Get and write version information
        %versionhash = _getVersion($vmpath);
        $vmversion = $versionhash{vmversion};
        $vmbuildversion = $versionhash{vmbuildversion};

        ## Copy needed files
        my @files = qw(nvram.5.0);
        foreach my $file (@files) {
            copyFile("$pluginFilesPath/$file", "$installationPath");
        }

        # Create runlevel script -> to be fixed!!
        my $runlevelScript = "$self->{'pluginRepositoryPath'}/$kind/vmware.init";
        if ($vmversion eq "2.5") {
            $self->_writeRunlevelScript($vmbin, $runlevelScript, "local25");
        } else {
            $self->_writeRunlevelScript($vmbin, $runlevelScript, $kind);
        }

        # Create wrapper scripts
        if (-e "/usr/bin/vmware") {
            $self->_writeWrapperScript("$vmpath", "$kind", "ws")
        } else {
            $self->_writeWrapperScript("$vmpath", "$kind", "player")
        }
        
    }
    # else { TODO: errorhandling }
    
    ## Creating needed config /etc/vmware/config
    $self->_writeVmwareConfigs("$kind", "$vmpath");
}


sub _vmpl2Installation {
    my $self     = shift;

    my $kind   = "vmpl2.0";
    my $vmpath = "/opt/openslx/plugin-repo/vmware/$kind/vmroot/lib/vmware";
    my $vmbin  = "/opt/openslx/plugin-repo/vmware/$kind/vmroot/bin";

    my $pluginFilesPath 
        = "$self->{'openslxBasePath'}/lib/plugins/$self->{'name'}/files";
    my $installationPath = "$self->{'pluginRepositoryPath'}/$kind";

    mkpath($installationPath);

    ##
    ## Copy needed files

    # copy 'normal' needed files
    my @files = qw( nvram.5.0 install-vmpl.sh );
    foreach my $file (@files) {
        copyFile("$pluginFilesPath/$file", "$installationPath");
    }

    # copy on depending runvmware file
    copyFile("$pluginFilesPath/runvmware-player-v2", "$installationPath", "runvmware");

    # Install the binarys from given pkgpath
    system("/bin/sh /opt/openslx/plugin-repo/$self->{'name'}/$kind/install-vmpl.sh $kind");

    # Create runlevel script
    my $runlevelScript = "$self->{'pluginRepositoryPath'}/$kind/vmware.init";
    $self->_writeRunlevelScript($vmbin, $runlevelScript, $kind);

    # Create wrapperscripts
    $self->_writeWrapperScript("$vmpath", "$kind", "player");

    # Creating needed config /etc/vmware/config
    $self->_writeVmwareConfigs("$kind", "$vmpath");
        
}

sub _vmpl25Installation {
    my $self     = shift;

    my $kind   = "vmpl2.5";
    my $vmpath = "/opt/openslx/plugin-repo/vmware/$kind/vmroot/lib/vmware";
    my $vmbin  = "/opt/openslx/plugin-repo/vmware/$kind/vmroot/bin";
    my $vmversion = "6.5";
    my $vmbuildversion = "TODO_we_need_it_for_enhanced_runvmware_config_in_stage1";

    my $pluginFilesPath 
        = "$self->{'openslxBasePath'}/lib/plugins/$self->{'name'}/files";
    my $installationPath = "$self->{'pluginRepositoryPath'}/$kind";

    mkpath($installationPath);

    # copy 'normal' needed files
    my @files = qw( nvram.5.0 install-vmpl.sh );
    foreach my $file (@files) {
        copyFile("$pluginFilesPath/$file", "$installationPath");
    }

    # copy on depending runvmware file
    copyFile("$pluginFilesPath/runvmware-player-v25", "$installationPath", "runvmware");

    # Install the binarys from given pkgpath
    system("/bin/sh /opt/openslx/plugin-repo/$self->{'name'}/$kind/install-vmpl.sh $kind");

    # Create runlevel script
    my $runlevelScript = "$self->{'pluginRepositoryPath'}/$kind/vmware.init";
    $self->_writeRunlevelScript($vmbin, $runlevelScript, $kind);

    # Create wrapperscripts
    $self->_writeWrapperScript("$vmpath", "$kind", "player");

    # Creating needed config /etc/vmware/config
    $self->_writeVmwareConfigs("$kind", "$vmpath");
        
}

sub _vmpl1Installation {
    my $self     = shift;

    my $kind   = "vmpl1.0";
    my $vmpath = "/opt/openslx/plugin-repo/vmware/$kind/vmroot/lib/vmware";
    my $vmbin  = "/opt/openslx/plugin-repo/vmware/$kind/vmroot/bin";
    my $vmversion = "5.5";
    my $vmbuildversion = "TODO_we_need_it_for_enhanced_runvmware_config_in_stage1";

    my $pluginFilesPath 
        = "$self->{'openslxBasePath'}/lib/plugins/$self->{'name'}/files";
    my $installationPath = "$self->{'pluginRepositoryPath'}/$kind";

    mkpath($installationPath);

    # copy 'normal' needed files
    my @files = qw( nvram.5.0 install-vmpl.sh );
    foreach my $file (@files) {
        copyFile("$pluginFilesPath/$file", "$installationPath");
    }
    # copy on depending runvmware file
    copyFile("$pluginFilesPath/runvmware-player-v1", "$installationPath", "runvmware");

    # Download and install the binarys
    system("/bin/sh /opt/openslx/plugin-repo/$self->{'name'}/$kind/install-vmpl.sh $kind");

    # Create runlevel script
    my $runlevelScript = "$self->{'pluginRepositoryPath'}/$kind/vmware.init";
    $self->_writeRunlevelScript($vmbin, $runlevelScript, $kind);

    # create wrapper scripts
    $self->_writeWrapperScript("$vmpath", "$kind", "player");

    # creating needed config /etc/vmware/config
    $self->_writeVmwareConfigs("$kind", "$vmpath");
        
}

# The bridge configuration needs the bridge module to be present in early
# stage3
sub suggestAdditionalKernelModules
{
    my $self                = shift;
    my $makeInitRamFSEngine = shift;

    my @suggestedModules;

    push @suggestedModules, qw( bridge );

    return @suggestedModules;
}

1;
