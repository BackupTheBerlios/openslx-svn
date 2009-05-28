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

if [ ! -e "/usr/sbin/dkms" ]; then
  echo -n "  * DKMS not found: installing .."
  aptitude install dkms > /dev/null 2>&1
    if [ $? -eq 1 ]; then
      echo "fail"
      echo "  * Didn't get package dkms! Exit now!"
      exit 1
    else
      echo "ok"
    fi
fi

case ${TARGET} in
  ati)
    mkdir -p ${PLUGIN_FOLDER}/ati/modules

    echo -n "  * downloading fglrx xorg package... "
    aptitude download xorg-driver-fglrx > /dev/null 2>&1
    if [ $? -eq 1 ]; then
      echo "fail"
      echo "  * Didn't get package xorg-driver-fglrx! Exit now!"
      exit 1
    else
      echo "ok"
    fi
    FGLRX_DEB=$(ls xorg-driver-fglrx_*.deb | tail -n1)
    # extract $DEB
    dpkg-deb -x ${FGLRX_DEB} ${PLUGIN_FOLDER}/ati

    echo -n "  * downloading fglrx kernel package... "
    aptitude download fglrx-kernel-source >/dev/null 2>&1
    if [ $? -eq 1 ]; then
      echo "fail"
      echo "  * Didn't get package fglrx-kernel-source!"
      exit 1
    else
      echo "ok"
    fi

    FGLRX_KERNEL_DEB=$(ls fglrx-kernel-source*.deb | tail -n1)
    dpkg-deb -x ${FGLRX_KERNEL_DEB} /

    FGLRX_SOURCE_DIR=$(find  /usr/src/fglrx-${FGLRX_DRIVER_VERSION}* \
      -maxdepth 0 -type d)
    FGLRX_FULL_VERSION=$(echo ${FGLRX_SOURCE_DIR} | \
      sed -e 's/\/usr\/src\/fglrx-//')

    FGLRX_DKMS_DIR="/var/lib/dkms/fglrx/${FGLRX_FULL_VERSION}"

    if [ -d /var/lib/dkms/fglrx/${FGLRX_FULL_VERSION} ]; then
      if [ ! -L ${FGLRX_DKMS_DIR}/source ]; then
        ln -sf ${FGLRX_SOURCE_DIR} ${FGLRX_DKMS_DIR}/source
      fi
    else
      echo -n "  * Add fglrx kernel module to dkms tree... "
      dkms add -m fglrx -v ${FGLRX_FULL_VERSION} >/dev/null 2>&1
      if [ $? -eq 0 ]; then
        echo "ok"
      else
        echo "fail"
        exit 1
      fi
    fi

    ######    build kernel module   ######
    echo -n "  * Building fglrx kernel module for kernel ${KVER}... "
    dkms -m fglrx -v ${FGLRX_FULL_VERSION} \
         -k ${KVER} \
         --kernelsourcedir /usr/src/linux-headers-${KVER}/ \
         --no-prepare-kernel \
         --no-clean-kernel \
         build \
    > /tmp/dkms.log 2>&1
    if [ $? -eq 0 ]; then
      echo "ok"
    else
      if $(cat /tmp/dkms.log | grep -q "has already"); then
        echo -n "--- fglrx module already built ---"
      else
        echo "fail"
        echo "------ dkms.log -----"
        cat /tmp/dkms.log
        echo "---------------------"
        rm /tmp/dkms.log
        exit 1
      fi
    fi

    FGLRX_MODULE_PATH=$(find ${FGLRX_DKMS_DIR}/${KVER}/ -name fglrx.ko \
            | tail -n1 )

    cp ${FGLRX_MODULE_PATH} ${PLUGIN_FOLDER}/ati/modules/fglrx.ko

    # cleanup
    if [ -f /usr/lib/dri/fglrx_dri.so ]; then
      mv /usr/lib/dri/fglrx_dri.so /usr/lib/dri/fglrx_dri.so.slx
    else
      # remove link
      rm -rf /usr/lib/dri/fglrx_dri.so
    fi
    ln -s ${PLUGIN_FOLDER}/ati/usr/lib/dri/fglrx_dri.so \
        /usr/lib/dri/fglrx_dri.so

    # cleanup
    rm /tmp/dkms.log
    cd ${PLUGIN_FOLDER}/ati

  ;;


  nvidia)
    mkdir -p ${PLUGIN_FOLDER}/nvidia/modules
    
    NVIDIA_DRIVER_VERSION=173

    echo -n "  * downloading nvidia xorg package... "
    aptitude download nvidia-glx-${NVIDIA_DRIVER_VERSION} > /dev/null 2>&1
    if [ $? -eq 1 ]; then
      echo "fail"
      echo "  * Didn't get package nvidia-glx-${NVIDIA_DRIVER_VERSION}!"
      exit 1
    else
      echo "ok"
    fi

    echo -n "  * downloading nvidia kernel package... "
    aptitude download nvidia-${NVIDIA_DRIVER_VERSION}-kernel-source >/dev/null 2>&1
    if [ $? -eq 1 ]; then
      echo "fail"
      echo "  * Didn't get package nvidia-${NVIDIA_DRIVER_VERSION}-kernel-source!"
      exit 1
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

    NVIDIA_DKMS_DIR="/var/lib/dkms/nvidia/${NVIDIA_FULL_VERSION}"

    if [ -d /var/lib/dkms/nvidia/${NVIDIA_FULL_VERSION} ]; then
      if [ ! -L ${NVIDIA_DKMS_DIR}/source ]; then
        ln -sf ${NVIDIA_SOURCE_DIR} ${NVIDIA_DKMS_DIR}/source
      fi
    else
      echo -n "  * Add nvidia kernel module to dkms tree... "
      dkms add -m nvidia -v ${NVIDIA_FULL_VERSION} >/dev/null 2>&1
      if [ $? -eq 0 ]; then
        echo "ok"
      else
        echo "fail"
        exit 1
      fi
    fi

    ######    build kernel module   ######
    echo -n "  * Building nvidia kernel module for kernel ${KVER}... "
    dkms -m nvidia -v ${NVIDIA_FULL_VERSION} \
         -k ${KVER} \
         --kernelsourcedir /usr/src/linux-headers-${KVER}/ \
         --no-prepare-kernel \
         --no-clean-kernel \
         build \
    > /tmp/dkms.log 2>&1
    if [ $? -eq 0 ]; then
      echo "ok"
    else
      if $(cat /tmp/dkms.log | grep -q "has already"); then
        echo -n "--- nvidia module already built ---"
      else
        echo "fail"
        echo "------ dkms.log -----"
        cat /tmp/dkms.log
        echo "---------------------"
        rm /tmp/dkms.log
        exit 1
      fi
    fi

    NVIDIA_MODULE_PATH=$(find ${NVIDIA_DKMS_DIR}/${KVER}/ -name \
            nvidia.ko | tail -n 1)

    cp ${NVIDIA_MODULE_PATH} ${PLUGIN_FOLDER}/nvidia/modules/nvidia.ko

    # cleanup
    rm /tmp/dkms.log
    cd ${PLUGIN_FOLDER}/nvidia
    rm -rf ./etc
    #TODO: check for more cleanups when the main part works!
  ;;
esac

