#!/bin/sh

cd /opt/openslx/plugin-repo/xserver

# Ubuntu gfx-install.sh skript
if [ "1" -eq "$(lsb_release -i | grep 'Ubuntu' | wc -l)" ]; then
  # we have Ubuntu - run ubuntu-gfx-install
  echo "* Using Ubuntu packages to install modules and libs"
  ./ubuntu-gfx-install.sh ati
  exit
fi
# End ubuntu gfx-install.sh

# SUSE gfx-install.sh skript
if [ "1" -eq "$(lsb_release -i | grep 'SUSE' | wc -l)" ]; then
  # we have SuSE - run ubuntu-gfx-install
  echo "* Using SuSE packages to install modules and libs"
  ./suse-gfx-install.sh ati
  exit
fi
# End ubuntu gfx-install.sh
