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
	return if !$self->{'plugin'};

	return 1;
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
	
	$self->_addInstalledPluginToDB();

	return 1;
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
	return if !$plugin;

	$plugin->initialize($self);

	return $plugin;
}

sub _addInstalledPluginToDB
{
	my $self = shift;
	
	my $openslxDB = instantiateClass("OpenSLX::ConfigDB");
	$openslxDB->connect();
	my $vendorOS = $openslxDB->fetchVendorOSByFilter( { 
		name => $self->{'vendor-os-name'},
	} );
	if (!$vendorOS) {
		die _tr(
			'unable to find vendor-OS "%s" in DB!', $self->{'vendor-os-name'}
		);
	}
	$openslxDB->addInstalledPlugin($vendorOS->{id}, $self->{'plugin-name'});
	$openslxDB->disconnect();

	return 1;
}

sub _removeInstalledPluginFromDB
{
	my $self = shift;
	
	my $openslxDB = instantiateClass("OpenSLX::ConfigDB");
	$openslxDB->connect();
	my $vendorOS = $openslxDB->fetchVendorOSByFilter( { 
		name => $self->{'vendor-os-name'},
	} );
	if (!$vendorOS) {
		die _tr(
			'unable to find vendor-OS "%s" in DB!', $self->{'vendor-os-name'}
		);
	}
	$openslxDB->removeInstalledPlugin($vendorOS->{id}, $self->{'plugin-name'});
	$openslxDB->disconnect();

	return 1;
}

1;
