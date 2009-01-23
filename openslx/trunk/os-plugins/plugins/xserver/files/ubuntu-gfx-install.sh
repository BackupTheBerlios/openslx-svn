#!/bin/bash

# gets needed packages for ubuntu nvidia/ati drivers
# $1 = nvidia | ati
PLUGIN_FOLDER="/opt/openslx/plugin-repo/xserver"
TMP_FOLDER="/tmp/"
TARGET="$1"

if [ ! -d "${PLUGIN_FOLDER}" ]; then
  mkdir -p "${PLUGIN_FOLDER}/modules"
fi

# change into temp
pushd ${TMP_FOLDER} > /dev/null

if [ -e "/boot/vmlinuz" ]; then
  KVER=$(ls -ahl '/boot/vmlinuz' | sed -e 's,^.*vmlinuz-,,g')
else
  KVER=$(find /lib/modules/2.6* -maxdepth 0|sed 's,/lib/modules/,,g'|sort|tail -n1)
fi


aptitude download linux-restricted-modules-${KVER} > /dev/null 2&>1
MODULE_DEB=$(ls linux-restricted-modules-*.deb | tail -n1)
dpkg-deb -x ${MODULE_DEB} ${TMP_FOLDER}/modules

case ${TARGET} in
  ati)
    aptitude download xorg-driver-fglrx > /dev/null 2&>1
    if [ $? -eq 1 ]; then
      echo "Didn't get package xorg-driver-fglrx! Starting debug shell.."
      bash
    fi
    FGLRX_DEB=$(ls xorg-driver-fglrx_*.deb | tail -n1)
    # extract $DEB into folder "atiroot"
    dpkg-deb -x ${FGLRX_DEB} ${PLUGIN_FOLDER}/ati/atiroot/

    # assemble module
    pushd modules/lib/linux-restricted-modules/${KVER}/ > /dev/null 2&>1
    ld_static -d -r -o ${PLUGIN_FOLDER}/modules/fglrx.ko fglrx/*
    popd > /dev/null 2&>1

    rm -rf ${FGLRX_DEB}
  ;;
  nvidia)
    aptitude download nvidia-glx-new > /dev/null 2&>1
    if [ $? -eq 1 ]; then
      echo "Didn't get package nvidia-glx-new! Starting debug shell.."
      bash
    fi   #oder
    #aptitude download nvidia-glx
    # extract $DEB into folder "nvroot"
    NVIDIA_DEB=$(ls nvidia-glx*.deb | tail -n1)
    dpkg-deb -x ${NVIDIA_DEB} ${PLUGIN_FOLDER}/nvidia/nvroot/

    # assemble modules
    pushd modules/lib/linux-restricted-modules/${KVER}/ > /dev/null 2&>1
    for module in nvidia nvidia_legacy nvidia_new; do
      ld_static -d -r -o ${PLUGIN_FOLDER}/modules/${module}.ko ${module}/*
    done 
    popd > /dev/null 2&>1

    rm -rf ${NVIDIA_DEB}
  ;;
  *)
    echo "Running installation script ubuntu-gfx-install.sh without purpose! Exiting!"
  ;;
esac

popd > /dev/null #${TMP_FOLDER}

rm -rf ${TMP_FOLDER}/modules


#
#
# TODO: move following line to a more general location
#
#
if [ "${TARGET}" = "ati" ];then 
  ln -s ${PLUGIN_FOLDER}/ati/atiroot/usr/lib/dri/fglrx_dri.so \
        /usr/lib/dri/fglrx_dri.so
fi

#if [ "${TARGET}" -eq "nvidia" ];then 
#  ln -s ${PLUGIN_FOLDER}/nvidia/nvroot/usr/lib/dri/nvidia_dri.so \
#        /usr/lib/dri/fglrx_dri.so
#fi

