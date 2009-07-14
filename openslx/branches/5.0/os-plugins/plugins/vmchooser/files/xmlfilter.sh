#!/bin/bash
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
# xmlfilter.sh
#    - This script is invoked by the vmchooser tool. It simply filters xml-
#      files (taking the path to these files in $1). You might modify it in any
#      way to match your needs, e.g. ask some database instead. You can re-
#      implement it in any other programming language too. You simply have to
#      return a list of proper xml files to be interpreted by the vmchooser
#      binary). Please check for vmchooser.sh too ...
# -----------------------------------------------------------------------------

# This script .
#
# currently:
#     - filter for slxgrp (which comes from /etc/machine-setup)
#

if [ -f /etc/opt/openslx/vmchooser-stage3.conf ]; then
  . /etc/opt/openslx/vmchooser-stage3.conf
fi

for FILE in $1/*.xml; do
  # filter all xmls which aren't set active
  if [ $(grep "<active param=.*true.*" ${FILE} | wc -l) -eq 1 ]; then
    if [ -n ${vmchooser_env} ]; then
      # filter all xmls with pool-param not equal to vmchooser::env
      if [ $(grep "<pools param=\"${vmchooser_env}\"" ${FILE} | wc -l) -eq 1 ]; then
        echo ${FILE};
      fi
    else
      # if there is no pool set, just take all available xmls
      echo -e ${active}
    fi
  fi
done
