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
# Debian_4_0_amd64.pm
#	- provides Debian-4.0_amd64-specific overrides of the OpenSLX OSSetup API.
# -----------------------------------------------------------------------------
package OpenSLX::OSSetup::Distro::Debian_4_0_amd64;

use strict;
use warnings;

use base qw(OpenSLX::OSSetup::Distro::Debian);

use OpenSLX::Basics;

################################################################################
### implementation
################################################################################
sub new
{
	my $class = shift;
	my $self = {
		'base-name'    => 'debian-4.0_amd64',
		'arch'         => 'amd64',
		'release-name' => 'etch',
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
			'name' => 'Debian 4.0',
			'repo-subdir'  => 'dists',
			'distribution' => 'etch',
			'components'   => 'main',
		},
	};

	$self->{config}->{'package-subdir'} = 'pool';

	$self->{config}->{'prereq-packages'} = "
		main/d/debootstrap/debootstrap_0.3.3.2etch1_all.deb
	";

	$self->{config}->{'bootstrap-packages'} = "
	";

	$self->{config}->{'selection'} = {
		'default' => "
			linux-image-amd64
			locales-all
		",

		'gnome' => "
			<<<default>>>
			gnome
		",

		'kde' => "
			<<<default>>>
			kde
		",

		# current 64-bit build platform for OpenSLX:
		'openslx-build' => "
			<<<default>>>
			bzip2
			gcc
			libc6-dev
			make
		",
	};

	return;
}

1;