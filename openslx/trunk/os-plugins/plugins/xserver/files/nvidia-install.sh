#!/bin/sh

##########################################################
# Installs NVIDIA binary drivers into openslx plugin-repo
##########################################################
PLUGIN_PATH="/opt/openslx/plugin-repo/xserver"

# we could easily pass this information via calling stage1 script and do not
# need to find it our here ...
DISTRO=$1

cd ${PLUGIN_PATH}

case ${DISTRO} in
  ubuntu-8.10*)
    ./ubuntu-8.10-gfx-install.sh nvidia
  ;;
  ubuntu*)
    ./ubuntu-gfx-install.sh nvidia
  ;;
  suse-11.X*)
    ./suse-gfx-install.sh nvidia
  ;;
  # general purpose nvidia installer script
  *)
   echo "  * Running general NVidia installer (expected in ~/xserver-pkgs)"
   # unpack the nvidia installer; quickhack - expects just one package
   echo "  * Unpacking installer"
   sh packages/NVIDIA-Linux-*.run -a -x >>nvidia-inst.log 2>&1
   stdprfx=/opt/openslx/plugin-repo/xserver/nvidia
   # run the lib installer
   echo "  * Starting the library installer"
   echo "Starting the lib installer" >>nvidia-inst.log
   $(ls -d NVIDIA-Linux-*)/nvidia-installer -s -q -N --no-abi-note \
     --x-prefix=${stdprfx}/usr --x-library-path=${stdprfx}/usr/lib \
     --x-module-path=${stdprfx}/usr/lib/xorg/modules \
     --opengl-prefix=${stdprfx}/usr --utility-prefix=${stdprfx}/usr \
     --documentation-prefix=${stdprfx}/usr --no-runlevel-check  \
     --no-rpms --no-x-check --no-kernel-module \
     --log-file-name=nvidia-lib.log >>nvidia-inst.log 2>&1
   # how to get an idea of the installed kernel?
   # run the kernel module creator (should be done for every kernel!?)
   kernel=2.6.25.18-0.2-pae
   echo "  * Trying to compile a kernel module for $kernel"
   echo "Starting the kernel $kernel installer" >>nvidia-inst.log
   $(ls -d NVIDIA-Linux-*)/nvidia-installer -s -q -N -K --no-abi-note \
     --kernel-source-path=/lib/modules/${kernel}/build -k ${kernel} \
     --kernel-install-path=/opt/openslx/plugin-repo/xserver/nvidia/modules \
     --no-runlevel-check  --no-abi-note --no-rpms --no-cc-version-check \
     --log-file-name=nvidia-kernel.log >>nvidia-inst.log 2>&1
   echo "  * Have a look into the several *.log files in "
   echo "    stage1/${DISTRO}/plugin-repo/xserver"
  ;;
esac

# set a proper return value to evaluate it in the calling script
exit 0
