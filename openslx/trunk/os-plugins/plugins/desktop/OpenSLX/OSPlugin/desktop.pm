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
# desktop.pm
#	- implementation of the 'desktop' plugin, which installs  
#     all needed information for a displaymanager and for the desktop. 
# -----------------------------------------------------------------------------
package OpenSLX::OSPlugin::desktop;

use strict;
use warnings;

use base qw(OpenSLX::OSPlugin::Base);

use File::Basename;
use File::Path;

use OpenSLX::Basics;
use OpenSLX::Utils;

sub new
{
	my $class = shift;

	my $self = {
		name => 'desktop',
	};

	return bless $self, $class;
}

sub getInfo
{
	my $self = shift;

	return {
		description => unshiftHereDoc(<<'		End-of-Here'),
			Sets a desktop and creates needed configs, theme can be set as well.
		End-of-Here
		mustRunAfter => [],
	};
}

sub getAttrInfo
{
	my $self = shift;

	return {
		'desktop::active' => {
			applies_to_systems => 1,
			applies_to_clients => 1,
			description => unshiftHereDoc(<<'			End-of-Here'),
				should the 'desktop'-plugin be executed during boot?
			End-of-Here
			content_regex => qr{^(0|1)$},
			content_descr => '1 means active - 0 means inactive',
			default => '1',
		},
		'desktop::precedence' => {
			applies_to_systems => 1,
			applies_to_clients => 1,
			description => unshiftHereDoc(<<'			End-of-Here'),
				the execution precedence of the 'desktop' plugin
			End-of-Here
			content_regex => qr{^\d\d$},
			content_descr => 'allowed range is from 01-99',
			default => 40,
		},
		'desktop::manager' => {
			applies_to_systems => 1,
			applies_to_clients => 1,
			description => unshiftHereDoc(<<'			End-of-Here'),
				which display manager to start: gdm, kdm, xdm?)
			End-of-Here
			content_regex => qr{^(g|k|x)dm$},
			content_descr => 'allowed: gdm, kdm, xdm',
			default => undef,
		},
		'desktop::kind' => {
			applies_to_systems => 1,
			applies_to_clients => 1,
			description => unshiftHereDoc(<<'			End-of-Here'),
				which desktop environment shall be used: gnome, kde, xfce, ...)
			End-of-Here
			content_regex => undef,
			content_descr => 'allowed: gnome, kde, xfce',
			default => undef,
		},
		'desktop::mode' => {
			applies_to_systems => 1,
			applies_to_clients => 1,
			description => unshiftHereDoc(<<'			End-of-Here'),
				which type of operation mode: kiosk, workstation, remote-desktop, ...?)
			End-of-Here
			content_regex => undef,
			content_descr => 'allowed: ...',
			default => 'workstation',
		},
		'desktop::theme' => {
			applies_to_systems => 1,
			description => unshiftHereDoc(<<'			End-of-Here'),
				name of the theme to apply to the desktop (unset for no theme)
			End-of-Here
			content_regex => undef,
			content_descr => undef,
			default => 'openslx',
		},
		'desktop::gdm' => {
			applies_to_vendor_os => 1,
			description => unshiftHereDoc(<<'			End-of-Here'),
				should gdm be available (installed in vendor-OS)?
			End-of-Here
			content_regex => undef,
			content_descr => '1 or 0',
			default => undef,
		},
		'desktop::kdm' => {
			applies_to_vendor_os => 1,
			description => unshiftHereDoc(<<'			End-of-Here'),
				should kdm be available (installed in vendor-OS)?
			End-of-Here
			content_regex => undef,
			content_descr => '1 or 0',
			default => undef,
		},
		'desktop::xdm' => {
			applies_to_vendor_os => 1,
			description => unshiftHereDoc(<<'			End-of-Here'),
				should xdm be available (installed in vendor-OS)?
			End-of-Here
			content_regex => undef,
			content_descr => '1 or 0',
			default => undef,
		},
		'desktop::gnome' => {
			applies_to_vendor_os => 1,
			description => unshiftHereDoc(<<'			End-of-Here'),
				should gnome be available (installed in vendor-OS)?
			End-of-Here
			content_regex => undef,
			content_descr => '1 or 0',
			default => undef,
		},
		'desktop::kde' => {
			applies_to_vendor_os => 1,
			description => unshiftHereDoc(<<'			End-of-Here'),
				should kde be available (installed in vendor-OS)?
			End-of-Here
			content_regex => undef,
			content_descr => '1 or 0',
			default => undef,
		},
		'desktop::xfce' => {
			applies_to_vendor_os => 1,
			description => unshiftHereDoc(<<'			End-of-Here'),
				should xfce be available (installed in vendor-OS)?
			End-of-Here
			content_regex => undef,
			content_descr => '1 or 0',
			default => undef,
		},
	};
}

