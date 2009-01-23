#!/bin/bash
# Copyright (c) 2008 - Rechenzentrum Uni Freiburg, OpenSLX GmbH
#
# This script simply filters xml-files (taking the path to these files in $1). # You might modify it in any way to match your needs, e.g. ask some database
# instead. You can re-implement it in any other programming language too. You
# simply have to return a list of proper xml files to be interpreted by the
# vmchooser binary).
#
# currently:
#     - filter for slxgrp (which comes from /etc/machine-setup)
#

if [ -f /etc/opt/openslx/vmchooser-stage3.conf ]; then
  . /etc/opt/openslx/vmchooser-stage3.conf
fi

if [ -n ${vmchooser_env} ]; then
  for FILE in $1/*.xml
  do
    # filter all xmls with pool-param not equal to slxgroup
    if [ $(grep "<pools param=\".*${vmchooser_env}.*\"" ${FILE} | wc -l) -eq 1 ]; then
      echo ${FILE};
    fi
  done
else
  # if there is no pool set, just take all available xmls
  ls -1 $1/*.xml
fi
