# Copyright (c) 2007 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your suggestions, praise, or complaints to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org/
# -----------------------------------------------------------------------------
# VMware.pm
#	- an example implementation of the OSPlugin API (i.e. an os-plugin)
# -----------------------------------------------------------------------------
package OpenSLX::OSPlugin::VMware;

use strict;
use warnings;

use base qw(OpenSLX::OSPlugin::Base);

use OpenSLX::Basics;
use OpenSLX::Utils;

sub new
{
	my $class = shift;

	my $self = {};

	return bless $self, $class;
}

sub getInfo
{
	my $self = shift;

	return {
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!! descriptive text missing here !!!
		End-of-Here
		mustRunAfter => [],
	};
}

sub getAttrInfo
{	# returns a hash-ref with information about all attributes supported
	# by this specific plugin
	my $self = shift;

	# This default configuration will be added as attributes to the default
	# system, such that it can be overruled for any specific system by means
	# of slxconfig.
	return {
		# attribute 'active' is mandatory for all plugins
		'vmware::active' => {
			applies_to_systems => 1,
			applies_to_clients => 0,
			description => unshiftHereDoc(<<'			End-of-Here'),
				should the 'VMware'-plugin be executed during boot?
			End-of-Here
			content_regex => qr{^(0|1)$},
			content_descr => '1 means active - 0 means inactive',
			default => '1',
		},
		# attribute 'precedence' is mandatory for all plugins
		'vmware::precedence' => {
			applies_to_systems => 1,
			applies_to_clients => 0,
			description => unshiftHereDoc(<<'			End-of-Here'),
				the execution precedence of the 'VMware' plugin
			End-of-Here
			content_regex => qr{^\d\d$},
			content_descr => 'allowed range is from 01-99',
			default => 50,
		},

	};
}

1;
