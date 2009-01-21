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
# AttrInfo::Core
#	- provides info about the core attributes.
# -----------------------------------------------------------------------------
package OpenSLX::AttrInfo::Core;

use strict;
use warnings;

use OpenSLX::Utils;

use vars qw(@ISA @EXPORT $VERSION %AttrInfo);

use Exporter;
$VERSION = 1.01;
@ISA     = qw(Exporter);

@EXPORT = qw( %AttrInfo );

%AttrInfo = (
	'automnt_dir' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
	},
	'automnt_src' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
	},
	'country' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
	},
	'dm_allow_shutdown' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
	},
	'hw_graphic' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
	},
	'hw_monitor' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
	},
	'hw_mouse' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
	},
	'late_dm' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
	},
	'netbios_workgroup' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
	},
	'nis_domain' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
	},
	'nis_servers' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
	},
	'sane_scanner' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
	},
	'scratch' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
	},
	'slxgrp' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
	},
	'start_alsasound' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
	},
	'start_atd' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
	},
	'start_cron' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
	},
	'start_dreshal' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
	},
	'start_ntp' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
	},
	'start_nfsv4' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
	},
	'start_printer' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
	},
	'start_samba' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
	},
	'start_snmp' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
	},
	'start_sshd' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
	},
	'start_syslogd' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
	},
	'start_x' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
	},
	'start_xdmcp' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
	},
	'tex_enable' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
	},
	'timezone' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			textual timezone (e.g. 'Europe/Berlin')
		End-of-Here
		content_regex => undef,
		content_descr => undef,
	},
	'tvout' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
	},
	'vmware' => {
		applies_to_systems => 1,
		applies_to_clients => 1,
		description => unshiftHereDoc(<<'		End-of-Here'),
			!!!descriptive text missing here!!!
		End-of-Here
		content_regex => undef,
		content_descr => undef,
	},

	'ramfs_fsmods' => {
		applies_to_systems => 1,
		applies_to_clients => 0,
		description => unshiftHereDoc(<<'		End-of-Here'),
			list of filesystem kernel modules to load
		End-of-Here
		content_regex => undef,
		content_descr => undef,
	},
	'ramfs_miscmods' => {
		applies_to_systems => 1,
		applies_to_clients => 0,
		description => unshiftHereDoc(<<'		End-of-Here'),
			list of miscellaneous kernel modules to load
		End-of-Here
		content_regex => undef,
		content_descr => undef,
	},
	'ramfs_nicmods' => {
		applies_to_systems => 1,
		applies_to_clients => 0,
		description => unshiftHereDoc(<<'		End-of-Here'),
			list of network card modules to load
		End-of-Here
		content_regex => undef,
		content_descr => undef,
	},
	'ramfs_screen' => {
		applies_to_systems => 1,
		applies_to_clients => 0,
		description => unshiftHereDoc(<<'		End-of-Here'),
			resolution of splash screen to use in stage3
		End-of-Here
		content_regex => undef,
		content_descr => undef,
	},
);

1;
