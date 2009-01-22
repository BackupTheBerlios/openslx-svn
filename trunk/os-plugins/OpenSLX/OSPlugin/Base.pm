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
# Base.pm
#	- provides empty base of the OpenSLX OSPlugin API.
# -----------------------------------------------------------------------------
package OpenSLX::OSPlugin::Base;

use strict;
use warnings;

our $VERSION = 1.01;		# API-version . implementation-version

use OpenSLX::Basics;

################################################################################
# if you have any questions regarding the concept of OS-plugins and their
# implementation, please drop a mail to: ot@openslx.com, or join the IRC-channel
# '#openslx' (on freenode).
################################################################################

sub new
{
	confess "Creating OpenSLX::OSPlugin::Base-objects directly makes no sense!";
}

sub initialize
{
	my $self = shift;

	# The os-plugin-engine drives us, it provides some useful services relevant 
	# to installing stuff into the vendor-OS, like downloading functionality, 
	# access to meta-packager, ...
	$self->{'os-plugin-engine'} = shift;
	
	return;
}

sub getInfo
{	# returns a hash-ref with administrative information about this plugin
	# (what does it do and how does it relate to other plugins)
	my $self = shift;

	return {
		# a short (one-liner) description of this plugin
		description => '',
		# a list of plugins that must have completed before this plugin can 
		# be executed
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
		# attribute 'precedence' is mandatory for all plugins
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
	
	return;
}

sub installationPhase
{	# called while chrooted to the vendor-OS root, most plugins will do all
	# their installation work here
	my $self = shift;
	my $pluginRepositoryPath = shift;
		# the repository folder, this time from inside the chroot
	my $pluginTempPath = shift;
		# the temporary folder, this time from inside the chroot
	
	return;
}

sub postInstallationPhase
{	# called after having returned from chrooted environment, should be used
	# to cleanup any leftovers, if any such thing is necessary
	my $self                 = shift;
	my $pluginRepositoryPath = shift;
	my $pluginTempPath       = shift;
	
	return;
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
	
	return;
}

sub removalPhase
{	# called while chrooted to the vendor-OS root, most plugins will do all
	# their uninstallation work here
	my $self = shift;
	my $pluginRepositoryPath = shift;
		# the repository folder, this time from inside the chroot
	my $pluginTempPath = shift;
		# the temporary folder, this time from inside the chroot
	
	return;
}

sub postRemovalPhase
{	# called after having returned from chrooted environment, should be used
	# to cleanup any leftovers, if any such thing is necessary
	my $self                 = shift;
	my $pluginRepositoryPath = shift;
	my $pluginTempPath       = shift;
	
	return;
}

sub suggestAdditionalKernelParams
{	# called by config-demuxer in order to give the plugin a chance to add
	# any kernel params it requires.
	# In order to do so, the plugin should analyse the contents of the 
	# given string ('kernel-params') and return a list of additional params 
	# that it would like to see added.
	my $self         = shift;
	my $kernelParams = shift;
	
	return;
}

sub suggestAdditionalKernelModules
{	# called by config-demuxer in order to give the plugin a chance to add
	# any kernel modules it requires.
	# In order to do so, the plugin should return the names of additional kernel
	# modules that it would like to see added.
	my $self                = shift;
	my $makeInitRamFSEngine = shift;
	
	return;
}

sub copyRequiredFilesIntoInitramfs
{	# called by config-demuxer in order to give the plugin a chance to copy
	# all required files from the vendor-OS into the initramfs.
	# N.B.: Only files that are indeed required by the initramfs should be
	#       copied here, i.e. files that are needed *before* the root-fs
	#       has been mounted!
	my $self                = shift;
	my $targetPath          = shift;
	my $attrs				= shift;
	my $makeInitRamFSEngine = shift;
	
	return;
}
