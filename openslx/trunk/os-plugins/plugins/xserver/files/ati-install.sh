#!/bin/sh

cd /opt/openslx/plugin-repo/xserver

# Ubuntu gfx-install.sh skript
DISTRO=$(lsb_release -i)
RELEASE=$(lsb_release -r)

if [ "1" -eq "$(echo ${DISTRO} | grep 'Ubuntu' | wc -l)" ]; then
  # we have Ubuntu - run ubuntu-gfx-install
  echo "* Using Ubuntu packages to install ati modules and libs"
  if [ "8.10" = "$(echo ${RELEASE} | awk '{print $2}' )" ]; then
    ./ubuntu-8.10-gfx-install.sh ati
  else
    ./ubuntu-gfx-install.sh ati
  fi
  exit
fi
# End ubuntu gfx-install.sh

# SUSE gfx-install.sh skript
if [ "1" -eq "$(lsb_release -i | grep 'SUSE' | wc -l)" ]; then
  # we have SuSE - run ubuntu-gfx-install
  echo "* Using SuSE packages to install ati modules and libs"
  ./suse-gfx-install.sh ati
  exit
fi
# End ubuntu gfx-install.sh
