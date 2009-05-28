#!/bin/sh

cd /opt/openslx/plugin-repo/xserver

DISTRO=$1
case $DISTRO in

  ubuntu-9.04*)
    ./ubuntu-8.10-gfx-install.sh ati ${DISTRO}
  
  ;;
  ubuntu-8.10*)
    ./ubuntu-8.10-gfx-install.sh ati ${DISTRO}
  
  ;;
  ubuntu-*)
    ./ubuntu-gfx-install.sh ati ${DISTRO}
  ;;

  suse-*)
    ./suse-gfx-install.sh ati ${DISTRO}
  ;;
esac
