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
# theme.pm
#	- implementation of the 'theme' plugin, which applies theming to the 
#     following places:
#		+ bootsplash (via splashy)
#		+ displaymanager (gdm, kdm, ...)
#		+ desktop (to be done)
# -----------------------------------------------------------------------------
package OpenSLX::OSPlugin::theme;

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
			Applies a graphical theme to the bootsplash and the displaymanager.
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
		'theme::active' => {
			applies_to_systems => 1,
			applies_to_clients => 0,
			description => unshiftHereDoc(<<'			End-of-Here'),
				should the 'theme'-plugin be executed during boot?
			End-of-Here
			content_regex => qr{^(0|1)$},
			content_descr => '1 means active - 0 means inactive',
			default => '1',
		},
		# attribute 'precedence' is mandatory for all plugins
		'theme::precedence' => {
			applies_to_systems => 1,
			applies_to_clients => 0,
			description => unshiftHereDoc(<<'			End-of-Here'),
				the execution precedence of the 'theme' plugin
			End-of-Here
			content_regex => qr{^\d\d$},
			content_descr => 'allowed range is from 01-99',
			default => 30,
		},

		'theme::splash' => {
			applies_to_systems => 1,
			applies_to_clients => 0,
			description => unshiftHereDoc(<<'			End-of-Here'),
				name of the theme to apply to bootsplash (unset for no theme)
			End-of-Here
			content_regex => undef,
			content_descr => undef,
			default => 'openslx',
		},
		'theme::displaymanager' => {
			applies_to_systems => 1,
			applies_to_clients => 0,
			description => unshiftHereDoc(<<'			End-of-Here'),
				name of the theme to apply to displaymanager (unset for no theme)
			End-of-Here
			content_regex => undef,
			content_descr => undef,
			default => 'openslx',
		},
		'theme::desktop' => {
			applies_to_systems => 1,
			applies_to_clients => 0,
			description => unshiftHereDoc(<<'			End-of-Here'),
				name of the theme to apply to desktop (unset for no theme)
			End-of-Here
			content_regex => undef,
			content_descr => undef,
			default => 'openslx',
		},
	};
}

sub suggestAdditionalKernelParams
{
	my $self         = shift;
	my $kernelParams = shift;

	my @suggestedParams;
	
	# add vga=0x317 unless explicit vga-mode is already set
	if ($kernelParams !~ m{\bvga=}) {
		vlog(1, "theme-plugin: adding kernel-param vga=0x317");
		push @suggestedParams, 'vga=0x317';
	}

	# add quiet, if not already set
	if ($kernelParams !~ m{\bquiet\b}) {
		vlog(1, "theme-plugin: adding kernel-param quiet");
		push @suggestedParams, 'quiet';
	}

	return @suggestedParams;
}

sub copyRequiredFilesIntoInitramfs
{
	my $self                = shift;
	my $targetPath          = shift;
	my $attrs				= shift;
	my $makeInitRamFSEngine = shift;
	
	my $themeDir = "$openslxConfig{'base-path'}/share/themes";
	my $splashTheme = $attrs->{'theme::splash'} || '';
	if ($splashTheme) {
		my $splashThemeDir = "$themeDir/$splashTheme/bootsplash";
		if (-d $splashThemeDir) {
			my $splashyPath = "$openslxConfig{'base-path'}/share/splashy";
			$makeInitRamFSEngine->addCMD(
				"cp -p $splashyPath/* $targetPath/bin/"
			);
			$makeInitRamFSEngine->addCMD(
				"mkdir -p $targetPath/etc/splashy"
			);
			$makeInitRamFSEngine->addCMD(
				"cp -a $splashThemeDir/* $targetPath/etc/splashy/"
			);
		}
	}
	else {
		$splashTheme = '<none>';
	}

	my $displayManagerTheme = $attrs->{'theme::displaymanager'} || '';
	if ($displayManagerTheme) {
		my $displayManagerThemeDir 
			= "$themeDir/$displayManagerTheme/displaymanager";
		if (-d $displayManagerThemeDir) {
			$makeInitRamFSEngine->addCMD(
				"mkdir -p $targetPath/usr/share/themes"
			);
			$makeInitRamFSEngine->addCMD(
				"cp -a $displayManagerThemeDir $targetPath/usr/share/themes/"
			);
		}
	}
	else {
		$displayManagerTheme = '<none>';
	}

	vlog(
		0, 
		_tr(
			"theme-plugin: bootsplash=%s displaymanager=%s", 
			$splashTheme, $displayManagerTheme
		)
	);

	return;
}

1;
