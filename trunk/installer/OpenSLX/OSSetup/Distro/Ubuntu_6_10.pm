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
# Ubuntu_6_10.pm
#	- provides Ubuntu-6.10-specific overrides of the OpenSLX OSSetup API.
# -----------------------------------------------------------------------------
package OpenSLX::OSSetup::Distro::Ubuntu_6_10;

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
		'base-name'    => 'ubuntu-6.10',
		'arch'         => 'i386',
		'release-name' => 'edgy',
	};
	return bless $self, $class;
}

sub initDistroInfo
{
	my $self = shift;
	$self->{config}->{'repository'} = {
		'base' => {
			'urls' => "
				ftp://localhost/pub/ubuntu
			",
			'name' => 'Ubuntu 6.10',
			'repo-subdir' => 'dists/edgy',
		},
	};

	$self->{config}->{'package-subdir'} = 'pool';

	$self->{config}->{'prereq-packages'} = "
		main/d/debootstrap/debootstrap_1.0.0_all.deb
	";

	$self->{config}->{'bootstrap-prereq-packages'} = "
	";

	$self->{config}->{'bootstrap-packages'} = "
	";

	$self->{config}->{'selection'} = {
		'default' => "kmail",
	};
	return;
}

1;