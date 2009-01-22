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
# vmware.pm
#	- declares necessary information for the vmware plugin
# -----------------------------------------------------------------------------
package OpenSLX::OSPlugin::vmware;

use strict;
use warnings;

use base qw(OpenSLX::OSPlugin::Base);

use OpenSLX::Basics;
use OpenSLX::Utils;

sub new
{
	my $class = shift;

	my $self = {
		name => 'vmware',
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
		'vmware::active' => {
			applies_to_systems => 1,
			applies_to_clients => 0,
			description => unshiftHereDoc(<<'			End-of-Here'),
				should the 'vmware'-plugin be executed during boot?
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
				the execution precedence of the 'vmware' plugin
			End-of-Here
			content_regex => qr{^\d\d$},
			content_descr => 'allowed range is from 01-99',
			default => 70,
		},
		# attribute 'imagesrc' defines where we can find vmware images
		'vmware::imagessrc' => {
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

sub preInstallationPhase
{	# called before chrooting into vendor-OS root, should be used if any files
	# have to be downloaded outside of the chroot (which might be necessary
	# if the required files can't be installed via the meta-packager)
	my $self = shift;
	my $pluginRepositoryPath = shift;
		# the folder where the stage1-plugin should store all files
		# required by the corresponding stage3 runlevel script
	my $pluginTempPath = shift;
		# a temporary playground that will be cleaned up automatically

	# get path of files we need to install
	my $pluginName = $self->{'name'};
	my $pluginFilesPath
		= "$openslxConfig{'base-path'}/lib/plugins/$pluginName/files";

	# copy all needed files now
	my @files = ("dhcpd.conf", "nat.conf", "nvram.5.0", "runvmware-v2");
	foreach my $file (@files) {
		copyFile("$pluginFilesPath/$file", "$pluginRepositoryPath");
	}
}

1;
