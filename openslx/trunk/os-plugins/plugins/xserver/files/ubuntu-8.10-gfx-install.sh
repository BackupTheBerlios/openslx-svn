#!/bin/sh

# gets needed packages for ubuntu nvidia/ati drivers
# $1 = nvidia | ati
PLUGIN_FOLDER="/opt/openslx/plugin-repo/xserver"
TMP_FOLDER="/tmp/slx-plugin/xserver"
TARGET="$1"

if [ ! -d "${PLUGIN_FOLDER}" ]; then
  mkdir -p "${PLUGIN_FOLDER}/modules"
fi

# change into temp
cd ${TMP_FOLDER} > /dev/null

if [ -e "/boot/vmlinuz" ]; then
  KVER=$(ls -ahl '/boot/vmlinuz' | sed -e 's,^.*vmlinuz-,,g')
else
  KVER=$(find /lib/modules/2.6* -maxdepth 0|sed 's,/lib/modules/,,g'|sort|tail -n1)
fi


case ${TARGET} in
  ati)
    mkdir -p ${PLUGIN_FOLDER}/ati/modules

    echo -n "  * downloading fglrx xorg package... "
    aptitude download xorg-driver-fglrx > /dev/null 2>&1
    if [ $? -eq 1 ]; then
      echo "fail"
      echo "  * Didn't get package xorg-driver-fglrx! Exit now!"
      #TODO: remove sh when development is finished
      sh
      exit
    else
      echo "ok"
    fi
    FGLRX_DEB=$(ls xorg-driver-fglrx_*.deb | tail -n1)
    # extract $DEB
    dpkg-deb -x ${FGLRX_DEB} ${PLUGIN_FOLDER}/ati

    echo -n "  * downloading fglrx kernel package..."
    aptitude download fglrx-kernel-source >/dev/null 2>&1
    if [ $? -eq 1 ]; then
      echo "fail"
      echo "  * Didn't get package fglrx-kernel-source!"
      exit
    else
      echo "ok"
    fi

    FGLRX_KERNEL_DEB=$(ls fglrx-kernel-sources*.deb | tail -n1)
    dpkg-deb -x ${FGLRX_KERNEL_DEB} /

    bash

    if [ -f /usr/lib/dri/fglrx_dri.so ]; then
      mv /usr/lib/dri/fglrx_dri.so /usr/lib/dri/fglrx_dri.so.slx
    else
      # remove link
      rm -rf /usr/lib/dri/fglrx_dri.so
    fi
    ln -s ${PLUGIN_FOLDER}/ati/usr/lib/dri/fglrx_dri.so \
        /usr/lib/dri/fglrx_dri.so

    # cleanup
    cd ${PLUGIN_FOLDER}/ati

  ;;


  nvidia)
    mkdir -p ${PLUGIN_FOLDER}/nvidia/modules
    
    NVIDIA_DRIVER_VERSION=177

    echo -n "  * downloading nvidia xorg package... "
    aptitude download nvidia-glx-${NVIDIA_DRIVER_VERSION} > /dev/null 2>&1
    if [ $? -eq 1 ]; then
      echo "fail"
      echo "  * Didn't get package nvidia-glx-${NVIDIA_DRIVER_VERSION}!"
      exit
    else
      echo "ok"
    fi

    echo -n "  * downloading nvidia kernel package..."
    aptitude download nvidia-${NVIDIA_DRIVER_VERSION}-kernel-source >/dev/null 2>&1
    if [ $? -eq 1 ]; then
      echo "fail"
      echo "  * Didn't get package nvidia-${NVIDIA_DRIVER_VERSION}-kernel-source!"
      exit
    else
      echo "ok"
    fi

    NVIDIA_DEB=$(ls -1 nvidia-glx*.deb | tail -n1)
    NVIDIA_KERNEL_DEB=$(ls -1 nvidia-${NVIDIA_DRIVER_VERSION}-kernel-source*.deb | tail -n1)
    # extract $DEB
    dpkg-deb -x ${NVIDIA_DEB} ${PLUGIN_FOLDER}/nvidia
    # extract the sources deb to root
    dpkg-deb -x ${NVIDIA_KERNEL_DEB} /
    
    NVIDIA_SOURCE_DIR=$(find  /usr/src/nvidia-${NVIDIA_DRIVER_VERSION}* \
      -maxdepth 0 -type d)
    NVIDIA_FULL_VERSION=$(echo ${NVIDIA_SOURCE_DIR} | \
      sed -e 's/\/usr\/src\/nvidia-//')

    NVIDIA_DKMS_DIR="/var/lib/dkms/nvidia/${NVIDIA_FULL_VERSION}/"

    if [ -d /var/lib/dkms/nvidia/${NVIDIA_FULL_VERSION} ]; then
      if [ ! -L ${NVIDI_DKMS_DIR}/source ]; then
        ln -sf ${NVIDIA_SOURCE_DIR} ${NVIDIA_DKMS_DIR}/source
      fi
    else
      dkms add -m nvidia -v ${NVIDIA_FULL_VERSION} >/dev/null 2>&1
    fi

    bash 

    
    ######    build kernel module   ######
    echo -n "  * Building nvidia Kernel Module for Kernel ${KVER} .. "
    dkms -m nvidia -v ${NVIDIA_FULL_VERSION} \
         -k ${KVER} \
         --kernelsourcedir /usr/src/linux-headers-${KVER}/ \
         --no-prepare-kernel \
         build \
    > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      echo "ok"
    else
      echo "fail"
      exit
    fi

    NVIDIA_MODULE_PATH=$(find ${NVIDIA_DKMS_DIR}/${KVER}/ -name nvidia.ko)

    #module is now under /var/lib/dkms/nvidia/${NVIDIA_DRIVER_VERSION}.<subversion>/${KVER}/iX86/module/nvidia.ko
    # TODO: rest & cleanup :)
    ln -sf ${NVIDIA_MODULE_PATH} ${PLUGIN_FOLDER}/nvidia/modules/nvidia.ko

    # assemble module - we just need the new one here
    # TODO: modules for older graphics hardware can be found here
    #cd modules/lib/linux-restricted-modules/${KVER}/
    #ld_static -d -r -o ${PLUGIN_FOLDER}/nvidia/modules/nvidia.ko nvidia_new/*

    # cleanup
    cd ${PLUGIN_FOLDER}/nvidia
    rm -rf ./etc
    #TODO: check for more cleanups when the main part works!
  ;;
esac