sub getDefaultAttrsForVendorOS
{
	my $self         = shift;
	my $vendorOSName = shift;

	my $attrs = $self->getAttrInfo();
	
	if ($vendorOSName =~ m{kde$}) {
		$attrs->{'desktop::manager'}->{default} = 'kdm';
		$attrs->{'desktop::kind'}->{default} = 'kde';
	}
	elsif ($vendorOSName =~ m{gnome$}) {
		$attrs->{'desktop::manager'}->{default} = 'gdm';
		$attrs->{'desktop::kind'}->{default} = 'gnome';
	}
	elsif ($vendorOSName =~ m{xfce$}) {
		$attrs->{'desktop::manager'}->{default} = 'xdm';
		$attrs->{'desktop::kind'}->{default} = 'xcfe';
	}
	else {
		# TODO: chroot into vendor-OS and determine the available desktop
	}
	return $attrs;
}

sub installationPhase
{
	my $self = shift;
	
	$self->{pluginRepositoryPath} = shift;
	$self->{pluginTempPath}       = shift;
	$self->{openslxPath}          = shift;
	$self->{attrs}                = shift;
	
	$self->_installRequiredPackages();
	$self->_determineAttrsByInstalledPackages();

use Data::Dumper; print Dumper $self->{attrs};

	if ($self->{attrs}->{'desktop::gdm'}) {
		$self->_setupGDM();
	}
	if ($self->{attrs}->{'desktop::kdm'}) {
		$self->_setupKDM();
	}
	if ($self->{attrs}->{'desktop::xdm'}) {
		$self->_setupXDM();
	}

	return;
}

sub removalPhase
{
	my $self = shift;
	my $pluginRepositoryPath = shift;
	my $pluginTempPath = shift;

	return;
}

sub copyRequiredFilesIntoInitramfs
{
	my $self                = shift;
	my $targetPath          = shift;
	my $attrs               = shift;
	my $makeInitRamFSEngine = shift;
	
	my $themeDir = "$openslxConfig{'base-path'}/share/themes";
        my $desktopXdmcp = $attrs->{'desktop::xdmcp'} || '';
	my $xdmcpConfigDir = "$openslxConfig{'base-path'}/lib/plugins/desktop/files/$desktopXdmcp";
	my $desktopTheme = $attrs->{'desktop::theme'} || '';
	if ($desktopTheme) {
		my $desktopThemeDir 
			= "$themeDir/$desktopTheme/desktop/$desktopXdmcp";
		if (-d $desktopThemeDir) {
                        $makeInitRamFSEngine->addCMD(
                                "mkdir -p $targetPath/usr/share/files"
                        );
			$makeInitRamFSEngine->addCMD(
				"mkdir -p $targetPath/usr/share/themes"
			);
			$makeInitRamFSEngine->addCMD(
				"cp -a $desktopThemeDir $targetPath/usr/share/themes/"
			);
                        $makeInitRamFSEngine->addCMD(
                                "cp -a $xdmcpConfigDir $targetPath/usr/share/files"
                        );
		}
	}
	else {
		$desktopTheme = '<none>';
	}

	vlog(
		1, 
		_tr(
			"desktop-plugin: desktop=%s", 
			$desktopTheme
		)
	);

	return;
}

