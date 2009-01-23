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
# displaymanager.pm
#	- implementation of the 'displaymanager' plugin, which installs  
#     all needed information for a displaymanager. Further possibilities:
#		change xdmcp to (gdm, kdm, ...)
#		change theme for this xdmcp
# -----------------------------------------------------------------------------
package OpenSLX::OSPlugin::displaymanager;

use strict;
use warnings;

use base qw(OpenSLX::OSPlugin::Base);

use OpenSLX::Basics;
use OpenSLX::Utils;

sub new
{
	my $class = shift;

	my $self = {
		name => 'displaymanager',
	};

	return bless $self, $class;
}

sub getInfo
{
	my $self = shift;

	return {
		description => unshiftHereDoc(<<'		End-of-Here'),
			Sets a displaymanager and creates needed configs, theme can be set as well.
		End-of-Here
		mustRunAfter => [],
	};
}

sub getAttrInfo
{
	my $self = shift;

	return {
		'displaymanager::active' => {
			applies_to_systems => 1,
			applies_to_clients => 0,
			description => unshiftHereDoc(<<'			End-of-Here'),
				should the 'displaymanager'-plugin be executed during boot?
			End-of-Here
			content_regex => qr{^(0|1)$},
			content_descr => '1 means active - 0 means inactive',
			default => '1',
		},
		'displaymanager::precedence' => {
			applies_to_systems => 1,
			applies_to_clients => 0,
			description => unshiftHereDoc(<<'			End-of-Here'),
				the execution precedence of the 'displaymanager' plugin
			End-of-Here
			content_regex => qr{^\d\d$},
			content_descr => 'allowed range is from 01-99',
			default => 40,
		},
		'displaymanager::xdmcp' => {
			applies_to_systems => 1,
			applies_to_clients => 0,
			description => unshiftHereDoc(<<'			End-of-Here'),
				which xdmcp to configure, gdm, kdm, xdm?)
			End-of-Here
			content_regex => qr{^(g|k|x)dm$},
			content_descr => 'allowed: gdm, kdm, xdm',
			default => 'xdm',
		},
		'displaymanager::theme' => {
			applies_to_systems => 1,
			applies_to_clients => 0,
			description => unshiftHereDoc(<<'			End-of-Here'),
				name of the theme to apply to the displaymanager (unset for no theme)
			End-of-Here
			content_regex => undef,
			content_descr => undef,
			default => 'openslx',
		},
	};
}

sub copyRequiredFilesIntoInitramfs
{
	my $self                = shift;
	my $targetPath          = shift;
	my $attrs		= shift;
	my $makeInitRamFSEngine = shift;
	
	my $themeDir = "$openslxConfig{'base-path'}/share/themes";
        my $displaymanagerXdmcp = $attrs->{'displaymanager::xdmcp'} || '';
	my $xdmcpConfigDir = "$openslxConfig{'base-path'}/lib/plugins/displaymanager/files/$displaymanagerXdmcp";
	my $displaymanagerTheme = $attrs->{'displaymanager::theme'} || '';
	if ($displaymanagerTheme) {
		my $displaymanagerThemeDir 
			= "$themeDir/$displaymanagerTheme/displaymanager/$displaymanagerXdmcp";
		if (-d $displaymanagerThemeDir) {
                        $makeInitRamFSEngine->addCMD(
                                "mkdir -p $targetPath/usr/share/files"
                        );
			$makeInitRamFSEngine->addCMD(
				"mkdir -p $targetPath/usr/share/themes"
			);
			$makeInitRamFSEngine->addCMD(
				"cp -a $displaymanagerThemeDir $targetPath/usr/share/themes/"
			);
                        $makeInitRamFSEngine->addCMD(
                                "cp -a $xdmcpConfigDir $targetPath/usr/share/files"
                        );
		}
	}
	else {
		$displaymanagerTheme = '<none>';
	}

	vlog(
		1, 
		_tr(
			"displaymanager-plugin: displaymanager=%s", 
			$displaymanagerTheme
		)
	);

	return;
}

1;
