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
# Engine.pm
#	- provides driver engine for the OSPlugin API.
# -----------------------------------------------------------------------------
package OpenSLX::OSPlugin::Engine;

use strict;
use warnings;

our $VERSION = 1.01;    # API-version . implementation-version

use File::Basename;

use OpenSLX::Basics;
use OpenSLX::OSSetup::Engine;
use OpenSLX::Utils;

################################################################################
### interface methods
################################################################################
sub new
{
	my $class = shift;

	my $self = {};

	return bless $self, $class;
}

sub getAvailablePlugins
{	# Class-method!
	my $class = shift;

	return 
		map { basename($_); }
		sort 
		glob("$openslxConfig{'base-path'}/lib/plugins/*");
}

sub initialize
{
	my $self         = shift;
	my $pluginName   = shift;
	my $vendorOSName = shift;

	$self->{'plugin-name'}     = $pluginName;
	$self->{'vendor-os-name'}  = $vendorOSName;

	$self->{'vendor-os-path'} 
		= "$openslxConfig{'private-path'}/stage1/$vendorOSName";
	vlog(1, "vendor-OS path is '$self->{'vendor-os-path'}'");

	$self->{'plugin-path'} 
		= "$openslxConfig{'base-path'}/lib/plugins/$pluginName";
	vlog(1, "plugin path is '$self->{'plugin-path'}'");
	
	$self->{'plugin'} = $self->_loadPlugin();
}

sub installPlugin
{
	my $self = shift;

	# create ossetup-engine for given vendor-OS:
	my $osSetupEngine = OpenSLX::OSSetup::Engine->new;
	$osSetupEngine->initialize($self->{'vendor-os-name'}, 'plugin');
	$self->{'os-setup-engine'} = $osSetupEngine;
	$self->{'distro-name'}     = $osSetupEngine->{'distro-name'};

	my $chrootedPluginRepoPath 
		= "$openslxConfig{'base-path'}/plugin-repo/$self->{'plugin-name'}";
	my $pluginRepoPath = "$self->{'vendor-os-path'}/$chrootedPluginRepoPath";
	my $chrootedPluginTempPath = "/tmp/slx-plugin/$self->{'plugin-name'}";
	my $pluginTempPath = "$self->{'vendor-os-path'}/$chrootedPluginTempPath";
	foreach my $path ($pluginRepoPath, $pluginTempPath) {
		if (slxsystem("mkdir -p $path")) {
			croak(_tr("unable to create path '%s'! (%s)", $path, $!));
		}
	}

	$self->{plugin}->preInstallationPhase($pluginRepoPath, $pluginTempPath);
	
	$self->{'os-setup-engine'}->callChrootedFunctionForVendorOS(
		sub {
			$self->{plugin}->installationPhase(
				$chrootedPluginRepoPath, $chrootedPluginTempPath
			);
		}
	);
	
	$self->{plugin}->postInstallationPhase($pluginRepoPath, $pluginTempPath);
}

sub getPlugin
{
	my $self = shift;

	return $self->{plugin};
}
	
sub removePlugin
{
}

sub _loadPlugin
{
	my $self = shift;
	
	my $pluginModule = "OpenSLX::OSPlugin::$self->{'plugin-name'}";
	my $plugin = instantiateClass(
		$pluginModule, { pathToClass => $self->{'plugin-path'} }
	);
	$plugin->initialize($self);
	return $plugin;
}
