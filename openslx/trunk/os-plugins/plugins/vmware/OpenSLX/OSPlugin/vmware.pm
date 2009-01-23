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
            !!! descriptive text missing here !!!
        End-of-Here
        precedence => 70,
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
            applies_to_clients => 0,
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
                Format ServerIP/Netprefix
            End-of-Here
            #TODO: check if the input is valid
            #content_regex => qr{^(0|1)$},
            content_descr => 'Allowed value: IP/Prefix',
            default => '192.168.102.1/24',
        },
        # attribute 'kind' defines which set of VMware binaries should be 
        # activated ('local' provided with the main installation set).
        'vmware::kind' => {
            applies_to_vendor_os => 0,
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                Which set of VMware binaries to use: installed (local) or provided by an
                other plugin (e.g. Workstation 5.5: vmws5.5, Player 2.0: vmpl2.0, ...)
            End-of-Here
            # only allow the supported once...
            # TODO: modify if we know which of them work
            #content_regex => qr{^(local|vmws(5\.5|6.0)|vmpl(1\.0|2\.0))$},
            content_regex => qr{^(local|vmpl2\.0)$},
            content_descr => 'Allowed values: local, vmpl2.0',
            default => 'local',
        },
        # ** set of attributes for the installation of VM Workstation/Player
        # versions. More than one package could be installed in parallel.
        # To be matched to/triggerd by 'vmware::kind'
    };
}


sub installationPhase
{
    my $self                      = shift;

    $self->{pluginRepositoryPath} = shift;
    $self->{pluginTempPath}       = shift;
    $self->{openslxPath}          = shift;
    $self->{attrs}                = shift;

    # install requested packages by **/ or triggered by 'vmware::kind'
    # check solution in "desktop plugin"

    # generate the runlevel scripts for all existing vmware installations,
    # variants because we do not know which on is selected on client level
    # in stage3 (we know the installed packages from ** / 'vmware::kind'
    # (code depends on distro/version and vmware location)
    # for local ... and other vm-installations
    # TODO: generate the list from ** / 'vmware::kind' (stage1 attributes)
    #       (do not generate scripts for packages which are not installed)
    my @types = qw( local vmpl2.0 );
    foreach my $type (@types) {
        # location of the vmware stuff
        if ($type eq "local") {
            $self->_localInstallation();
        }
        # TODO: here we will add the slx-installed versions
        elsif ($type eq "vmpl2.0") {
            $self->_vmpl2Installation();
        }
        else {
            #my $vmpath = "$self->{'pluginRepositoryPath'}/vmware/$type";
            #my $vmbin  = "$vmpath/bin";
            #$vmversion = "TODO: get information from the stage1 flag";
            #$vmfile = "TODO: get information from the stage1 flag";
        }



        # TODO: check how we can put the vmversion information to stage3.
        #       more or less only needed for local installation but can
	#       also be used for quickswitch of vmware version in stage4 - 
	#       rather theoretical option for now - who should run the root scripts!?
	#       (if it is requested later on, this feature might be added, but not relevant now)
	#       Perhaps we write all installed player versions in this file
	#       which get sourced by XX_vmware.sh

	#       Conflict without rewrite of this code: local installed
	#           vmware/player or(!) vmplayer
	#       Solution:  substitude  "foreach my $type (@types) {"
	#                  with _checkInstalled(local_vmplayer);
	#                       _checkInstalled(local_vmwarews);
	#                       _checkInstalled(vmplayer1);
	#                       _checkInstalled(vmplayer2);
	#                  and so on
	#                  while _checkInstalled pseudocode
	#               sub _checkInstalled($type, $path) {
	# 			check_for_version(see above)
	#			write information of this version to file
	#		}
	#		=> results in conflict of local, we just have
	#		   local defined but would need then a
	#		   local_ws and local_player which is less userfriendly
	#	Dirk: see .4.2 suse-10.2-(test|main) system which includes
	#		vmplayer or vmware ws/player (vmplayer is every time a part of the
	#		workstation!! since version 5.5!! So if we have workstation, than
	#		we have automatically vmplayer too)

    }

}

