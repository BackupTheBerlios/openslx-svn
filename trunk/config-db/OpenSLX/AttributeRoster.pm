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
# AttributeRoster.pm
#	- provides information about all available attributes
# -----------------------------------------------------------------------------
package OpenSLX::AttributeRoster;

use strict;
use warnings;

use OpenSLX::Basics;
use OpenSLX::OSPlugin::Roster;
use OpenSLX::Utils;

################################################################################
###
### Integrate info about all known attributes (from core and from the plugins)
### into one big hash.
###
################################################################################

# set core attributes
my %AttributeInfo = (
	'automnt_dir' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
		default => '',
	},
	'automnt_src' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
		default => '',
	},
	'country' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
		default => 'de',
	},
	'dm_allow_shutdown' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
		default => 'user',
	},
	'hw_graphic' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
		default => '',
	},
	'hw_monitor' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
		default => '',
	},
	'hw_mouse' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
		default => '',
	},
	'netbios_workgroup' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
		default => 'slx-network',
	},
	'nis_domain' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
		default => '',
	},
	'nis_servers' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
		default => '',
	},
	'ramfs_fsmods' => {
		applies_to_systems => 1,
		applies_to_clients => 0,
		description => unshiftHereDoc(<<'		End-of-Here'),
			list of filesystem kernel modules to load
		End-of-Here
		content_regex => undef,
		content_descr => undef,
		default => '',
	},
	'ramfs_miscmods' => {
		applies_to_systems => 1,
		applies_to_clients => 0,
		description => unshiftHereDoc(<<'		End-of-Here'),
			list of miscellaneous kernel modules to load
		End-of-Here
		content_regex => undef,
		content_descr => undef,
		default => '',
	},
	'ramfs_nicmods' => {
		applies_to_systems => 1,
		applies_to_clients => 0,
		description => unshiftHereDoc(<<'		End-of-Here'),
			list of network card modules to load
		End-of-Here
		content_regex => undef,
		content_descr => undef,
		default => 'forcedeth e1000 e100 tg3 via-rhine r8169 pcnet32',
	},
	'ramfs_screen' => {
		applies_to_systems => 1,
		applies_to_clients => 0,
		description => unshiftHereDoc(<<'		End-of-Here'),
			resolution of splash screen to use in stage3
		End-of-Here
		content_regex => undef,
		content_descr => undef,
		default => '',
	},
	'sane_scanner' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
		default => '',
	},
	'scratch' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
		default => '',
	},
	'slxgrp' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
		default => '',
	},
	'start_alsasound' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
		default => 'yes',
	},
	'start_atd' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
		default => 'no',
	},
	'start_cron' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
		default => 'no',
	},
	'start_dreshal' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
		default => 'yes',
	},
	'start_ntp' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
		default => 'initial',
	},
	'start_nfsv4' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
		default => 'no',
	},
	'start_printer' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
		default => 'no',
	},
	'start_samba' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
		default => 'may',
	},
	'start_snmp' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
		default => 'no',
	},
	'start_sshd' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
		default => 'yes',
	},
	'start_syslogd' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
		default => 'yes',
	},
	'start_x' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
		default => 'yes',
	},
	'start_xdmcp' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
		default => 'kdm',
	},
	'tex_enable' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
		default => 'no',
	},
	'timezone' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			textual timezone (e.g. 'Europe/Berlin')
		End-of-Here
		content_regex => undef,
		content_descr => undef,
		default => 'Europe/Berlin',
	},
	'tvout' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
		default => 'no',
	},
	'vmware' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
		default => 'no',
	},
);

# and add all plugin attributes, too
OpenSLX::OSPlugin::Roster->addAllDefaultAttributesToHash(\%AttributeInfo);

=item C<getAttrInfo()>

Returns info about all attributes.

=over

=item Return Value

An hash-ref with info about all known attributes.

=back

=cut

sub getAttrInfo
{
	my $class = shift;
	my $name  = shift;

	if (defined $name) {
		my $attrInfo = $AttributeInfo{$name};
		return if !defined $attrInfo;
		return { $name => $AttributeInfo{$name} };
	}

	return \%AttributeInfo;
}

=item C<getSystemAttrs()>

Returns the attribute names that apply to systems.

=over

=item Return Value

An array of attribute names.

=back

=cut

sub getSystemAttrs
{
	my $class = shift;

	return 
		grep { $AttributeInfo{$_}->{"applies_to_systems"} }
		keys %AttributeInfo
}

=item C<getClientAttrs()>

Returns the attribute names that apply to clients.

=over

=item Return Value

An array of attribute names.

=back

=cut

sub getClientAttrs
{
	my $class = shift;

	return 
		grep { $AttributeInfo{$_}->{"applies_to_clients"} }
		keys %AttributeInfo
}

1;