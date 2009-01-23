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
# debian.pm
#    - provides Debian-specific overrides of the OpenSLX Distro API for the 
#     desktop plugin.
# -----------------------------------------------------------------------------
package OpenSLX::Distro::debian;

use strict;
use warnings;

use base qw(OpenSLX::Distro::Base);

use OpenSLX::Basics;
use OpenSLX::Utils;

################################################################################
### interface methods
################################################################################

1;