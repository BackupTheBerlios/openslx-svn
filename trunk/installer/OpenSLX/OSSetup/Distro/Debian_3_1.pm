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
# Debian_3_1.pm
#	- provides Debian-3.1-specific overrides of the OpenSLX OSSetup API.
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
	slxsystem("apt-get install initrd-tools");
	# ... and replace /usr/sbin/mkinitrd with a dummy, in order to skip the 
	# initrd-creation.
	rename('/usr/sbin/mkinitrd', '/usr/sbin/_mkinitrd');
	spitFile('/usr/sbin/mkinitrd', "#! /bin/sh\ntouch \$2\n");
	chmod 0755, '/usr/sbin/mkinitrd';
}

sub postSystemInstallationHook
{
	my $self = shift;

	# restore /usr/sbin/mkinitrd
	rename('/usr/sbin/_mkinitrd', '/usr/sbin/mkinitrd');
	$self->SUPER::postSystemInstallationHook();
}

1;