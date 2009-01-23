# Copyright (c) 2006, 2007 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your suggestions, praise, or complaints to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org/
# -----------------------------------------------------------------------------
# NFS.pm
#    - provides NFS-specific overrides of the OpenSLX::OSExport::FileSystem API.
# -----------------------------------------------------------------------------
package OpenSLX::OSExport::FileSystem::NFS;

use strict;
use warnings;

use base qw(OpenSLX::OSExport::FileSystem::Base);

use File::Basename;
use OpenSLX::Basics;
use OpenSLX::ConfigDB qw(:support);
use OpenSLX::Utils;

################################################################################
### interface methods
################################################################################
sub new
{
    my $class = shift;
    my $self = {
        'name' => 'nfs',
    };
    return bless $self, $class;
}

sub initialize
{
    my $self = shift;
    my $engine = shift;

    $self->{'engine'} = $engine;
    my $exportBasePath = "$openslxConfig{'public-path'}/export";
    $self->{'export-path'} = "$exportBasePath/nfs/$engine->{'vendor-os-name'}";
    return;
}

sub exportVendorOS
{
    my $self = shift;
    my $source = shift;

    my $target = $self->{'export-path'};
    
    # For development purposes, it is very desirable to be able to take a 
    # shortcut that avoids doing the actual copying of the folders (as that
    # takes a considerable amount of time).
    # In order to support this, we explicitly check if the OpenSLX NFS export
    # root folder (/srv/openslx/export/nfs) is a bind-mount of the OpenSLX 
    # stage1 folder (/var/opt/openslx/stage1).
    # If that is the case, we print a notice and skip the rsync step (which 
    # wouldn't work anyway, as source and target folder are the same).
    my $stage1Root = dirname($source);
    my $nfsRoot    = dirname($target);
    chomp(my $canonicalStage1Root = qx{readlink -f $stage1Root} || $stage1Root);
    chomp(my $canonicalNFSRoot    = qx{readlink -f $nfsRoot}    || $nfsRoot);
    my @mounts = slurpFile('/etc/mtab');
    for my $mount (@mounts) {
        if ($mount =~ m{
            ^
            $canonicalStage1Root    # mount source
            \s+
            $canonicalNFSRoot       # mount target
            \s+
            none                    # filesystem for bind mounts is 'none'
            \s+
            \S*\bbind\b\S*          # look for bind mounts only
        }gmsx) {
            warn _tr(
                "%s is a bind-mount to vendor-OS root - rsync step is skipped!",
                $target
            );
            return;
        }
    }
    
    $self->_copyViaRsync($source, $target);

    return;
}

sub purgeExport
{
    my $self = shift;

    my $target = $self->{'export-path'};
    if (system("rm -r $target")) {
        vlog(0, _tr("unable to remove export '%s'!", $target));
        return 0;
    }
    return 1;
}

sub checkRequirements
{
    my $self         = shift;
    my $vendorOSPath = shift;

    # determine most appropriate kernel version ...
    my $kernelVer = $self->_pickKernelVersion($vendorOSPath);

    # ... and check if that kernel-version provides all the required modules
    my $nfsMod = $self->_locateKernelModule(
        $vendorOSPath,
        'nfs.ko',
        [
            "$vendorOSPath/lib/modules/$kernelVer/kernel/fs/nfs",
            "$vendorOSPath/lib/modules/$kernelVer/kernel/fs"
        ]
    );
    if (!defined $nfsMod) {
        warn _tr("unable to find nfs-module for kernel version '%s'.",
            $kernelVer);
        return;
    }
    return 1;
}

sub generateExportURI
{
    my $self = shift;
    my $export = shift;
    my $vendorOS = shift;

    my $serverIP = $export->{server_ip} || '';
    my $server 
        = length($serverIP) ? $serverIP : generatePlaceholderFor('serverip');
    my $port = $export->{port} || '';
    $server .= ":$port" if length($port);

    my $exportPath = "$openslxConfig{'public-path'}/export";
    return "nfs://$server$exportPath/nfs/$vendorOS->{name}";
}

sub requiredFSMods
{
    my $self = shift;

    return qw( nfs );
}

sub showExportConfigInfo
{
    my $self = shift;
    my $export = shift;

    print (('#' x 80)."\n");
    print _tr("Please make sure the following line is contained in /etc/exports\nin order to activate the NFS-export of this vendor-OS:\n\t%s\n",
              "$self->{'export-path'}\t*(ro,no_root_squash,async,no_subtree_check)");
    print (('#' x 80)."\n");

# TODO : add something a bit more clever here...
#    my $exports = slurpFile("/etc/exports");
    return;
}

################################################################################
### implementation methods
################################################################################
sub _copyViaRsync
{
    my $self = shift;
    my $source = shift;
    my $target = shift;

    if (system("mkdir -p $target")) {
        die _tr("unable to create directory '%s', giving up! (%s)\n",
                $target, $!);
    }
    my $includeExcludeList = $self->_determineIncludeExcludeList();
    vlog(1, _tr("using include-exclude-filter:\n%s\n", $includeExcludeList));
    my $rsyncFH;
    my $additionalRsyncOptions = $ENV{SLX_RSYNC_OPTIONS} || '';
    my $rsyncCmd
        = "rsync -av --delete-excluded --exclude-from=- $additionalRsyncOptions"
            . " $source/ $target";
    vlog(2, "executing: $rsyncCmd\n");
    open($rsyncFH, '|-', $rsyncCmd)
        or die _tr("unable to start rsync for source '%s', giving up! (%s)",
                   $source, $!);
    print $rsyncFH $includeExcludeList;
    close($rsyncFH)
        or die _tr("unable to export to target '%s', giving up! (%s)",
                   $target, $!);
    return;
}

sub _determineIncludeExcludeList
{
    my $self = shift;

    # Rsync uses a first match strategy, so we mix the local specifications
    # in front of the filterset given by the package (as the local filters
    # should always overrule the vendor filters):
    my $distroName = $self->{engine}->{'distro-name'};
    my $localFilterFile 
        = "$openslxConfig{'config-path'}/distro-info/$distroName/export-filter";
    my $includeExcludeList 
        = slurpFile($localFilterFile, { failIfMissing => 0 });
    $includeExcludeList .= $self->{engine}->{distro}->{'export-filter'};
    $includeExcludeList =~ s[^\s+][]igms;
        # remove any leading whitespace, as rsync doesn't like it
    return $includeExcludeList;
}

1;
