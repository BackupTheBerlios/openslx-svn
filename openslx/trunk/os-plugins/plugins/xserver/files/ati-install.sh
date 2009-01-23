#!/bin/sh

cd /opt/openslx/plugin-repo/xserver

# check if its already installed
if [ -d ati ]; then
  echo "   * ati driver seems to be installed"
  echo "     If you want to reinstall ati drivers press \"y\" or else we will exit"
  read
  if [ "${REPLY}" != "y" ]; then
    echo "   * ati is already installed. Nothing to do."
    exit
  fi
  echo "   * ati drivers will be reinstalled"
  echo "   * deleting old files"
  rm -rf ati/
fi

#TODO: check if we have ati files available (and not just nvidia's)
FILE_ATI=$(ls packages/ati-driver-installer*.run|sort|tail -n 1)
VERSION=$(head ${FILE_ATI} | grep "label=" | sed -e 's,.*Driver-\(.*\)",\1,g')

mkdir ati
mkdir ati/modules
mkdir ati/atiroot
cd ati

#TODO: here we should do filecheck
#../${FILE_ATI} --check

# extract ati file
../${FILE_ATI} --extract ./temp/ > /dev/null



echo "  * build kernel modules"
cd temp/common/lib/modules/fglrx/build_mod
#TODO GCC4 haengt von GCC ab, hier version 4
GCC_VERSION=4
ln -s /opt/openslx/plugin-repo/xserver/ati/temp/arch/x86/lib/modules/fglrx/build_mod/libfglrx_ip.a.GCC${GCC_VERSION} .
cp 2.6.x/Makefile .
uname_r=$(find /lib/modules/2.6* -maxdepth 0|sed 's,/lib/modules/,,g'|sort|tail -n1)
sed -i "s,^KVER.*$,KVER = ${uname_r}," Makefile
# TODO: less verbose
make -C /lib/modules/2.6.18.8-0.9-bigsmp/build M=$(pwd) GCC_VER_MAJ=${GCC_VERSION}

cd /opt/openslx/plugin-repo/xserver/ati

echo "  * move kernel modules"
mv temp/common/lib/modules/fglrx/build_mod/fglrx.ko modules/
mv temp/common/* atiroot
cp -r temp/arch/x86/* atiroot/
rm -rf atiroot/lib
rm -rf atiroot/opt
rm -rf atiroot/usr/src

# Todo: keep it for development purpose
#rm -rf temp/

sh

