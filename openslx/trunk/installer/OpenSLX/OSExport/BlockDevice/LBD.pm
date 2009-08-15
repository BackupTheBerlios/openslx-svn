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
# LBD.pm
#    - provides the local block devices with Squashfs container specific
#      overrides of the OpenSLX::OSExport::BlockDevice API.
# -----------------------------------------------------------------------------
package OpenSLX::OSExport::BlockDevice::LBD;

use strict;
use warnings;

use base qw(OpenSLX::OSExport::BlockDevice::Base);

use File::Basename;
use OpenSLX::Basics;
use OpenSLX::ConfigDB qw(:support);
use OpenSLX::OSExport::BlockDevice::Base 1;
use OpenSLX::Utils;

################################################################################
### interface methods
################################################################################
sub new
{
    my $class = shift;
    my $self = {'name' => 'LBD',};
    return bless $self, $class;
}

sub generateExportURI
{
    my $self   = shift;
    
    return "lbd://sda1/squashfs";
}

sub requiredBlockDeviceModules
{
    my $self = shift;

    return qw( ehci_hcd usb_storage scsi_mod sd_mod loop ext3 );
}

sub requiredBlockDeviceTools
{
    my $self = shift;

    return qw( );
}

sub showExportConfigInfo
{
    my $self   = shift;
    my $export = shift;

    print '#' x 80 , "\n", 
    _tr(
        "Please make sure you copy all corresponding files to your boot\n",
        "device you wish to deploy (e.g. bootable USB stick)\n"
    ),
    "Make your device bootable using syslinux for (v)fat or extlinux for\n",
    "ext2/3 partitions. Cat HPA syslinux' mbr to the device very beginning\n",
    "and set the boot flag to the partion you made bootable\n\n",
    '#' x 80, "\n";
    return;
}

1;
