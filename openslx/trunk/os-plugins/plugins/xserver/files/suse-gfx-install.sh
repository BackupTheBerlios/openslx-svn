#!/bin/sh

#
# supported:
# nvidia: 
# 	* 10.2 (pkg-installer)
#	* 11.0 (zypper rpm packages)
# 	* not yet - soon - 11.1 
# 
# ati:
#	* 10.2 (pkg-installer)
#	* 11.0 (zypper rpm packages)
#	* 11.1 (zypper rpm packages)
#

# not right any more - removed from script
# is there any busybox in this environment
#BUSYBOX="/mnt/opt/openslx//busybox/busybox"

BASE=/opt/openslx/plugin-repo/xserver
DISTRO=$2
cd ${BASE} 

if [ -L /boot/vmlinuz ]; then 
    KSUFFIX=$(ls -l /boot/vmlinuz | grep -P -o -e "-[a-z]*$" )
	KVERS=$(ls -l /boot/vmlinuz | awk -F "->" '{print $2}'| grep -P -o "2.6.*")
else 
    KSUFFIX=$(ls /boot/vmlinuz-* | head -n1 | grep -P -o -e "-[a-z]*$" )
	KVERS=$(ls /boot/vmlinuz-* | head -n1 | awk -F "->" '{print $2}' | grep -P -o "2.6.*" )

fi

if [ -z "${KSUFFIX}" ]; then
    echo "Could not determine proper local kernel suffix!"
    echo "This is needed to install kernel modules for graphics drivers!"
    exit 1
#else
#	echo -e "Kernel-Suffix: ${KSUFFIX}"
#	echo -e "Kernel-version:${KVERS}"
fi


buildfglrx() {
    # build ATI kernel module
    cd ${BASE}/ati/usr/src/kernel-modules/fglrx
    rm -rf fglrx.ko >/dev/null 2>&1
    make KVER=${1} >/dev/null 2>&1
    if [ "$?" -eq "0" ]; then
        cp fglrx.ko ../../../../modules
    else
    	echo -e "Kernel module for kernel ${1} could not be built!"
    fi
    cd - >/dev/null 2>&1
}


##########################################################################
# NVidia section
##########################################################################
if [ "$1" = "nvidia" ]; then
  if [ ! -d nvidia ]; then
  	mkdir -p nvidia/{modules,usr,temp}
  fi
  cd nvidia/temp
  if [ -e nvidia/usr/lib/libGL.so.1 ]; then
    exit
  fi

  ############################################################
  ##                 SUSE 11.0 Section                      ##
  ############################################################

  case ${DISTRO} in
    suse-11.*)
      echo "* Downloading nvidia rpm packages... this could take some time..."
      # add repository for nvidia drivers
	  case ${DISTRO} in
	  suse-11.0*)
      zypper --no-gpg-checks addrepo http://download.nvidia.com/opensuse/11.0/ NVIDIA > /dev/null 2>&1
	  ;;
	  suse-11.1*)
      zypper --no-gpg-checks addrepo http://download.nvidia.com/opensuse/11.1/ NVIDIA > /dev/null 2>&1
	  ;;
	  esac
      # get URLs by virtually installing nvidia-OpenGL driver
      zypper --no-gpg-checks -n -vv install -D \
	  	nvidia-gfxG01-kmp${KSUFFIX}  > logfile 2>&1 
  
      # zypper refresh is requested if something is not found
      if [ "1" -le "$(cat logfile | grep -o "zypper refresh"| wc -l)" ]; then 
          zypper refresh >/dev/null 2>&1 
      fi
  
      # take unique urls from logfile
      URLS=$(cat logfile |  grep -P -o "http://.*?rpm " | sort -u | xargs)
      for RPM in $URLS; do
        RNAME=$(echo ${RPM} | sed -e 's,^.*/\(.*\)$,\1,g')
        if [ ! -e ${RNAME} ]; then
          wget ${RPM} > /dev/null 2>&1
        fi
        # We use rpm2cpio from suse to extract
        rpm2cpio ${RNAME} | cpio -id > /dev/null 2>&1
      done
      mv ./usr/X11R6/lib/* ./usr/lib/
  
      rm -rf ../usr
      mv ./usr ..
      find lib/ -name "*.ko" -exec mv '{}' ../modules \;
  
      cd .. 
    ;;
  esac

  rm -rf temp/
  cd ..

fi


############################################################################
# ATI section
############################################################################
if [ "$1" = "ati" ]; then
  if [ -e ati/usr/lib/libGL.so.1.2 ]; then
    exit
  fi

  mkdir -p ati/modules ati/temp

  case ${DISTRO} in
  suse-10.2*)
    ### SUSE 10.2 section ###
    echo "* Extracting ATI package (expected in xserver::pkgpath) ... this could take some time..."

    PKG=`find packages/ -name ati-driver*\.run | tail -n1`
    PKG_VERSION=`head ${PKG} | grep -P -o "[0-9]\.[0-9]{3}"`
    
    chmod +x ${PKG}

    ${PKG} --extract ati/temp >/dev/null 2>&1

    cd ati/temp/
    RPM=`./ati-installer.sh ${PKG_VERSION} --buildpkg SuSE/SUSE102-IA32 2>&1 | grep Package | awk '{print $2}' | tail -n1`

    cd ..
    rpm2cpio ${RPM} 2>/dev/null | cpio -id >/dev/null 2>&1 


    mv ./usr/X11R6/lib/* ./usr/lib/

    # cleanup
    rm -rf ${RPM}
    cd ..
    rm -rf ${PKG}

    buildfglrx ${KVERS}

  ;;
  suse-11.*)
    ### SUSE 11.0 Section ###

    echo "* Downloading ati rpm packages... this could take some time..."
    cd ati/temp

    # add repository for ATI drivers
	case ${DISTRO} in
	suse-11.0*)
    zypper --no-gpg-checks addrepo http://www2.ati.com/suse/11.0/ ATI > /dev/null 2>&1 
	;;
	suse-11.1*)
    zypper --no-gpg-checks addrepo http://www2.ati.com/suse/11.1/ ATI > /dev/null 2>&1 
	;;
	esac
    # get URLs by virtually installing fglrx-OpenGL driver
    zypper --no-gpg-checks -n -vv install -D ati-fglrxG01-kmp${KSUFFIX} \
    x11-video-fglrxG01 > logfile 2>&1

    # zypper refresh is requested if something is not found
    if [ "1" -le "$(cat logfile | grep -o "zypper refresh" | wc -l)" ]; then
        zypper refresh >/dev/null 2>&1
    fi

    # take unique urls from logfile
    URLS=$(cat logfile |  grep -P -o "http://.*?rpm " | grep fglrx | sort -u | xargs)
    for RPM in $URLS; do
      RNAME=$(echo ${RPM} | sed -e 's,^.*/\(.*\)$,\1,g')
      if [ ! -e ${RNAME} ]; then
        wget ${RPM} > /dev/null 2>&1 
      fi
      # We use rpm2cpio from suse to extract -> propably new rpm version
      rpm2cpio ${RNAME} | cpio -id > /dev/null 2>&1
    done

    mv ./usr/X11R6/lib/* ./usr/lib/
    mv ./usr ..
    mv ./etc ..

    find lib/ -name "*.ko" -exec mv {} ../modules \; >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Could not find kernel module nvidia.ko!";
    fi

  ;;
  esac
  cd ..

  rm -rf temp/
fi

