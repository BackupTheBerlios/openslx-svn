# Copyright (c) 2008 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your suggestions, praise, or complaints to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org/
# -----------------------------------------------------------------------------
package OpenSLX::OSPlugin::vmchooser;

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

	my $self = {
		name => 'vmchooser',
	};

	return bless $self, $class;
}

sub getInfo
{
	my $self = shift;

	return {
		description => unshiftHereDoc(<<'		End-of-Here'),
			this plugin will over a list of different, chooseable virtualmachine images
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
		'vmchooser::active' => {
			applies_to_systems => 0,
			applies_to_clients => 0,
			description => unshiftHereDoc(<<'			End-of-Here'),
				should the 'vmchooser'-plugin be executed during boot?
			End-of-Here
			content_regex => qr{^(0|1)$},
			content_descr => '1 means active - 0 means inactive',
			default => '1',
		},
		# attribute 'precedence' is mandatory for all plugins
		'example::precedence' => {
			applies_to_systems => 1,
			applies_to_clients => 1,
			description => unshiftHereDoc(<<'			End-of-Here'),
				the execution precedence of the 'vmchooser' plugin
			End-of-Here
			content_regex => qr{^\d\d$},
			content_descr => 'allowed range is from 01-99',
			default => 50,
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
	
	# uncomment the following if you need to copy files
	## get path of files we need to install
	#my $pluginName = $self->{'name'};

	##my $pluginFilesPath
	#	= "$openslxConfig{'base-path'}/lib/plugins/$pluginName/files";

	## copy all needed files now
	#my @files = ("file1", "file2");
	#foreach my $file (@files) {
	#	copyFile("$pluginFilesPath/$file", "$pluginRepositoryPath");
	#}
}

1;
