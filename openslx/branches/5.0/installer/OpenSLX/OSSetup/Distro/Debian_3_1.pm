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
# OSSetup/Distro/Debian_3_1.pm
#    - provides Debian-3.1-specific overrides of the OSSetup Distro API.
# -----------------------------------------------------------------------------
package OpenSLX::OSSetup::Distro::Debian_3_1;

use strict;
use warnings;

use base qw(OpenSLX::OSSetup::Distro::Debian);

use OpenSLX::Basics;
use OpenSLX::Utils;

################################################################################
### implementation
################################################################################
sub preSystemInstallationHook
{
    my $self = shift;
    
    $self->SUPER::preSystemInstallationHook();

    # when the kernel package is being configured, it insists on trying to
    # create an initrd, which neither works nor makes sense in our environment.
    #
    # in order to circumvent this problem, we manually install initrd-tools 
    # (which contains mkinitrd) ...
    $self->{engine}->{'meta-packager'}->installPackages('initrd-tools');
    # ... and replace /usr/sbin/mkinitrd with a dummy, in order to skip the 
    # initrd-creation.
    rename('/usr/sbin/mkinitrd', '/usr/sbin/_mkinitrd');
    spitFile('/usr/sbin/mkinitrd', "#! /bin/sh\ntouch \$2\n");
    chmod 0755, '/usr/sbin/mkinitrd';
}

sub startSession
{
    my $self  = shift;
    my $osDir = shift;

    $self->SUPER::startSession($osDir);    

    # As in preSystemInstallationHook, we replace /usr/sbin/mkinitrd with a 
    # dummy, in order to skip the initrd-creation.
    #
    # During installation, this might not exist yet, so we better check
    if (-e '/usr/sbin/mkinitrd') {
        rename('/usr/sbin/mkinitrd', '/usr/sbin/_mkinitrd');
        spitFile('/usr/sbin/mkinitrd', "#! /bin/sh\ntouch \$2\n");
        chmod 0755, '/usr/sbin/mkinitrd';
    }
}

sub finishSession
{
    my $self  = shift;

    # restore /usr/sbin/mkinitrd
    rename('/usr/sbin/_mkinitrd', '/usr/sbin/mkinitrd');

    $self->SUPER::finishSession();
}

1;