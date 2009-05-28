#!/bin/bash

#
# supported:
# nvidia: 
# 	* 10.2 (pkg-installer)
#	* 11.0 (zypper rpm packages)
# 	* 11.1 (zypper rpm packages)
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
  if [ -e nvidia/usr/lib/libGL.so.1 ]; then
    exit
  fi
  if [ ! -d nvidia ]; then
  	mkdir -p nvidia/{modules,usr,temp}
  fi
  cd nvidia/temp

  ############################################################
  ##                 SUSE 11.0 Section                      ##
  ############################################################

  case ${DISTRO} in
    suse-10.2*)
	  echo "* Running general NVidia installer (expected in xserver::pkgpath)"
	  # unpack the nvidia installer; quickhack - expects just one package
	  echo "  * Unpacking installer"
	  sh ../../packages/NVIDIA-Linux-*.run -a -x >>nvidia-inst.log 2>&1
	  # prefix and paths should be matched more closely to each distro
	  # just demo at the moment ... but working at the moment
	  # without the kernel module
	  stdprfx=/opt/openslx/plugin-repo/xserver/nvidia
	
	  # backing up libglx.so and libGLcore.so
	  bkpprfx=${stdprfx}/../mesa/lib/xorg/modules/extensions
	  mkdir -p ${bkpprfx}
	  if [ -f /usr/lib/xorg/modules/extensions/libglx.so ]; then
	  	cp /usr/lib/xorg/modules/extensions/libGLcore.so ${bkpprfx}
	  	cp /usr/lib/xorg/modules/extensions/libglx.so ${bkpprfx}
	  elif [ -f /usr/X11R6/lib/xorg/modules/extensions/libglx.so ]; then
	  	cp /usr/X11R6/lib/xorg/modules/extensions/libglx.so ${bkpprfx}
	   cp /usr/X11R6/lib/xorg/modules/extensions/libGLcore.so ${bkpprfx}
	   touch ${bkpprfx}/../../../../X11R6
	  fi
	  if [ -f /usr/lib/libGL.so.1.2 ]; then
	   cp /usr/lib/libGL.so.1.2 ${bkpprfx}/../../..
	  elif [ -f /usr/X11R6/lib/libGL.so.1.2 ]; then
	   cp /usr/X11R6/lib/libGL.so.1.2 ${bkpprfx}/../../..
	   touch ${bkpprfx}/../../../X11R6
	  fi
	
	
	  # run the lib installer
	  echo "  * Starting the library installer"
	  echo "Starting the lib installer" >>nvidia-inst.log
	  $(ls -d NVIDIA-Linux-*)/nvidia-installer -s -q -N --no-abi-note \
	    --x-prefix=${stdprfx}/usr --x-library-path=${stdprfx}/usr/lib \
	    --x-module-path=${stdprfx}/usr/lib/xorg/modules \
	    --opengl-prefix=${stdprfx}/usr --utility-prefix=${stdprfx}/usr \
	    --documentation-prefix=${stdprfx}/usr --no-runlevel-check  \
	    --no-rpms --no-x-check --no-kernel-module \
	    --log-file-name=nvidia-lib.log >>nvidia-inst.log 2>&1
	  # how to get an idea of the installed kernel?
	  # run the kernel module creator (should be done for every kernel!?)
	  kernel=${KVERS}
	  echo "  * Trying to compile a kernel module for $kernel"
	  echo "Starting the kernel module installer for $kernel" >>nvidia-inst.log
	  # we need the .config file in /usr/src/linux or where ever!
	  # we need scripts/genksyms/genksyms compiled via make scripts in /usr/src/linux
	  # option available in newer nvidia packages
	  cd /usr/src/linux-${kernel%-*}
	  # in suse we have the config file lying there
	  cp /boot/config-${kernel} .config
	  ARCH=$(cat .config| grep -o CONFIG_M.86=y |tail -n1|grep -o "[0-9]86")
	  SUFFIX=${kernel##*-}
	  cp -r /usr/src/linux-${kernel%-*}-obj/i${ARCH}/${SUFFIX}/ \
	  		/usr/src/linux-${kernel%-*}
	  make scripts >/dev/null 2>&1
	  make prepare >/dev/null 2>&1
	  cd - >/dev/null 2>&1
	  #/usr/src/linux-${kernel%-*}
	  addopts="--no-cc-version-check"
	  $(ls -d NVIDIA-Linux-*)/nvidia-installer -s -q -N -K --no-abi-note \
	    --kernel-source-path=/usr/src/linux-${kernel%-*} \
	    -k ${kernel} \
	    --kernel-install-path=/opt/openslx/plugin-repo/xserver/nvidia/modules \
	    --no-runlevel-check --no-abi-note --no-rpms ${addopts} \
	    --log-file-name=nvidia-kernel.log >>nvidia-inst.log 2>&1
	  if [ $? -gt 0 ];then
	  	echo "* kernel module built failed!"
  	    echo "* Have a look into the several log files in "
  	    echo "  stage1/${DISTRO}/plugin-repo/xserver"
	  fi
	
	
	  # redo some unwanted changes of nvidia-installer
	  if [ -f ${bkpprfx}/libglx.so ]; then
	  	cp ${bkpprfx}/libGLcore.so /usr/lib/xorg/modules/extensions
	  	cp ${bkpprfx}/libglx.so /usr/lib/xorg/modules/extensions
	   if [ -f ${bkpprfx}/X11R6 ]; then
	      	cp ${bkpprfx}/libGLcore.so /usr/X11R6/lib/xorg/modules/extensions
	      	cp ${bkpprfx}/libglx.so /usr/X11R6/lib/xorg/modules/extensions
	   fi
	  fi
	  if [ -f ${bkpprfx}/../../../libGL.so.1.2 ]; then
	   cp ${bkpprfx}/../../../libGL.so.1.2  /usr/lib
	   ln -sf /usr/lib/libGL.so.1.2 /usr/lib/libGL.so.1
	   ln -sf /usr/lib/libGL.so.1.2 /usr/lib/libGL.so
	  elif [ -f ${bkpprfx}/../../../X11R6 ]; then
	  	cp  ${bkpprfx}/../../../libGL.so.1.2  /usr/X11R6/lib/
	  	ln -sf /usr/lib/libGL.so.1.2 /usr/lib/libGL.so.1
	   ln -sf /usr/lib/libGL.so.1.2 /usr/lib/libGL.so
	  fi
	;;
    suse-11.*)
      echo "* Downloading nvidia rpm packages... this could take some time..."
      # add repository for nvidia drivers
	  case ${DISTRO} in
	  suse-11.0*)
	  REPO=http://download.nvidia.com/opensuse/11.0/
	  ;;
	  suse-11.1*)
	  REPO=http://download.nvidia.com/opensuse/11.1/
	  ;;
	  esac
	  zypper --no-gpg-checks addrepo ${REPO} NVIDIA > /dev/null 2>&1
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
	if [ -d etc ]; then
		cp -r etc/* /etc/
	fi

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
        echo "Could not find kernel module fglrx.ko!";
    fi

  ;;
  esac
  cd ..

  rm -rf temp/
fi

