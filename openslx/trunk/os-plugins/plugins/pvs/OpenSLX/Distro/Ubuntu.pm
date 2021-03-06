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
# pvs/OpenSLX/Distro/Ubuntu.pm
#    - provides Ubuntu-specific overrides of the Distro API for the pvs
#      plugin.
# -----------------------------------------------------------------------------
package pvs::OpenSLX::Distro::Ubuntu;

use strict;
use warnings;

# inherit everything from Debian (as Ubuntu is based on it anyway)
use base qw(pvs::OpenSLX::Distro::Debian);

1;
