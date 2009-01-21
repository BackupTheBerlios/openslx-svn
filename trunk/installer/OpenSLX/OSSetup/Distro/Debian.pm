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
# Debian.pm
#	- provides Debian-specific overrides of the OpenSLX OSSetup API.
# -----------------------------------------------------------------------------
package OpenSLX::OSSetup::Distro::Debian;

use strict;
use warnings;

use base qw(OpenSLX::OSSetup::Distro::Base);

use OpenSLX::Basics;
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
	my $self = shift;
	my $engine = shift;

	$self->SUPER::initialize($engine);
	$self->{'packager-type'}       = 'dpkg';
	$self->{'meta-packager-type'}  = $ENV{SLX_META_PACKAGER} || 'apt';
	$self->{'stage1c-faked-files'} = [];
	return;
}

sub preSystemInstallationHook
{
	my $self = shift;
	
	$self->SUPER::preSystemInstallationHook();

	# fake required /dev-entries
	my %devInfo = (
		mem     => { type => 'c', major => '1', minor =>  '1' },
		null    => { type => 'c', major => '1', minor =>  '3' },
		zero    => { type => 'c', major => '1', minor =>  '5' },
		random  => { type => 'c', major => '1', minor =>  '8' },
		urandom => { type => 'c', major => '1', minor =>  '9' },
		kmsg    => { type => 'c', major => '1', minor => '11' },
		console => { type => 'c', major => '5', minor =>  '1' },
		ptmx    => { type => 'c', major => '5', minor =>  '2' },
	);
	foreach my $dev (keys %devInfo) {
		my $info = $devInfo{$dev};
		if (!-e "/dev/$dev") {
			if (slxsystem(
				"mknod /dev/$dev $info->{type} $info->{major} $info->{minor}"
			)) {
				croak(_tr("unable to create dev-node '%s'! (%s)", $dev, $!));
			}
		}
	}
	foreach my $devDir ('pts', 'shm', '.udevdb', '.udev') {
		if (!-e "/dev/$devDir") {
			if (slxsystem("mkdir -p /dev/$devDir")) {
				croak(_tr("unable to create dev-dir '%s'! (%s)", $devDir, $!));
			}
		}
	}

	# replace /usr/sbin/invoke-rc.d by a dummy, in order to avoid a whole lot
	# of initscripts being started. Wishful thinking: there should be another
	# way to stop Ubuntu from doing this, as this is not really very supportive
	# of folder-based installations ...
	rename('/usr/sbin/invoke-rc.d', '/usr/sbin/_invoke-rc.d');
	spitFile('/usr/sbin/invoke-rc.d', "#! /bin/sh\nexit 0\n");
	chmod 0755, '/usr/sbin/invoke-rc.d';
}

sub postSystemInstallationHook
{
	my $self = shift;

	# restore /usr/sbin/invoke-rc.d
	rename('/usr/sbin/_invoke-rc.d', '/usr/sbin/invoke-rc.d');
	$self->SUPER::postSystemInstallationHook();
}

sub setPasswordForUser
{
	my $self = shift;
	my $username = shift;
	my $password = shift;
	
	# activate shadow passwords
	my $activateShadowFunction = sub {
		slxsystem('/sbin/shadowconfig', 'on');
	};
	$self->{engine}->callChrootedFunctionForVendorOS($activateShadowFunction);
	
	# invoke default behaviour
	$self->SUPER::setPasswordForUser($username, $password);
}
	
1;