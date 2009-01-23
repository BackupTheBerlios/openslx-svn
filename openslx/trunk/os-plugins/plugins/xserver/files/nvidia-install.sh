#!/bin/sh
##########################################################
# Installs NVIDIA binary drivers into openslx plugin-repo
##########################################################
#
# $1 should be package folder
# $2 is temporary folder - defaults to /opt/openslx/plugin-repo/xserver/nvidia/tmp
#
set -x

PLUGIN_PATH="/opt/openslx/plugin-repo/xserver"
TMP_FOLDER="$2"
PKG_FOLDER="$1"

if [ "${TMP_FOLDER}" -eq "" ]; then
  TMP_FOLDER="${PLUGIN_PATH}/nvidia/tmp"
fi
if [ ! -d ${TMP_FOLDER} ]; then
  mkdir -p ${TMP_FOLDER}
fi
# change working directory to ${TMP_FOLDER}
pushd ${TMP_FOLDER}

if [ ! -d "${PKG_FOLDER}" || ! -f "${PKG_FOLDER}/NVIDIA-Linux-*.run" ]; then
  echo "Can't find driver package from NVIDIA. Exiting!"
  exit 1
fi

# file to call - binary driver package from vendor
FILE=${PKG_FOLDER}/NVIDIA-Linux-*.run
# extract to ${FILE/.run/} 
./${FILE} -x

# or do we need precompiled? I guess not
NVPATH=${FILE/.run/}
rm -rf "${NVPATH}/usr/src/nv/precompiled" 
cp -R "${NVPATH}/usr" "${PLUGIN_PATH}/nvidia"

# kernel version - pick needed kernel version
UNAME_R=$(find /lib/modules/2.6* -maxdepth 0|sed 's,/lib/modules/,,g'|sort|tail -n1)
pushd ${PLUGIN_PATH}/nvidia/usr/src/nv/

##############
# DON'T LOAD THIS MODULE ON SERVER OR WHATEVER SYSTEM THIS MAY BE
sed \
 -e '/.* modprobe .*/d' \
 -i ${PLUGIN_PATH}/nvidia/usr/src/nv/Makefile.kbuild
 -i ${PLUGIN_PATH}/nvidia/usr/src/nv/Makefile.nvidia
 -i ${PLUGIN_PATH}/nvidia/usr/src/nv/makefile
###############



############################################
# build kernel modules
############################################
# compile nvidia.ko module with selected kernel
make SYSSRC=/lib/modules/${UNAME_R}/build module > /dev/null 2&>1
if [ $? -eq 0 ]; then
  echo "Successfully built module nvidia.ko!"
  mkdir -p /lib/modules/${UNAME_R}/video
  cp ${PLUGIN_PATH}/nvidia/usr/src/nv/nvidia.ko /lib/modules/${UNAME_R}/video/
else
  echo "Something went wrong while building nvidia.ko module!"
fi
popd



# TODO: perhaps we don't need this part! - it's very slow
#/./${TEMP_FOLDER}/nvidia-files/nvidia-installer -s --x-prefix=${TEMP_FOLDER} \
# --no-runlevel-check --no-abi-note --no-x-check\
# --no-rpms --no-recursion \
# --x-module-path=${TEMP_FOLDER}/usr/lib/xorg/modules\
# --x-library-path=${TEMP_FOLDER}/usr/lib\
# --opengl-prefix=${TEMP_FOLDER}/usr\
# --opengl-libdir=lib\
# --utility-prefix=${TEMP_FOLDER}/usr\
# --utility-libdir=lib\
# --documentation-prefix=${TEMP_FOLDER}/usr\
# --no-kernel-module \
## --kernel-install-path=${TEMP_FOLDER}/lib/modules/${KVERS}/video \
# 2>&1 > /dev/null

#mv ${TEMP_FOLDER}/src/usr/src ${TEMP_FOLDER}/usr/
#rm -rf ${TEMP_FOLDER}/usr/share ${TEMP_FOLDER}/src/


