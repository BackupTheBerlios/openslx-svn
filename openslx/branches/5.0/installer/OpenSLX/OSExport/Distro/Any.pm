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
# OSExport/Distro/Any.pm
#    - provides generic overrides of the OSExport Distro API.
# -----------------------------------------------------------------------------
package OpenSLX::OSExport::Distro::Any;

use strict;
use warnings;

use base qw(OpenSLX::OSExport::Distro::Base);

use OpenSLX::Basics;

################################################################################
### implementation
################################################################################
sub new
{
    my $class = shift;
    my $self = {
        'base-name' => 'any',
    };
    return bless $self, $class;
}

sub initDistroInfo
{
    my $self = shift;

    $self->{'export-filter'} = "
        - /var/tmp/*
        - /var/spool/*
        - /var/run/*
        - /var/lock/*
        - /var/log/*
        - /var/lib/xdm
        - /var/lib/smart
        - /var/cache/yum
        - /var/cache/man/*
        - /usr/share/vmware/*
        - /tmp/*
        - /sys/*
        - /proc/*
        - /mnt/*
        - /media/*
        + /lib/modules/*/misc/vmblock.o
        + /lib/modules/*/misc/vmnet.o
        + /lib/modules/*/misc/vmmon.o
        - /lib/klibc/events/*
        - /boot/initrd*
        - /boot/grub
    ";
    return;
}

1;