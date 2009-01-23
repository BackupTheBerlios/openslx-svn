#!/bin/bash
#
# This script is a filter for the xml-files available
# 
# currently: 
#     - filter for slxgrp (which comes from /etc/machine-setup)
#


if [ -f /etc/machine-setup ]; then
  . /etc/machine-setup
fi

if [ -n $slxgrp ]; then
  for FILE in $1/*.xml
  do
    # filter all xmls with pool-param not equal to slxgroup
    if [ `grep "<pools param=\".*$slxgrp.*\"" $FILE | wc -l` -eq 1 ]; then
      echo $FILE;
    fi
  done
else
  # if there is no pool set, just take all available xmls
  ls -1 $1/*.xml
fi
