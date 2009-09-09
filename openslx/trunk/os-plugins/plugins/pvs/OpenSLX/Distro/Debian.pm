# Copyright (c) 2009 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your suggestions, praise, or complaints to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org/
# -----------------------------------------------------------------------------
# pvs/OpenSLX/Distro/debian.pm
#    - provides Debian-specific overrides of the Distro API for the pvs 
#      plugin.
# -----------------------------------------------------------------------------
package pvs::OpenSLX::Distro::Debian;

use strict;
use warnings;

use base qw(pvs::OpenSLX::Distro::Base);

use OpenSLX::Basics;
use OpenSLX::Utils;

################################################################################
### interface methods
################################################################################

1;
