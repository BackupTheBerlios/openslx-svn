#!/bin/sh
# -----------------------------------------------------------------------------
# Copyright (c) 2007..2009 - RZ Uni FR
# Copyright (c) 2007..2009 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your suggestions, praise, or complaints to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org/
# -----------------------------------------------------------------------------
# vmchooser.sh
#    - This is a generic wrapper script for the vmchooser tool. If you would 
#      like to apply any filters for the sessions to be shown to the logged in
#      user, you could use a different path to the sessions *.xml's ...
# -----------------------------------------------------------------------------

if [ -e "/etc/opt/openslx/vmchooser-stage3.conf" ]; then
  . /etc/opt/openslx/vmchooser-stage3.conf
fi

/opt/openslx/plugin-repo/vmchooser/vmchooser -p${vmchooser_xmlpath}

