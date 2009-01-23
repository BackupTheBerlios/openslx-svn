#!/bin/bash

##########################################################
# This file is responsible to extract system packages
# out of corresponding driver archives
# 
# Arguments:
#  1: temporary folder, where we put all the extracted files in.
#  2: your system name (will come from OpenSLX' vendorOS)
#  3: ati | nvidia [nothing to extract both]
#
# CHECK: No need for NVIDIA to extract?
##########################################################

#set -x

DEBUG=false

TMP_FOLDER="$1"
SYSNAME="$2"
WHAT="$3"

FOLDER=`pwd`/..
FILE_ATI=$FOLDER/ati-driver-installer*.run
FILE_NVIDIA=$FOLDER/NVIDIA-Linux*.run


##########################################################
# function ati_extract: Extract files from ATI-Package
#--------------------------------------------------------
#
# This function extracts the package for the right system
# from the driver archive of ATI.
#
##########################################################
function ati_extract  {
  INSTFOLDER=$1

  
  if [ -f ${FILE_ATI} ]; then
    chmod +x ${FILE_ATI}
    ${FILE_ATI} --extract ${TMP_FOLDER}/ati-files 2>&1 > /dev/null
  else
    echo "Could not extract ATI driver files!\n Please make sure that archive is not located in /tmp"
    exit
  fi
  

  VERSION=`head ${FILE_ATI} | grep "label=" | sed -e 's,.*Driver-\(.*\)",\1,g'`

  PKGNAME=""
  case "$SYSNAME" in
    "suse-10.2")  
      PKGNAME="SuSE/SUSE102-IA32"
      ;;
    "ubuntu") 
      PKGNAME="Ubuntu/7.10"
      ;;
    *) 
      PKGNAME="Debian/etch"
      ;;
  esac


  pushd ${TMP_FOLDER}/ati-files
  ./ati-installer.sh $VERSION --buildpkg ${PKGNAME} 2>&1 > out.txt
  
  if [ `grep "successfully generated" out.txt | wc -l` -eq 1 ]; then
    echo "System package extracted from driver archive..."

    if [ ! -d $INSTFOLDER ]; then
      mkdir -p $INSTFOLDER
    fi
    PKG=`grep "successfully generated" out.txt | cut -d' ' -f2 `

    pushd $INSTFOLDER

    # look for the last three letters in $PKG
    case ${PKG: -3} in
      rpm) 
        rpm2cpio ${PKG} | cpio -i --make-directories 2>&1 > /dev/null 
        ;;
      deb)
        # Do something
        ;;
      tgz|.gz)
        tar -zxf ${PKG} 2>&1 > /dev/null   
        ;;
       *) 
        # Do something as default
        echo "System Package format not recognized!"
        exit 1
        ;;
    esac
    popd

  fi
}



##########################################################
# function nvidia_extract: Extract files from 
#				nvidia-package
#--------------------------------------------------------
#
# This function extracts the package for the right system
# from the driver archive of NVIDIA.
#
##########################################################
function nvidia_extract  {
  INSTFOLDER=$1
  WORKFOLDER=${TMP_FOLDER}/nvidia-files

  
  if [ -f ${FILE_NVIDIA} ]; then
    chmod +x ${FILE_NVIDIA}
    ${FILE_NVIDIA} --extract ${WORKFOLDER} 2>&1 > /dev/null
  else
    echo "Could not extract NVIDIA driver files!\n Please make sure that archive is not located in /tmp"
    exit
  fi
  
}









##############################################
# Here main script starts
##############################################

case $WHAT in
  nvidia)
   nvidia_extract $FOLDER/nvidia-package
   ;;
  ati)
   ati_extract $FOLDER/ati-package
   ;;
  *)
   nvidia_extract $FOLDER/nvidia-package
   ati_extract $FOLDER/ati-package
   exit 1
   ;;
esac


if [ $DEBUG == "true" ]
then
  /bin/bash
  rm -rf ${TMP_FOLDER}/ati-files

fi

