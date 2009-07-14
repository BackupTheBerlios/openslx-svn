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
# vmchooser/OpenSLX/Distro/Suse.pm
#    - provides Suse implementation of the Distro API for the vmchooser plugin.
# -----------------------------------------------------------------------------
package vmchooser::OpenSLX::Distro::Suse;

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
	if( -f "/etc/X11/sessions/default.desktop") {
        rename("/etc/X11/sessions/default.desktop",
              "/etc/X11/sessions/default.desktop.back")
    }
	copyFile("$pluginroot/default.desktop","/etc/X11/sessions");
	
	return 1;
}