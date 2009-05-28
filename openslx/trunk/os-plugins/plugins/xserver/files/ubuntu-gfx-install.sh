#!/bin/sh

# gets needed packages for ubuntu nvidia/ati drivers
# $1 = nvidia | ati
PLUGIN_FOLDER="/opt/openslx/plugin-repo/xserver"
TMP_FOLDER="/tmp/slx-plugin/xserver"
TARGET="$1"
DISTRO="$2"

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


echo "  * downloading restricted modules... this may take a while"
# TODO: remove commented out "> /dev/null ..." later... multiple times
#       in this script! check all comments!
aptitude download linux-restricted-modules-${KVER} #> /dev/null 2&>1
if [ $? -eq 1 ]; then
  echo "  * Didn't get restricted modules. Exit now!"
  #TODO: remove sh when development is finished
  sh
  exit
fi
MODULE_DEB=$(ls linux-restricted-modules-*.deb | tail -n1)
dpkg-deb -x ${MODULE_DEB} ${TMP_FOLDER}/modules

case ${TARGET} in
  ati)
    mkdir -p ${PLUGIN_FOLDER}/ati
    mkdir -p ${PLUGIN_FOLDER}/ati/modules

    echo "  * downloading fglrx xorg package... this may take a while"
    aptitude download xorg-driver-fglrx #> /dev/null 2&>1
    if [ $? -eq 1 ]; then
      echo "  * Didn't get package xorg-driver-fglrx! Exit now!"
      #TODO: remove sh when development is finished
      sh
      exit
    fi
    FGLRX_DEB=$(ls xorg-driver-fglrx_*.deb | tail -n1)
    # extract $DEB
    dpkg-deb -x ${FGLRX_DEB} ${PLUGIN_FOLDER}/ati

    # assemble module
    cd modules/lib/linux-restricted-modules/${KVER}/
    ld_static -d -r -o ${PLUGIN_FOLDER}/ati/modules/fglrx.ko fglrx/*

    #TODO: Bastian: do we really need this part in stage1?
    # Volker: I think we could just copy it (is a unique file)
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

    #@Volker: We need /etc-files - there is a database
    #         file for the fglrx-driver in stage3 !!!
    #rm -rf ./etc
    #TODO: check for more cleanups when the main part works!

  ;;


  nvidia)
    mkdir -p ${PLUGIN_FOLDER}/nvidia
    mkdir -p ${PLUGIN_FOLDER}/nvidia/modules

    echo "  * downloading fglrx xorg package... this may take a while"
    aptitude download nvidia-glx-new #> /dev/null 2&>1
    if [ $? -eq 1 ]; then
      echo "  * Didn't get package nvidia-glx-new!"
      #TODO: remove sh when development is finished
      sh
      exit
    fi
    #Bastian: what is this? please explain
    #aptitude download nvidia-glx
    NVIDIA_DEB=$(ls nvidia-glx*.deb | tail -n1)
    # extract $DEB
    dpkg-deb -x ${NVIDIA_DEB} ${PLUGIN_FOLDER}/nvidia

    # assemble module - we just need the new one here
    # TODO: modules for older graphics hardware can be found here
    cd modules/lib/linux-restricted-modules/${KVER}/
    ld_static -d -r -o ${PLUGIN_FOLDER}/nvidia/modules/nvidia.ko nvidia_new/*

    #TODO: if we use this part, we need to copy the check from ati, too!
    #if [ -f /usr/lib/dri/fglrx_dri.so ]; then
    #  mv /usr/lib/dri/fglrx_dri.so /usr/lib/dri/fglrx_dri.so.slx
    #else
    #  # remove link
    #  rm -rf /usr/lib/dri/fglrx_dri.so
    #fi
    #ln -s ${PLUGIN_FOLDER}/nvidia/nvroot/usr/lib/dri/nvidia_dri.so \
    #        /usr/lib/dri/fglrx_dri.so

    # cleanup
    cd ${PLUGIN_FOLDER}/nvidia
    rm -rf ./etc
    #TODO: check for more cleanups when the main part works!
  ;;
esac

