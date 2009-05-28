#!/bin/sh

if [ -e "/etc/opt/openslx/vmchooser-stage3.conf" ]; then
  . /etc/opt/openslx/vmchooser-stage3.conf
fi


/opt/openslx/plugin-repo/vmchooser/vmchooser -p${vmchooser_xmlpath}

