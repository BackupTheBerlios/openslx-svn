#!/bin/sh

cd /opt/openslx/plugin-repo/xserver

# Ubuntu gfx-install.sh skript
DISTRO=$1
case $DISTRO in

  ubuntu-8.10)
    ./ubuntu-8.10-gfx-install.sh ati
  
  ;;
  ubuntu-*)
    ./ubuntu-gfx-install.sh ati
  ;;

# End ubuntu gfx-install.sh

# SUSE gfx-install.sh skript
  suse-*)
    # we have SuSE - run ubuntu-gfx-install
    ./suse-gfx-install.sh ati
  ;;
esac
