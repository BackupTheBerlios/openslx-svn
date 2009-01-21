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
# Debian_4_0.pm
#	- provides Debian-4.0-specific overrides of the OpenSLX OSSetup API.
# -----------------------------------------------------------------------------
package OpenSLX::OSSetup::Distro::Debian_4_0;

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
		'base-name'    => 'debian-4.0',
		'arch'         => 'i386',
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
		main/d/debootstrap/debootstrap_1.0.0_all.deb
	";

	$self->{config}->{'bootstrap-packages'} = "
	";

	$self->{config}->{'selection'} = {
		'default' => "
			kernel-image-2.6-386
			kmail
		",
	};

	return;
}

1;