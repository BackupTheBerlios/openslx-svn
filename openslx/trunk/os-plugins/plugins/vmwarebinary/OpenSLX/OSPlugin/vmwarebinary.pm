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
# vmwarebinary.pm
#	- declares necessary information for the vmware plugin
# -----------------------------------------------------------------------------
package OpenSLX::OSPlugin::vmwarebinary;

use strict;
use warnings;

use base qw(OpenSLX::OSPlugin::Base);

use File::Path;

use OpenSLX::Basics;
use OpenSLX::Utils;

sub new
{
	my $class = shift;

	my $self = {
		name => 'vmwarebinary',
	};

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
		'vmwarebinary::active' => {
			applies_to_systems => 1,
			applies_to_clients => 0,
			description => unshiftHereDoc(<<'			End-of-Here'),
				should the 'vmwarebinary'-plugin be executed during boot?
			End-of-Here
			content_regex => qr{^(0|1)$},
			content_descr => '1 means active - 0 means inactive',
			default => '1',
		},
		# attribute 'precedence' is mandatory for all plugins
		'vmwarebinary::precedence' => {
			applies_to_systems => 1,
			applies_to_clients => 0,
			description => unshiftHereDoc(<<'			End-of-Here'),
				the execution precedence of the 'vmwarebinary' plugin
			End-of-Here
			content_regex => qr{^\d\d$},
			content_descr => 'allowed range is from 01-99',
			default => 70,
		},
		# attribute 'imagesrc' defines where we can find vmware images
		'vmwarebinary::imagessrc' => {
			applies_to_systems => 1,
			applies_to_clients => 1,
			description => unshiftHereDoc(<<'			End-of-Here'),
				Where do we store our vmware images? NFS? Filesystem?
			End-of-Here
			content_regex => qr{^\d\d$},
			content_descr => 'Allowed values: path or URI',
			default => "",
		},

	};
}

sub installationPhase
{
	my $self                 = shift;
	my $pluginRepositoryPath = shift;
	my $pluginTempPath       = shift;
	my $openslxPath          = shift;

	# get path of files we need to install
	my $pluginFilesPath = "$openslxPath/lib/plugins/$self->{'name'}/files";

	# copy all needed files now
	my @files = qw( installbinary.sh locations
		VMware-player-2.0.2-59824.i386.tar.gz depmod.sh uname.sh
		nvram.5.0 insmod.sh runvmware-v2 );
	foreach my $file (@files) {
		copyFile("$pluginFilesPath/$file", $pluginRepositoryPath);
	}

	system("/bin/sh /opt/openslx/plugin-repo/$self->{'name'}/installbinary.sh");

	return;
}

sub removalPhase
{
	my $self                 = shift;
	my $pluginRepositoryPath = shift;
	my $pluginTempPath       = shift;
	my $openslxPath          = shift;
	
	rmtree ( [ $pluginRepositoryPath ] );
	
	return;
}

1;