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

use base qw(OpenSLX::OSSetup::Distro::Base);

use OpenSLX::Basics;

################################################################################
### implementation
################################################################################
sub new
{
	my $class = shift;
	my $self = {
		'base-name' => 'debian-4.0',
	};
	return bless $self, $class;
}

sub initialize
{
	my $self = shift;
	my $engine = shift;

	$self->SUPER::initialize($engine);
	$self->{'packager-type'} = 'dpkg';
	$self->{'meta-packager-type'} = $ENV{SLX_META_PACKAGER} || 'apt';
	$self->{'stage1c-faked-files'} = [
	];
}

sub fixPrerequiredFiles
{
	my $self = shift;
	my $stage1cDir = shift;
}

sub initDistroInfo
{
	my $self = shift;
	$self->{config}->{'repository'} = {
		'base' => {
			'urls' => "
			",
			'name' => '',
			'repo-subdir' => '',
		},
		'base_update' => {
			'urls' => '
			',
			'name' => '',
			'repo-subdir' => '',
		},
	};

	$self->{config}->{'package-subdir'} = '';

	$self->{config}->{'prereq-packages'} = "
	";

	$self->{config}->{'bootstrap-prereq-packages'} = "";

	$self->{config}->{'bootstrap-packages'} = "
	";

	$self->{config}->{'selection'} = {
		'default' => "list any packagenames here",
	}
}

1;