sub removalPhase
{
    my $self                 = shift;
    my $pluginRepositoryPath = shift;
    my $pluginTempPath       = shift;
    
    rmtree ( [ $pluginRepositoryPath ] );
    # restore old start scripts - to be discussed
    my @files = qw( vmware vmplayer );
    foreach my $file (@files) {
        if (-e $file) {
            unlink("/usr/bin/$file");
            rename("/usr/bin/$file.slx-bak", "/usr/bin/$file");
        }
    }
    return;
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
    
    # $location points to the path where vmware helpers are installed
    # call the distrospecific fillup
    my $runlevelScript = $self->{distro}->fillRunlevelScript($location);

    # OLTA: this backup strategy is useless if invoked twice, so I have
    #       deactivated it
    # rename($file, "${file}.slx-bak") if -e $file;

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
    my $vmversion = "";
    my $vmbuildversion = "";

    my $pluginFilesPath 
        = "$self->{'openslxPath'}/lib/plugins/$self->{'name'}/files";
    my $installationPath = "$self->{'pluginRepositoryPath'}/$kind";

    mkpath($installationPath);

    # if vmware ws is installed, vmplayer is installed, too.
    # we will only use vmplayer
    if (-e "/usr/lib/vmware/bin/vmplayer") {

        ##
        ## Get and write version informations

        # get version information about installed vmplayer
        open(FH, "/usr/lib/vmware/bin/vmplayer");
        $/ = undef;
        my $data = <FH>;
        close FH;
        # perhaps we need to recheck the following check. depending
        # on the installation it could differ and has multiple build-
        # strings
        if ($data =~ m{(\d\.\d) build-(\d+)}) {
            $vmversion = $1;
            $vmbuildversion = $2;
        }
        # else { TODO: errorhandling if file or string doesn't exist }
        chomp($vmversion);
        chomp($vmbuildversion);

        # write informations about local installed vmplayer in file
        # TODO: perhaps we don't need this file.
        # TODO2: write vmbuildversion and stuff in runvmware in stage1
        open FILE, ">$self->{'pluginRepositoryPath'}/$kind/versioninfo.txt"
            or die $!;
        print FILE "vmversion=\"$vmversion\"\n";
        print FILE "vmbuildversion=\"$vmbuildversion\"\n";
        close FILE;

        ##
        ## Copy needed files

        # copy 'normal' needed files
        my @files = qw( nvram.5.0);
        foreach my $file (@files) {
            copyFile("$pluginFilesPath/$file", "$installationPath");
        }
        # copy depends on version and rename it to runvmware, safes one check in stage3
        if ($vmversion < "6") {
            print "\n\nDEBUG: player version $vmversion, we use -v1\n\n";
            copyFile("$pluginFilesPath/runvmware-player-v1", "$installationPath", "runvmware");
        } else {
            print "\n\nDEBUG: player version $vmversion, we use -v2\n\n";
            copyFile("$pluginFilesPath/runvmware-player-v2", "$installationPath", "runvmware");
        }

        ##
        ## Create runlevel script
        my $runlevelScript = "$self->{'pluginRepositoryPath'}/$kind/vmware.init";
        $self->_writeRunlevelScript($vmbin, $runlevelScript);

        ##
        ## Create wrapperscripts
        if (-e "/usr/bin/vmware") {
            $self->_writeWrapperScript("$vmpath", "$kind", "ws")
        } else {
            $self->_writeWrapperScript("$vmpath", "$kind", "player")
        }
        
        ##
        ## replacement with our, faster wrapper script
        
        # rename the default vmplayer script and copy it. remove function takes
        # care about plugin remove. We only need this part if vmplayer
        # or ws is installed on the local system
        rename("/usr/bin/vmplayer", "/usr/bin/vmplayer.slx-bak");
        copyFile("$self->{'pluginRepositoryPath'}/$kind/vmplayer", "/usr/bin");
        # the same with vmware, if ws is installed
        if (-e "/usr/bin/vmware") {
            rename("/usr/bin/vmware", "/usr/bin/vmware.slx-bak");
            copyFile("$self->{'pluginRepositoryPath'}/$kind/vmware", "/usr/bin");
         }
            
    }
    # else { TODO: errorhandling }
}


sub _vmpl2Installation {
    my $self     = shift;

    my $kind   = "vmpl2.0";
    my $vmpath = "/opt/openslx/plugin-repo/vmware/$kind/root/lib/vmware";
    my $vmbin  = "/opt/openslx/plugin-repo/vmware/$kind/root/bin";
    my $vmversion = "TODO_we_need_it_for_enhanced_runvmware_config_in_stage?";
    my $vmbuildversion = "TODO_we_need_it_for_enhanced_runvmware_config_in_stage1";

    my $pluginFilesPath 
        = "$self->{'openslxPath'}/lib/plugins/$self->{'name'}/files";
    my $installationPath = "$self->{'pluginRepositoryPath'}/$kind";

    mkpath($installationPath);

    ##
    ## Copy needed files

    # copy 'normal' needed files
    my @files = qw( nvram.5.0 install-vmpl2.0.sh );
    foreach my $file (@files) {
        copyFile("$pluginFilesPath/$file", "$installationPath");
    }
    # copy on depending runvmware file
    copyFile("$pluginFilesPath/runvmware-player-v2", "$installationPath", "runvmware");

    ##
    ## Download and install the binarys
    system("/bin/sh /opt/openslx/plugin-repo/$self->{'name'}/$kind/install-$kind.sh");

    ##
    ## Create runlevel script
    my $runlevelScript = "$self->{'pluginRepositoryPath'}/$kind/vmware.init";
    $self->_writeRunlevelScript($vmbin, $runlevelScript);

    ##
    ## Create wrapperscripts
    $self->_writeWrapperScript("$vmpath", "$kind", "player")
        
}


1;
