#!/bin/bash

set -x


# local path
LPATH=$(pwd)

# temp path
TPATH=${LPATH}/tmp

# file to call - should be replaced with argument
FILE=../NVIDIA-Linux-x86-1.0-9639-pkg1.run

# kernel version (not really useful in this context - on a server)
# todo: we need to fix this for stage1 chroot
KVERS=$(uname -r)

if [ ! -d $TPATH ]; then
  mkdir -p ${TPATH}
fi

mkdir -p ${TPATH}/{usr/lib/xorg/modules,lib/modules/${KVERS}/kernel/drivers}

# driver path - install modules in this path
DPATH=lib/modules/${KVERS}/kernel/drivers

# extract contents - we need to fix some things
./${FILE} -x --target ${TPATH}/src/


##########################################
# fix:
#  - module installation path
#  - automatic module loading
##########################################
sed \
 -e 's,\(^MODULE_ROOT\s*= \)\(/lib/modules\),\1${TPATH}\2,g'\
 -e '/.* modprobe .*/d' \
 -i ${TPATH}/src/usr/src/nv/Makefile.kbuild



# TODO: perhaps we don't need this part!
/./${TPATH}/src/nvidia-installer -s --x-prefix=${TPATH} \
 --no-runlevel-check --no-abi-note --no-x-check\
 --no-rpms --no-recursion \
 --x-module-path=${TPATH}/usr/lib/xorg/modules\
 --x-library-path=${TPATH}/usr/lib\
 --opengl-prefix=${TPATH}/usr\
 --opengl-libdir=lib\
 --utility-prefix=${TPATH}/usr\
 --utility-libdir=lib\
 --documentation-prefix=${TPATH}/usr\
 --no-kernel-module \
# --kernel-install-path=${TPATH}/lib/modules/${KVERS}/video \
 2>&1 > /dev/null

mv ${TPATH}/src/usr/src ${TPATH}/usr/
rm -rf ${TPATH}/usr/share ${TPATH}/src/

############################################
# build kernel modules
############################################
pushd ${TPATH}/usr/src/nv/
make -f Makefile.kbuild
popd

