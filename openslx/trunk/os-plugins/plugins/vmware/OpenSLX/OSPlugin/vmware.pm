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
        'vmware::imagessrc' => {
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
            content_regex => qr{^(local|vmws(5\.5|6.0)|vmpl(1\.0|2\.0))$},
            content_descr => 'Allowed values: local, vmws5.5, vmws6.0, vmpl1.0 ...',
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

    my $vmpath = "";
    my $vmbin  = "";
    my $vmfile = ""; # will be vmware or vmplayer
    my $vmversion = ""; # will be v1/2 (vmplayer)
                             # or v5.x/6.x (vmware ws) --> build number might be needed too

    # get path of files we need to install
    my $pluginFilesPath 
        = "$self->{'openslxPath'}/lib/plugins/$self->{'name'}/files";

    # copy all needed files (TODO: nvram should depend on the "kind" of vmware ...)
    # TODO: create a second runvmware version... for v5.5/6.0 or v1/2
    #       AFAIR WS5.5 is compatible with vmplayer-v1 and
    #             WS6.0 is compatible with vmplayer-v2
    #       1. check how to handle the different executable (vmware/vmplayer)
    #          1. Wrapper in stage4 which checks which one is
    #             activated in stage3 (there might be several versions installed)
    #             => one wrapperscript + v1-runvmware
    #                                            + v2-runvmware
    #          2. v1-runvmware-workstation, v1-runvmware-vmplayer
    #             v2-runvmware-workstation, v2-runvmware-vmplayer
    #             keeping runvmware code in sync is more ugly then
    #             OR: put differences to include files (which might be stored in /etc/vmware)
    #          3. check if its possible to have
    #             v1-runvmware-template   v2-runvmware-template
    #             in stage3 we add a variable if its vmware or vmplayer
    #             to it
    my @files = qw( vmware-init nvram.5.0 runvmware-v2 );
    foreach my $file (@files) {
        copyFile("$pluginFilesPath/$file", $self->{'pluginRepositoryPath'});
    }

    # generate the runlevel scripts for all existing vmware installations,
    # variants because we do not know which on is selected on client level
    # in stage3 (we know the installed packages from ** / 'vmware::kind'
    # (code depends on distro/version and vmware location)
    # for local ... and other vm-installations
    # TODO: generate the list from ** / 'vmware::kind' (stage1 attributes)
    #       (do not generate scripts for packages which are not installed)
    my @types = qw( local );
    foreach my $type (@types) {
        # location of the vmware stuff, "local" for directly installed
        # package (more sophisticated assignment might be needed ...)
        if ($type eq "local") {
            $vmpath = "/usr/lib/vmware";
            $vmbin  = "/usr/bin";
            # test if we use vmplayer or vmware - should be moved to subroutine +++!!, because
            # needed in other places too ... (check in this routine both vmware/player, build)
            #TODO: error handling if non installed or not supported
            #      version of local
            if (-e "/usr/lib/vmware/bin/vmware") {
                $vmfile = "vmware";
                # get version. read it out of the binary
                open(FH, "/usr/lib/vmware/bin/vmware");
                $/ = undef;
                my $data = <FH>;
                close FH;
		#TODO: add the else case, if we cant find this string
		if ($data =~ m{(\d\.\d)\.\d build-(\d)+}) {
		    $vmversion = $1;
		}
                print "DEBUG: vmware ws version: $vmversion\n";
                rename("/usr/bin/$vmfile", "/usr/bin/$vmfile.slx-bak");
                linkFile("/var/X11R6/bin/$vmfile", "/usr/bin/$vmfile");
            } elsif (-e "/usr/lib/vmware/bin/vmplayer") {
                $vmfile = "vmplayer";
                # dublicate of test for vmware - should be put into a function,
                # e.g. in one which decides if workstation or player too ... (see above, exactly
                # the same code for checking!!)
                open(FH, "/usr/lib/vmware/bin/vmplayer");
                $/ = undef;
                my $data = <FH>;
                close FH;
		#TODO: add the else case, if we cant find this string
		if ($data =~ m{(\d\.\d)\.\d build-(\d)+}) {
		    $vmversion = $1;
		}
                chomp($vmversion);
                print "DEBUG: vmplayer version: $vmversion\n";
                rename("/usr/bin/$vmfile", "/usr/bin/$vmfile.slx-bak");
                linkFile("/var/X11R6/bin/$vmfile", "/usr/bin/$vmfile");
            }
        }

        # (TODO: pathname not completely clear ...
        #   -> should be the one of the plugin)
        else {
            $vmpath = "$self->{'pluginRepositoryPath'}/vmware/$type";
            $vmbin  = "$vmpath/bin";
            # vmversion, build and vmware/player should be read via subroutine +++ named above!!
            $vmversion = "TODO: get information from the stage1 flag";
            $vmfile = "TODO: get information from the stage1 flag";
        }
        my $runlevelScript = "$self->{'pluginRepositoryPath'}/vmware.$type";
        $self->_writeRunlevelScript($vmbin, $runlevelScript);

        # create our own simplified version of the vmware and player wrapper
        # Depending on the configured kind it will be copied in stage3
        # because of tempfs of /var but not /usr we link the file
        # to /var/..., where we can write in stage3
        my $script = unshiftHereDoc(<<"        End-of-Here");
            #!/bin/sh
            # written by OpenSLX-plugin 'vmware' in Stage1
            # radically simplified version of the original script $vmfile by VMware Inc.
            PREFIX=$vmpath # depends on the vmware location
            exec "\$PREFIX"'/lib/wrapper-gtk24.sh' \\
                 "\$PREFIX"'/lib' \\
                 "\$PREFIX"'/bin/$vmfile' \\
                 "\$PREFIX"'/libconf' "\$@"
        End-of-Here
        # TODO: check if these will be overwritten if we have more as
        # local defined (add the version/type like vmpl1.0, vmws5.5, ...)
        # then we have a lot of files easily distinguishable by there suffix
        spitFile("$self->{'pluginRepositoryPath'}/$vmfile", $script);
        chmod 0755, "$self->{'pluginRepositoryPath'}/$vmfile";

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
    # TODO: check if this can result in an error or conflict
    my @files = qw( vmware vmplayer );
    foreach my $file (@files) {
        unlink("/usr/bin/$file");
        rename("/usr/bin/$file.slx-bak", "/usr/bin/$file");
        # we only create in stage3 a file there... not needed
        #unlink("/var/X11R6/bin/$file");
    }
    # TODO: path is distro specific
    #rename ("/etc/init.d/vmware.slx-bak", "/etc/init.d/vmware");
    return;
}

# such a function will be implemented on a higher level some day. At first the
# needed characteristics are collected and tried out with local subroutines
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

1;
