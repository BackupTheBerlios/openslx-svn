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
# x11vnc/OpenSLX/Distro/Suse.pm
#    - provides SUSE-specific overrides of the Distro API for the x11vnc plugin.
# -----------------------------------------------------------------------------
package x11vnc::OpenSLX::Distro::Suse;

use strict;
use warnings;

use base qw(x11vnc::OpenSLX::Distro::Base);

use OpenSLX::Basics;
use OpenSLX::Utils;

################################################################################
### interface methods
################################################################################

sub fillRunlevelScript
{
    my $self     = shift;

    my $script = unshiftHereDoc(<<"    End-of-Here");
        #!/bin/sh
        # SuSE compatible start/stop script, generated via stage1 'x11vnc' plugin
        # installation
        #
        # inspiration taken from x11vnc start script:
        #   Copyright 1998-2007 x11vnc, Inc.  All rights reserved.
        #
        # This script manages the services needed to run x11vnc software
        
        # Basic support for the Linux Standard Base Specification 1.3
        ### BEGIN INIT INFO
        # Provides: x11vnc
        # Required-Start: \$syslog
        # Required-Stop:
        # Default-Start: 2 3 5
        # Default-Stop: 0 6
        # Short-Description: Manages the services needed to run x11vnc software
        # Description: Manages the services needed to run x11vnc software
        ### END INIT INFO

        # load the helper stuff
        . /etc/rc.status
        # reset the script status
        rc_reset
    
        [ -f /opt/openslx/plugin-repo/x11vnc/x11vnc-init ] \\
          && CMD="/opt/openslx/plugin-repo/x11vnc/x11vnc-init"

        case \$1 in
          start)
            echo -n "Starting x11vnc background services ..."
            \$CMD start
            rc_status -v
          ;;
          stop)
            # message output should match the given vendor-os
            echo -n "Stopping x11vnc background services ..."
            rc_reset
            \$CMD stop
            rc_status -v
          ;;
          #status)
          #  echo -n "Say something useful here ..."
          #;;
          restart)
            "\$0" stop
            "\$0" start
          ;;
          *)
            echo "Usage: `basename "\$0"` {start|stop|restart}"
            exit 1
         ;;
        esac
        exit 0
    End-of-Here
    return $script;
}

1;
