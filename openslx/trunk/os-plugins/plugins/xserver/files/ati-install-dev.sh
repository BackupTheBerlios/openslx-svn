#!/bin/sh

sh

cd /opt/openslx/plugin-repo/xserver

# check if its already installed
if [ -d ati/ ]; then
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
cd ati

#TODO: here we should do filecheck
#../${FILE_ATI} --check

# extract ati file
../${FILE_ATI} --extract ./temp/ > /dev/null

# we try to build the modules on our own. Perhaps we don't need all the
# packages and distribution stuff
cd temp/common/lib/modules/fglrx/build_mod
# faking environment
uname_r=$(find /lib/modules/2.6* -maxdepth 0|grep -v -e "^/lib/modules/$$"|sed 's,/lib/modules/,,g'|sort|tail -n1)
sed -i "s,^uname_r.*$,uname_r=${uname_r}," make.sh
sed -i "s,kernel_release=.*,kernel_release=${uname_r}," make.sh
#uname -m: just x86_64 and ia64 will get checked. till we support 64bit
# we'll use i686
sed -i "s,^uname_m.*$,uname_m=i686," make.sh
sh make.sh


# handle operating system
# firs we try it with a random suse one... perhaps it fit all our needs
# TODO: do we really need to know the specific distribution?
# TODO: get it from stage1
#case "$SYSNAME" in
#  "suse-10.2")  
#    PKGNAME="SuSE/SUSE102-IA32"
#    ;;
#  "ubuntu") 
#    PKGNAME="Ubuntu/7.10"
#    ;;
#  *) 
#    echo "  * failed to identify Distribution. Exit."
#    exit
#    ;;
#esac

# install
#cd ./temp/
#
#./ati-installer.sh ${VERSION} --buildpkg ${PKGNAME} 2>&1 > ../out.txt
#cd ..
#  
#if [ "$(grep 'successfully generated' out.txt | wc -l)" -eq 1 ]; then
#  echo "System package extracted from driver archive..."
#
#  if [ ! -d $INSTFOLDER ]; then
#    mkdir -p $INSTFOLDER
#  fi
#  PKG=$(grep "successfully generated" out.txt | cut -d' ' -f2)
#
#  # look for the last three letters in $PKG
#  case ${PKG: -3} in
#    rpm) 
#      rpm2cpio ${PKG} | cpio -i --make-directories 2>&1 > /dev/null 
#      ;;
#    deb)
#      # Do something
#      ;;
#    tgz|.gz)
#      tar -zxf ${PKG} 2>&1 > /dev/null   
#      ;;
#    *) 
#      # Do something as default
#      echo "System Package format not recognized!"
#      exit 1
#      ;;
#    esac
#fi
#rm -rf out.txt
