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
# x11vnc.pm
# -----------------------------------------------------------------------------
package OpenSLX::OSPlugin::x11vnc;

use strict;
use warnings;

use base qw(OpenSLX::OSPlugin::Base);

use OpenSLX::Basics;
use OpenSLX::Utils;

sub new
{
	my $class = shift;
	my $self = {
		name => 'x11vnc',
	};

	return bless $self, $class;
}

sub getInfo
{
	my $self = shift;
	return {
		description => unshiftHereDoc(<<'		End-of-Here'),
			enables x11vnc server
		End-of-Here
		mustRunAfter => [],
	};
}

sub getAttrInfo
{
	my $self = shift;

	return {
		'x11vnc::active' => {
			applies_to_systems => 1,
			applies_to_clients => 0,
			description => unshiftHereDoc(<<'			End-of-Here'),
				should the 'x11vnc' plugin be executed during boot?
			End-of-Here
			content_regex => qr{^(0|1)$},
			content_descr => '1 means active - 0 means inactive',
			default => '1',
		},

		'x11vnc::precedence' => {
			applies_to_systems => 1,
			applies_to_clients => 0,
			description => unshiftHereDoc(<<'			End-of-Here'),
				the execution precedence of the 'x11vnc' plugin
			End-of-Here
			content_regex => qr{^\d\d$},
			content_descr => 'allowed range is from 01-99',
			default => 50,
		},

		'x11vnc::mode' => {
			applies_to_systems => 1,
			applies_to_clients => 0,
			description => unshiftHereDoc(<<'			End-of-Here'),
				set x11vnc to listen on X11(default) or console fb
			End-of-Here
			content_regex => qr{^(x11|fb)$},
			content_descr => 'x11 means listen current X session - fb means listen to tty1 console',
			default => 'x11',
		},

		'x11vnc::scale' => {
			applies_to_systems => 1,
			applies_to_clients => 0,
			description => unshiftHereDoc(<<'			End-of-Here'),
				scale screen size (e.g. as fraction 2/3 or as decimal 0.5)
			End-of-Here
			content_regex => undef,
			content_descr => undef,
			default => '',
		},

		'x11vnc::shared' => {
			applies_to_systems => 1,
			applies_to_clients => 0,
			description => unshiftHereDoc(<<'			End-of-Here'),
				by default x11vnc is always called with the -shared option
			End-of-Here
			content_regex => qr{^(yes|no|1|0)$},
			content_descr => 'use 1 or yes to enable - 0 or no to disable',
			default => 'yes',
		},

		'x11vnc::force_viewonly' => {
			applies_to_systems => 1,
			applies_to_clients => 0,
			description => unshiftHereDoc(<<'			End-of-Here'),
				disable user interaction with vnc
			End-of-Here
			content_regex => qr{^(yes|no|1|0)$},
			content_descr => 'use 1 or yes to enable - 0 or no to disable',
			default => 'no',
		},

		'x11vnc::auth_type' => {
			applies_to_systems => 1,
			applies_to_clients => 0,
			description => unshiftHereDoc(<<'			End-of-Here'),
				set authentication type of the vnc connection
			End-of-Here
			content_regex => qr{^(passwd|rfbauth|none)$},
			content_descr => 'choose: passwd, rfbauth, none',
			default => 'passwd',
		},

		'x11vnc::allowed_hosts' => {
			applies_to_systems => 1,
			applies_to_clients => 0,
			description => unshiftHereDoc(<<'			End-of-Here'),
				set allowed hosts (multiple hosts are seperated by semicolons, (simple) subnets are possible too
				e.g. "192.168.")
			End-of-Here
			content_regex => undef,
			content_descr => undef,
			default => '',
		},

		'x11vnc::force_localhost' => {
			applies_to_systems => 1,
			applies_to_clients => 0,
			description => unshiftHereDoc(<<'			End-of-Here'),
				force x11vnc to only accept local connections and only listen on the loopback device
			End-of-Here
			content_regex => qr{^(1|0|yes|no)$},
			content_descr => 'use 1 or yes to enable - 0 or no to disable',
			default => 'no',
		},

		'x11vnc::pass' => {
			applies_to_systems => 1,
			applies_to_clients => 0,
			description => unshiftHereDoc(<<'			End-of-Here'),
				viewonly password (you can add multiple passwords seperated by semicolons)
				(if you're using rfb-auth only the first one is used)
			End-of-Here
			content_regex => undef,
			content_descr => undef,
			default => '',
		},

		'x11vnc::viewonlypass' => {
			applies_to_systems => 1,
			applies_to_clients => 0,
			description => unshiftHereDoc(<<'			End-of-Here'),
				viewonly password (you can add multiple passwords seperated by semicolons)
				(disabled with rfb-auth)
			End-of-Here
			content_regex => undef,
			content_descr => undef,
			default => 'viewonly',
		},

		'x11vnc::logging' => {
			applies_to_systems => 1,
			applies_to_clients => 0,
			description => unshiftHereDoc(<<'			End-of-Here'),
				enable logging
			End-of-Here
			content_regex => qr{^(1|0|yes|no)$},
			content_descr => 'use 1 or yes to enable - 0 or no to disable',
			default => 'yes',
		},
		
	};
}

sub installationPhase
{
	my $self = shift;
	my $pluginRepositoryPath = shift;
	my $pluginTempPath = shift;
	my $openslxPath = shift;

	# get path of files we need to install
	my $pluginFilesPath = "$openslxPath/lib/plugins/$self->{'name'}/files";

	# copy all needed files now
	copyFile("$pluginFilesPath/x11vnc", "/etc/init.d");
	vlog(3, "install init file");

	if ( !-x "/usr/bin/x11vnc" ) {
	  # let's install x11vnc
	  if ( $self->{'os-plugin-engine'}->{'vendor-os-name'} =~ m/(debian|ubuntu)/i ) {
	    my $cmd = "aptitude -y install x11vnc";
	    vlog(3, "executing: $cmd");
	    if (slxsystem($cmd)) {
	      die _tr(
	        "unable to execute shell-cmd\n\t%s", $cmd
	      );
	    }
	  }
	  if ( $self->{'os-plugin-engine'}->{'vendor-os-name'} =~ m/suse/i ) {
	   # PLEASE TEST THIS!!!
	    my $cmd = "yast --install x11vnc";
	    vlog(3, "executing: $cmd");
	    if (slxsystem($cmd)) {
	      die _tr(
	        "unable to execute shell-cmd\n\t%s", $cmd
	      );
	    }
	  }
	} else {
	  vlog(3, "x11vnc is already installed");
	}

}

sub removalPhase
{
	my $self = shift;
	my $pluginRepositoryPath = shift;
	my $pluginTempPath = shift;
}

1;
