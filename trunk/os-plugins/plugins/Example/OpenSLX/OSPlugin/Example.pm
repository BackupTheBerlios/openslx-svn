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
# Example.pm
#	- an example implementation of the OSPlugin API (i.e. an os-plugin)
# -----------------------------------------------------------------------------
package OpenSLX::OSPlugin::Example;

use strict;
use warnings;

our $VERSION = 1.01;    # API-version . implementation-version

use OpenSLX::Basics;
use OpenSLX::Utils;

################################################################################
# if you have any questions regarding the concept of OS-plugins and their
# implementation, please drop a mail to: ot@openslx.com, or join the IRC-channel
# '#openslx' (on freenode).
################################################################################
### interface methods
################################################################################
sub new
{
	my $class = shift;

	my $self = {};

	return bless $self, $class;
}

sub initialize
{
	my $self = shift;

	# The os-plugin-engine drives us, it provides some useful services relevant 
	# to installing stuff into the vendor-OS, like downloading functionality, 
	# access to meta-packager, ...
	$self->{'os-plugin-engine'} = shift;

	# Any other static initialization necessary for a plugin should be done 
	# here, more often than not, this will involve a configurational hash
	# representing the default settings for this plugin.
	# At a later stage, the user will be able to change plugin-specific settings
	# (on a per-system/client basis) via slxconfig, such that the actual 
	# configuration will be stored in the DB. 
	# Currently, though, you have to change the settings here:
	$self->{config} = {
		'active' => 1,					# set to 0 in order to deactivate
		'precedence' => 10,				# runlevel precedence
		'preferred_side' => 'left',		# just a silly example
	}
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
	spitFile("$pluginRepositoryPath/left", "(-;\n");
	spitFile("$pluginRepositoryPath/right", ";-)\n");
}

sub postInstallationPhase
{	# called after having returned from chrooted environment, should be used
	# to cleanup any leftovers, if any such thing is necessary
	my $self                 = shift;
	my $pluginRepositoryPath = shift;
	my $pluginTempPath       = shift;
	
	# in this example plugin, there's no need to do anything here ...
}

sub getConfig
{	# called from the config-demuxer in order ot access the configurational
    # hash, which will then be written to a file (in this case: 
    # /opt/openslx/plugin-conf/Example.conf), that will be transported to each
    # client as part of the conf-TGZ.
	my $self = shift;

    return $self->{config};
}

sub preRemovalPhase
{
}

sub removalPhase
{
}

sub postRemovalPhase
{
}

