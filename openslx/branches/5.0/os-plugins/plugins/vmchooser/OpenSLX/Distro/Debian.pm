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
# vmchooser/OpenSLX/Distro/Debian.pm
#    - provides Debian implementation of the Distro API for the vmchooser plugin.
# -----------------------------------------------------------------------------
package vmchooser::OpenSLX::Distro::Debian;

use strict;
use warnings;

our $VERSION = 1.01;        # API-version . implementation-version

use base qw(vmchooser::OpenSLX::Distro::Base);

use File::Basename;
use File::Path;
use Scalar::Util qw( weaken );

use OpenSLX::Basics;
use OpenSLX::Utils;

################################################################################
### interface methods
################################################################################

sub copyDefaultSession
{
	my $self 	= shift;
	my $pluginroot = shift;
	
	
	# Take the default path of SuSE 
	# (as we have the most experience with it)
	if( -f "/usr/share/xsessions/default.desktop") {
        rename("/usr/share/xsessions/default.desktop",
              "/usr/share/xsessions/default.desktop.back")
    }
	copyFile("$pluginroot/default.desktop","/usr/share/xsessions");
	
	return 1;
}