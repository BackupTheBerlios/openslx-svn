#!/bin/sh

set -x


# local path
FOLDER=$(pwd)

# temp path
TEMP_FOLDER="$1"
if [ "${TEMP_FOLDER}" -eq "" ]; then
  TEMP_FOLDER=${FOLDER}
fi


# file to call - should be replaced with argument
FILE=NVIDIA-Linux-*.run

# kernel version (not really useful in this context - on a server)
# TODO: we need to fix this for stage1 chroot
KVERS=$(uname -r)

# driver path - install modules in this path
DPATH=lib/modules/${KVERS}/kernel/drivers

if [ ! -d $TEMP_FOLDER ]; then
  mkdir -p ${TEMP_FOLDER}
fi

mkdir -p ${TEMP_FOLDER}/{usr/lib/xorg/modules,${DPATH}}

# extract contents - we need to fix some things
./${FILE} -x --target ${TEMP_FOLDER}/nvidia-files/


##########################################
# fix for:
#  - module installation path
#  - automatic module loading
##########################################
sed \
 -e 's,\(^MODULE_ROOT\s*= \)\(/lib/modules\),\1${TEMP_FOLDER}\2,g'\
 -e '/.* modprobe .*/d' \
 -i ${TEMP_FOLDER}/src/usr/src/nv/Makefile.kbuild



# TODO: perhaps we don't need this part! - it's very slow
/./${TEMP_FOLDER}/nvidia-files/nvidia-installer -s --x-prefix=${TEMP_FOLDER} \
 --no-runlevel-check --no-abi-note --no-x-check\
 --no-rpms --no-recursion \
 --x-module-path=${TEMP_FOLDER}/usr/lib/xorg/modules\
 --x-library-path=${TEMP_FOLDER}/usr/lib\
 --opengl-prefix=${TEMP_FOLDER}/usr\
 --opengl-libdir=lib\
 --utility-prefix=${TEMP_FOLDER}/usr\
 --utility-libdir=lib\
 --documentation-prefix=${TEMP_FOLDER}/usr\
 --no-kernel-module \
# --kernel-install-path=${TEMP_FOLDER}/lib/modules/${KVERS}/video \
 2>&1 > /dev/null

mv ${TEMP_FOLDER}/src/usr/src ${TEMP_FOLDER}/usr/
rm -rf ${TEMP_FOLDER}/usr/share ${TEMP_FOLDER}/src/

############################################
# build kernel modules
############################################
pushd ${TEMP_FOLDER}/usr/src/nv/
make -f Makefile.kbuild
popd

