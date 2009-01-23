#!/bin/bash

##########################################################
# This file is responsible to extract system packages
# out of corresponding driver archives
# 
# Arguments (optional):
#  1: temporary folder, where we put all the extracted files in.
#   - default: put all extracted files in ./ati-files
#              and all driver files in ./ati-root
#
##########################################################

#set -x

DEBUG=false

TMP_FOLDER="$1"
FOLDER=`pwd`
if [ "$TMP_FOLDER" -eq "" ]; then
  TMP_FOLDER=${FOLDER}
fi

FILE_ATI=$FOLDER/ati-driver-installer*.run


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
  
  # here we will just create a package to extract it later
  # and have all things in one place
  VERSION=`head ${FILE_ATI} | grep "label=" | sed -e 's,.*Driver-\(.*\)",\1,g'`
  
  # TODO: distinguish between 32-bit and 64-bit
  PKGNAME="SuSE/SUSE102-IA32"

  pushd ${TMP_FOLDER}/ati-files
  ./ati-installer.sh $VERSION --buildpkg ${PKGNAME} 2>&1 > out.txt
  
  if [ `grep "successfully generated" out.txt | wc -l` -eq 1 ]; then
    echo "* Package extracted from ATI driver archive..."
  else
    return
  fi

  if [ ! -d $INSTFOLDER ]; then
    mkdir -p $INSTFOLDER
  fi
  PKG=`grep "successfully generated" out.txt | cut -d' ' -f2 `

  # extract files into ati-root
  pushd $INSTFOLDER
 
  rpm2cpio ${PKG} | cpio -i --make-directories 2>&1 > /dev/null 
  if [ ! $? -eq 0 ]; then
    echo "* Something went wrong extracting package!"
  fi
  
  popd

}





##############################################
# Here main script starts
##############################################

ati_extract $FOLDER/ati-root


if [ $DEBUG == "true" ]
then
  /bin/bash
  rm -rf ${TMP_FOLDER}/ati-files

fi

