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
sub new
{
	my $class = shift;
	my $self = {
		'base-name' => 'debian-3.1',
		'arch'         => 'i386',
		'release-name' => 'sarge',
	};
	return bless $self, $class;
}

sub initDistroInfo
{
	my $self = shift;

	$self->{config}->{'repository'} = {
		'base' => {
			'urls' => "
				http://debian.intergenia.de/debian
			",
			'name' => 'Debian 3.1',
			'repo-subdir'  => 'dists',
			'distribution' => 'sarge',
			'components'   => 'main',
		},
	};

	$self->{config}->{'package-subdir'} = 'pool';

	$self->{config}->{'prereq-packages'} = "
		main/d/debootstrap/debootstrap_0.3.3.2_all.deb
	";

	$self->{config}->{'bootstrap-packages'} = "
	";

	$self->{config}->{'selection'} = {
		'default' => "
			kernel-image-2.6-386
			locales
		",

		'gnome' => "
			<<<default>>>
			gnome
		",

		'kde' => "
			<<<default>>>
			kde
		",

		# current build platform for OpenSLX:
		'openslx-build' => "
			<<<default>>>
			gcc
			libc6-dev
			make
		",

	};

	return;
}

sub preSystemInstallationHook
{
	my $self = shift;
	
	$self->SUPER::preSystemInstallationHook();

	# replace /usr/sbin/mkinitrd with a dummy, in order to skip the hopeless
	# pass at trying to create an initrd. It doesn't work and we don't need
	# it either.
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