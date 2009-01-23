#!/bin/sh

##########################################################
# Installs NVIDIA binary drivers into openslx plugin-repo
##########################################################
PLUGIN_PATH="/opt/openslx/plugin-repo/xserver"
TMP_FOLDER="/opt/openslx/plugin-repo/xserver/nvidia/temp"
PKG_FOLDER="/opt/openslx/plugin-repo/xserver/packages"
MODULES_FOLDER="/opt/openslx/plugin-repo/xserver/modules"

#TODO: check if we still have .../xserver/nvidia folder


cd ${PLUGIN_PATH}

# Ubuntu gfx-install.sh skript
if [ "1" -eq "$(lsb_release -i | grep 'Ubuntu' | wc -l)" ]; then
  # we have Ubuntu - run ubuntu-gfx-install
  echo "* Using Ubuntu packages to install modules and libs"
  ./ubuntu-gfx-install.sh nvidia
  exit
fi
# End ubuntu gfx-install.sh


# SUSE gfx-install.sh skript
if [ "1" -eq "$(lsb_release -i | grep 'SUSE' | wc -l)" ]; then
  # we have SUSE - run ubuntu-gfx-install
  echo "* Using SuSE packages to install modules and libs"
  ./suse-gfx-install.sh nvidia
  exit
fi
# End suse gfx-install.sh
