#!/bin/sh

##########################################################
# Installs NVIDIA binary drivers into openslx plugin-repo
##########################################################
PLUGIN_PATH="/opt/openslx/plugin-repo/xserver"

# we could easily pass this information via calling stage1 script and do not
# need to find it our here ...
DISTRO=$1


# for development we take the only kernel version from normal systems
if [ -L /boot/vmlinuz ]; then 
	KVERS=$(ls -l /boot/vmlinuz | awk -F "->" '{print $2}'| grep -P -o "2.6.*")
else 
	KVERS=$(ls /boot/vmlinuz-* | head -n1 | awk -F "->" '{print $2}' | grep -P -o "2.6.*" )
fi



cd ${PLUGIN_PATH}

case ${DISTRO} in
  ubuntu-8.10*)
    ./ubuntu-8.10-gfx-install.sh nvidia
  ;;
  ubuntu*)
    ./ubuntu-gfx-install.sh nvidia
  ;;
  suse-11.0*)
    ./suse-gfx-install.sh nvidia
  ;;
  # general purpose nvidia installer script
  *)
   echo "* Running general NVidia installer (expected in xserver::pkgpath)"
   # unpack the nvidia installer; quickhack - expects just one package
   echo "  * Unpacking installer"
   sh packages/NVIDIA-Linux-*.run -a -x >>nvidia-inst.log 2>&1
   # prefix and paths should be matched more closely to each distro
   # just demo at the moment ... but working at the moment
   # without the kernel module
   stdprfx=/opt/openslx/plugin-repo/xserver/nvidia

   # backing up libglx.so and libGLcore.so
   BACKUP_PATH=${stdprfx}/../mesa/usr/lib/xorg/modules/extensions
   mkdir -p ${BACKUP_PATH}
   if [ -f /usr/lib/xorg/modules/extensions/libglx.so ]; then
   	cp /usr/lib/xorg/modules/extensions/libGLcore.so ${BACKUP_PATH}
   	cp /usr/lib/xorg/modules/extensions/libglx.so ${BACKUP_PATH}
   elif [ -f /usr/X11R6/lib/xorg/modules/extensions/libglx.so ]; then
   	cp /usr/X11R6/lib/xorg/modules/extensions/libglx.so ${BACKUP_PATH}
	cp /usr/X11R6/lib/xorg/modules/extensions/libGLcore.so ${BACKUP_PATH}
	touch ${BACKUP_PATH}/X11R6
   fi
   if [ -f /usr/lib/libGL.so.1.2 ]; then
	cp /usr/lib/libGL.so.1.2 ${BACKUP_PATH}/../../..
   elif [ -f /usr/X11R6/lib/libGL.so.1.2 ]; then
   	cp /usr/X11R6/lib/libGL.so.1.2 ${BACKUP_PATH}/../../..
	touch ${BACKUP_PATH}/../../../X11R6
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
   echo "Starting the kernel $kernel installer" >>nvidia-inst.log
   # we need the .config file in /usr/src/linux or where ever!
   # we need scripts/genksyms/genksyms compiled via make scripts in /usr/src/linux
   # option available in newer nvidia packages
   if [ ! -f /usr/src/linux-${kernel}/include/linux/kernel.h ]; then
   		cd /usr/src/linux-${kernel%-*}
		if [ ! -f .config ]; then
		  if [ -f /boot/config-${kernel} ]; then
		  	  # in suse we have the config file lying there
			  cp /boot/config-${kernel} .config
		  fi
		fi
		make scripts >/dev/null 2>&1
		make prepare >/dev/null 2>&1
		cd - >/dev/null 2>&1
   fi
   addopts="--no-cc-version-check"
   $(ls -d NVIDIA-Linux-*)/nvidia-installer -s -q -N -K --no-abi-note \
     --kernel-source-path=/usr/src/linux-${kernel%-*} -k ${kernel} \
     --kernel-install-path=/opt/openslx/plugin-repo/xserver/nvidia/modules \
     --no-runlevel-check --no-abi-note --no-rpms ${addopts} \
     --log-file-name=nvidia-kernel.log >>nvidia-inst.log 2>&1
   echo "  * Have a look into the several *.log files in "
   echo "    stage1/${DISTRO}/plugin-repo/xserver"


   # redo some unwanted changes of nvidia-installer
   if [ -f ${BACKUP_PATH}/libglx.so ]; then
   	cp ${BACKUP_PATH}/libGLcore.so /usr/lib/xorg/modules/extensions
   	cp ${BACKUP_PATH}/libglx.so /usr/lib/xorg/modules/extensions
    if [ -f ${BACKUP_PATH}/X11R6 ]; then
	   	cp ${BACKUP_PATH}/libGLcore.so /usr/X11R6/lib/xorg/modules/extensions
	   	cp ${BACKUP_PATH}/libglx.so /usr/X11R6/lib/xorg/modules/extensions
	fi
   fi
   if [ -f ${BACKUP_PATH}/../../../libGL.so.1.2 ]; then
	cp ${BACKUP_PATH}/../../../libGL.so.1.2  /usr/lib
	ln -sf /usr/lib/libGL.so.1.2 /usr/lib/libGL.so.1
	ln -sf /usr/lib/libGL.so.1.2 /usr/lib/libGL.so
   elif [ -f ${BACKUP_PATH}/../../../X11R6 ]; then
   	cp  ${BACKUP_PATH}/../../../libGL.so.1.2  /usr/X11R6/lib/
   	ln -sf /usr/lib/libGL.so.1.2 /usr/lib/libGL.so.1
	ln -sf /usr/lib/libGL.so.1.2 /usr/lib/libGL.so
   fi


  ;;
esac

# set a proper return value to evaluate it in the calling script
exit 0
