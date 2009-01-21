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
# Ubuntu_7_04.pm
#	- provides Ubuntu-7.04-specific overrides of the OpenSLX OSSetup API.
# -----------------------------------------------------------------------------
package OpenSLX::OSSetup::Distro::Ubuntu_7_04;

use strict;
use warnings;

use base qw(OpenSLX::OSSetup::Distro::Ubuntu);

use OpenSLX::Basics;

################################################################################
### implementation
################################################################################
sub new
{
	my $class = shift;
	my $self = {
		'base-name'    => 'ubuntu-7.04',
		'arch'         => 'i386',
		'release-name' => 'feisty',
	};
	return bless $self, $class;
}

sub initDistroInfo
{
	my $self = shift;
	$self->{config}->{'repository'} = {
		'base' => {
			'urls' => "
				http://ubuntu.intergenia.de/ubuntu
			",
			'name' => 'Ubuntu 7.04',
			'repo-subdir'  => 'dists',
			'distribution' => 'feisty',
			'components'   => 'main restricted',
		},
		'base_updates' => {
			'urls' => "
				ftp://localhost/pub/ubuntu
			",
			'name' => 'Ubuntu 7.04 Updates',
			'repo-subdir'  => 'dists',
			'distribution' => 'feisty-updates',
			'components'   => 'main restricted',
		},
		'base_security' => {
			'urls' => "
				ftp://localhost/pub/ubuntu
			",
			'name' => 'Ubuntu 7.04 Security',
			'repo-subdir'  => 'dists',
			'distribution' => 'feisty-security',
			'components'   => 'main restricted',
		},
	};

	$self->{config}->{'package-subdir'} = 'pool';

	$self->{config}->{'prereq-packages'} = "
		main/d/debootstrap/debootstrap_0.3.3.3ubuntu3~feisty1_all.deb
	";

	$self->{config}->{'bootstrap-packages'} = "
	";

	$self->{config}->{'selection'} = {
		'default' => "
			language-pack-de
			linux-image-generic
		",

		'gnome' => "
			<<<default>>>
			ubuntu-desktop
		",

		'kde' => "
			<<<default>>>
			kubuntu-desktop
		",

		'xfce' => "
			<<<default>>>
			xubuntu-desktop
		",
	};
	return;
}

1;
