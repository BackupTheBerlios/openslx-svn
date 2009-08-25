#!/bin/sh

cd /opt/openslx/plugin-repo/xserver

DISTRO=$1
case $DISTRO in

  ubuntu-9.10*)
    ./ubuntu-ng-gfx-install.sh ati ${DISTRO}
  ;;
  ubuntu-9.04*)
    ./ubuntu-ng-gfx-install.sh ati ${DISTRO}
  ;;
  ubuntu-8.10*)
    ./ubuntu-ng-gfx-install.sh ati ${DISTRO}
  ;;
  ubuntu-*)
    ./ubuntu-gfx-install.sh ati ${DISTRO}
  ;;

  suse-*)
    ./suse-gfx-install.sh ati ${DISTRO}
  ;;
esac
