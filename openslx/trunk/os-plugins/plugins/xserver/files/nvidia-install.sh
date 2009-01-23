#!/bin/sh

##########################################################
# Installs NVIDIA binary drivers into openslx plugin-repo
##########################################################
PLUGIN_PATH="/opt/openslx/plugin-repo/xserver"
TMP_FOLDER="/opt/openslx/plugin-repo/xserver/nvidia/temp"
PKG_FOLDER="/opt/openslx/plugin-repo/xserver/packages"
MODULES_FOLDER="/opt/openslx/plugin-repo/xserver/modules"

#TODO: check if we still have .../xserver/nvidia folder

mkdir -p ${TMP_FOLDER} ${MODULES_FOLDER}
cd ${PKG_FOLDER}
FILE=$(ls NVIDIA-Linux-*|sort|tail -n 1)

echo "  * extracting package"
cd ${TMP_FOLDER}
${PKG_FOLDER}/${FILE} -x > /dev/null
#todo: check if it extracted like it should...

FILEPATH=$(echo ${FILE}|sed 's/.run//')
NVPATH="${TMP_FOLDER}/${FILEPATH}"
mv "${NVPATH}/usr" "${PLUGIN_PATH}/nvidia"

echo "  * prepare kernel module"
UNAME_R=$(find /lib/modules/2.6* -maxdepth 0|sed 's,/lib/modules/,,g'|sort|tail -n1)
cd ${PLUGIN_PATH}/nvidia/usr/src/nv/
# dont load module
sed -e '/.* modprobe .*/d' \
 -i ${PLUGIN_PATH}/nvidia/usr/src/nv/Makefile.kbuild \
 -i ${PLUGIN_PATH}/nvidia/usr/src/nv/Makefile.nvidia \
 -i ${PLUGIN_PATH}/nvidia/usr/src/nv/makefile
# fake kernel
# Bastian: the SYSSRC way didnt work in chroot!
sed -e "s/..shell uname -r./${UNAME_R}/" \
 -i ${PLUGIN_PATH}/nvidia/usr/src/nv/Makefile.kbuild \
 -i ${PLUGIN_PATH}/nvidia/usr/src/nv/Makefile.nvidia \
 -i ${PLUGIN_PATH}/nvidia/usr/src/nv/makefile

echo "  * compile kernel module"
make module > /dev/null 2&>1

# somehow $? isn't trustworthy...
if [ -e nvidia.ko ]; then
  echo "  * Successfully built module nvidia.ko!"
  mv nvidia.ko ${MODULES_FOLDER}
else
  echo -e "\n\n  * Something went wrong while building nvidia.ko module!\n\n\n"
  #TODO: handle this error => mark plugin as not installed
fi

#TODO: remove comment
#echo "  * cleanup"
#rm -rf ${TMP_FOLDER} ${PLUGIN_PATH}/nvidia/usr/src

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


