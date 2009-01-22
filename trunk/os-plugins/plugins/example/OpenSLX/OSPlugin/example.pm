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
# example.pm
#	- an example implementation of the OSPlugin API (i.e. an os-plugin)
# -----------------------------------------------------------------------------
package OpenSLX::OSPlugin::example;

use strict;
use warnings;

use base qw(OpenSLX::OSPlugin::Base);

use OpenSLX::Basics;
use OpenSLX::Utils;

################################################################################
# if you have any questions regarding the concept of OS-plugins and their
# implementation, please drop a mail to: ot@openslx.com, or join the IRC-channel
# '#openslx' (on freenode).
################################################################################
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
			just an exemplary plugin that prints a smiley when the client boots
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
		'example::active' => {
			applies_to_systems => 1,
			applies_to_clients => 0,
			description => unshiftHereDoc(<<'			End-of-Here'),
				should the 'example'-plugin be executed during boot?
			End-of-Here
			content_regex => qr{^(0|1)$},
			content_descr => '1 means active - 0 means inactive',
			default => '1',
		},
		# attribute 'precedence' is mandatory for all plugins
		'example::precedence' => {
			applies_to_systems => 1,
			applies_to_clients => 0,
			description => unshiftHereDoc(<<'			End-of-Here'),
				the execution precedence of the 'example' plugin
			End-of-Here
			content_regex => qr{^\d\d$},
			content_descr => 'allowed range is from 01-99',
			default => 50,
		},

		# plugin specific attributes start here ...
		'example::preferred_side' => {
			applies_to_systems => 1,
			applies_to_clients => 0,
			description => unshiftHereDoc(<<'			End-of-Here'),
				determines to which side you have to tilt your head in order
				to read the smiley
			End-of-Here
			content_regex => qr{^(left|right)$},
			content_descr => q{'left' will print ';-)' - 'right' will print '(-;'},
			default => 'left',
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
	
	# in this example plugin, there's no need to do anything here ...
}

sub installationPhase
{	# called while chrooted to the vendor-OS root, most plugins will do all
	# their installation work here
	my $self = shift;
	my $pluginRepositoryPath = shift;
		# the repository folder, this time from inside the chroot
	my $pluginTempPath = shift;
		# the temporary folder, this time from inside the chroot
	
	# for this example plugin, we simply create two files:
	spitFile("$pluginRepositoryPath/right", "(-;\n");
	spitFile("$pluginRepositoryPath/left", ";-)\n");
}

sub postInstallationPhase
{	# called after having returned from chrooted environment, should be used
	# to cleanup any leftovers, if any such thing is necessary
	my $self                 = shift;
	my $pluginRepositoryPath = shift;
	my $pluginTempPath       = shift;
	
	# in this example plugin, there's no need to do anything here ...
}

sub preRemovalPhase
{	# called before chrooting into vendor-OS root, should be used if any
	# preparations outside of the chroot have to be made before the plugin 
	# can be removed
	my $self = shift;
	my $pluginRepositoryPath = shift;
		# the folder where the stage1-plugin has stored all files
		# required by the corresponding stage3 runlevel script
	my $pluginTempPath = shift;
		# a temporary playground that will be cleaned up automatically
}

sub removalPhase
{	# called while chrooted to the vendor-OS root, most plugins will do all
	# their uninstallation work here
	my $self = shift;
	my $pluginRepositoryPath = shift;
		# the repository folder, this time from inside the chroot
	my $pluginTempPath = shift;
		# the temporary folder, this time from inside the chroot
}

sub postRemovalPhase
{	# called after having returned from chrooted environment, should be used
	# to cleanup any leftovers, if any such thing is necessary
	my $self                 = shift;
	my $pluginRepositoryPath = shift;
	my $pluginTempPath       = shift;
}

1;
