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
# x11vnc/OpenSLX/Distro/debian.pm
#    - provides Debian-specific overrides of the Distro API for the x11vnc 
#      plugin.
# -----------------------------------------------------------------------------
package x11vnc::OpenSLX::Distro::Debian;

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
        # Ubuntu/Debian specific start/stop script, generated via stage1 'x11vnc'
        # plugin install
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
 
        # initialize the lsb status messages
        . /lib/lsb/init-functions

        [ -f /opt/openslx/plugin-repo/x11vnc/x11vnc-init ] \\
          && CMD="/opt/openslx/plugin-repo/x11vnc/x11vnc-init"

        case \$1 in
          start)
            log_daemon_msg "Starting x11vnc background services ..." "x11vnc"
            \$CMD start
            log_end_msg \$?
          ;;
          stop)
            log_daemon_msg "Stopping x11vnc background services ..." "x11vnc"
            \$CMD stop
            log_end_msg \$?
          ;;
          #status)
          #  log_daemon_msg "Say something useful here ..."
          #;;
          restart)
            \$0 stop
            \$0 start
            exit $?
          ;;
          *)
           log_success_msg "Usage: \$0 {start|stop|restart}"
            exit 2
          ;;
        esac
        exit 0
    End-of-Here
    return $script;
}

1;
