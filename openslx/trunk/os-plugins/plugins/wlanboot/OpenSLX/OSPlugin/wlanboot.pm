# Copyright (c) 2009 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your suggestions, praise, or complaints to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org/
# -----------------------------------------------------------------------------
# wlanboot.pm
#    - an wlanboot extension to the stage3 system
# -----------------------------------------------------------------------------
package OpenSLX::OSPlugin::wlanboot;

use strict;
use warnings;

use base qw(OpenSLX::OSPlugin::Base);

use File::Path;

use Data::Dumper;

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
        name => 'wlanboot',
    };

    return bless $self, $class;
}

sub getInfo
{
    my $self = shift;

    return {
        description => unshiftHereDoc(<<'        End-of-Here'),
            wlanboot is an extension for stage 3
        End-of-Here
        precedence => 50,
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
        'wlanboot::active' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                should the 'wlanboot'-plugin be executed during boot?
            End-of-Here
            content_regex => qr{^(0|1)$},
            content_descr => '1 means active - 0 means inactive',
            default => '1',
        },
        'wlanboot::activenics' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                kernel modules to load ..
            End-of-Here
            content_regex => '',
            content_descr => 'space seperated list of kernel modules (without .ko)',
            default => 'iwl3945 arc4 ecb',
        },
    };
}

sub installationPhase
{
    my $self = shift;
    my $info = shift;

    my $pluginRepoPath = $info->{'plugin-repo-path'};
    my $pluginTempPath = $info->{'plugin-temp-path'};
    my $openslxBasePath = $info->{'openslx-base-path'};
    my $openslxConfigPath = $info->{'openslx-config-path'};
    my $attrs = $info->{'plugin-attrs'};

    my $filesDir = "$openslxBasePath/lib/plugins/wlanboot/files";
    slxsystem("cp -r $filesDir $pluginRepoPath/");

    return;
}

sub removalPhase
{
    my $self = shift;
    my $info = shift;
    
    my $pluginRepoPath = $info->{'plugin-repo-path'};
    my $pluginTempPath = $info->{'plugin-temp-path'};

    return;
}

sub suggestAdditionalKernelModules
{
    my $self = shift;
    my $info = shift;

    my $attrs = $info->{'attrs'}; 

    my @suggestedKernelModules;

    print Dumper(split(/ /, $attrs->{'wlanboot::activenics'}));
    push(@suggestedKernelModules, split(/ /, $attrs->{'wlanboot::activenics'} )); 

   return @suggestedKernelModules;
}

sub copyRequiredFilesIntoInitramfs
{
    my $self                = shift;
    my $targetPath         = shift;
    my $attrs               = shift;
    my $makeInitRamFSEngine = shift;
    my $pluginRepoPath = "$openslxConfig{'base-path'}/lib/plugins/wlanboot";
    
    $makeInitRamFSEngine->addCMD(
       "cp -p $pluginRepoPath/files/bin/* $targetPath/bin/"
    );
    $makeInitRamFSEngine->addCMD(
       "cp -a $pluginRepoPath/files/firmware $targetPath/lib"
    );
    $makeInitRamFSEngine->addCMD(
       "cp -a $pluginRepoPath/files/lib $targetPath/"
    );
    vlog(1, _tr("wlanboot-plugin: ..."));

    return;
}

1;
