#!/bin/bash
#
# This script is a filter for the xml-files available
# 
# currently: 
#     - filter for slxgrp (which comes from /etc/machine-setup)
#


if [ -f /opt/openslx/plugin-repo/vmchooser/stage3.conf ]; then
  . /opt/openslx/plugin-repo/vmchooser/stage3.conf
fi

if [ -n ${env} ]; then
  for FILE in $1/*.xml
  do
    # filter all xmls with pool-param not equal to slxgroup
    if [ `grep "<pools param=\".*${env}.*\"" $FILE | wc -l` -eq 1 ]; then
      echo $FILE;
    fi
  done
else
  # if there is no pool set, just take all available xmls
  ls -1 $1/*.xml
fi
