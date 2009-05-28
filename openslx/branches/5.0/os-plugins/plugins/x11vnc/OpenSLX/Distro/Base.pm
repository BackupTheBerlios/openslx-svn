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
# x11vnc/OpenSLX/Distro/Base.pm
#    - provides base implementation of the Distro API for the x11vnc plugin.
# -----------------------------------------------------------------------------
package x11vnc::OpenSLX::Distro::Base;

use strict;
use warnings;

our $VERSION = 1.01;        # API-version . implementation-version

use File::Basename;

use OpenSLX::Basics;
use OpenSLX::Utils;

################################################################################
### interface methods
################################################################################
sub new
{
    my $class = shift;
    my $self = {};
    return bless $self, $class;
}

sub initialize
{
    my $self = shift;
    $self->{engine} = shift;

    return 1;
}

sub fillRunlevelScript
{
    my $self     = shift;

    my $script = unshiftHereDoc(<<"    End-of-Here");
        #! /bin/sh
        # completely generic start/stop script, generated via stage1 'x11vnc' plugin
        # install
        #
        # This script manages the services needed to run x11vnc software

        # Basic support for the Linux Standard Base Specification 1.3
        ### BEGIN INIT INFO
        # Provides: x11vnc
        # Required-Start:
        # Required-Stop:
        # Default-Start: 
        # Default-Stop: 
        # Short-Description: Manages the services needed to run x11vnc software
        # Description: Manages the services needed to run x11vnc software
        ### END INIT INFO

        [ -f /opt/openslx/plugin-repo/x11vnc/x11vnc-init ] \\
          && CMD="/opt/openslx/plugin-repo/x11vnc/x11vnc-init"

        case \$1 in
          start)
            echo "Starting x11vnc ..."
            \$CMD start
          ;;
          stop)
            # message output should match the given vendor-os
            echo "Stopping x11vnc ..."
            \$CMD stop
          ;;
          #status)
          #  echo "Say something useful here ..."
          #;;
          restart)
            "\$0" stop
            "\$0" start
          ;;
        esac
        exit 0
    End-of-Here
    return $script;
}

1;
