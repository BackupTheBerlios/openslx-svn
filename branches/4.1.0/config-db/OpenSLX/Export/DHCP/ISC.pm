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
# ISC.pm
#	- provides ISC-specific implementation of DHCP export.
# -----------------------------------------------------------------------------
package OpenSLX::Export::DHCP::ISC;

use strict;
use warnings;

our $VERSION = 1.01;		# API-version . implementation-version

################################################################################
### This class provides an ISC specific implementation for DHCP export.
################################################################################
use OpenSLX::Basics;

################################################################################
### implementation
################################################################################
sub new
{
	my $class = shift;
	my $self = {};
	return bless $self, $class;
}

sub execute
{
	my $self = shift;
	my $clients = shift;

	vlog(1, _tr("writing dhcp-config for %s clients", scalar(@$clients)));
	foreach my $client (@$clients) {
print "ISC-DHCP: $client->{name}\n";
	}
}

1;