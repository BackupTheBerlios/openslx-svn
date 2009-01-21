# ISC.pm - provides ISC-specific implementation of DHCP export.
#
# (c) 2006 - OpenSLX.com
#
# Oliver Tappe <ot@openslx.com>
#
package OpenSLX::Export::DHCP::ISC;

use vars qw(@ISA $VERSION);
$VERSION = 1.01;		# API-version . implementation-version

################################################################################
### This class provides an ISC specific implementation for DHCP export.
################################################################################
use strict;
use Carp;
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

	vlog 1, _tr("writing dhcp-config for %s clients", scalar(@$clients));
	foreach my $client (@$clients) {
print "ISC-DHCP: $client->{name}\n";
	}
}