sub _installRequiredPackages
{
	my $self  = shift;

	my $engine = $self->{'os-plugin-engine'};
	
	for my $desktop (qw( gnome kde xfce )) {
		next if !$self->{attrs}->{"desktop::$desktop"};
		my $packages = $engine->getPackagesForSelection($desktop);
		$engine->installPackages($packages);
	}
	
	for my $dm (qw( gdm kdm xdm )) {
		next if !$self->{attrs}->{"desktop::$dm"};
		$engine->installPackages($dm);
	}

	return 1;
}

sub _determineAttrsByInstalledPackages
{
	my $self  = shift;
	my $attrs = shift;
	
	if (!defined $attrs->{'desktop::gnome'}) {
		$attrs->{'desktop::gnome'} = $self->{distro}->isGNOMEInstalled();
	}
	if (!defined $attrs->{'desktop::gdm'}) {
		$attrs->{'desktop::gdm'} = $self->{distro}->isGDMInstalled();
	}
	if (!defined $attrs->{'desktop::kde'}) {
		$attrs->{'desktop::kde'} = $self->{distro}->isKDEInstalled();
	}
	if (!defined $attrs->{'desktop::kdm'}) {
		$attrs->{'desktop::kdm'} = $self->{distro}->isKDMInstalled();
	}
	if (!defined $attrs->{'desktop::xfce'}) {
		$attrs->{'desktop::xfde'} = $self->{distro}->isXFCEInstalled();
	}
	if (!defined $attrs->{'desktop::xdm'}) {
		$attrs->{'desktop::xdm'} = $self->{distro}->isXDMInstalled();
	}

	return 1;
}

sub _setupGDM
{
	my $self = shift;
	my $attrs = shift;
	
	my $repoPath = $self->{pluginRepositoryPath};
	mkpath([ "$repoPath/gdm" ]);
	
	my $pathInfo   = $self->{distro}->GDMPathInfo();
	$self->_setupGDMScript($pathInfo);

	my $configHash = $self->{distro}->GDMConfigHashForWorkstation();
	$self->_writeConfigHash($configHash, "$repoPath/gdm/workstation/gdm.conf");
	
	$configHash = $self->{distro}->GDMConfigHashForKiosk();
	$self->_writeConfigHash($configHash, "$repoPath/gdm/kiosk/gdm.conf");

	$configHash = $self->{distro}->GDMConfigHashForChooser();
	$self->_writeConfigHash($configHash, "$repoPath/gdm/chooser/gdm.conf");

	return;	
}

sub _setupGDMScript
{
	my $self = shift;
	my $pathInfo = shift;
	
	my $repoPath = $self->{pluginRepositoryPath};
	my $configFile = $pathInfo->{config};
	my $paths = join(' ', ( dirname($configFile), @{$pathInfo->{paths}} ));
	my $script = unshiftHereDoc(<<"	End-of-Here");
		#!/bin/ash
		# written by OpenSLX-plugin 'desktop'
		mkdir -p $paths
		ln -sf /mnt$repoPath/gdm/\$desktop_kind/gdm.conf $configFile
	End-of-Here
	spitFile("$repoPath/gdm/desktop.sh", $script);
	return;
}

sub _setupKDM
{
	my $self = shift;
	my $attrs = shift;
	
}

sub _setupXDM
{
	my $self = shift;
	my $attrs = shift;
}

sub _writeConfigHash
{
	my $self = shift;
	my $hash = shift || {};
	my $file = shift;
	
	my $content = '';
	for my $domain (sort keys %$hash) {
		$content .= "[$domain]\n";
		for my $key (sort keys %{$hash->{$domain}}) {
			my $value 
				= defined $hash->{$domain}->{$key} 
					? $hash->{$domain}->{$key}
					: '';
			$content .= "$key=$value\n";
		}
	}
	spitFile($file, $content);
}

1;
