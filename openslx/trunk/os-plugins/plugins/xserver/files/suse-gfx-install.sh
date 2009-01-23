#!/bin/sh

#
#Currently only suse 10.2 is supported!
#

#To handle it under suse is kinda retarded. SuSE 10.2's zypper don't know
#a flag similiar to "--download-only" (should be supported in a later
#SuSE Version!)
#SuSE 10.2 and 10.3 has two Kernelpackages:
#  nvidia-gfxG01-kmp-bigsmp and -default
#And its different nameing scheme to suse 11


BUSYBOX="/mnt/opt/openslx/share/busybox/busybox"

cd /opt/openslx/plugin-repo/xserver

if [ "$1" = "nvidia" ]; then
  mkdir -p nvidia/modules nvidia/temp
  cd nvidia/temp

  if [ "1" -eq "$(lsb_release -r|grep '10.2'|wc -l)" ]; then
    # TODO: add -q flag
    wget -c \
      ftp://download.nvidia.com/opensuse/10.2/i586/nvidia-gfxG01-kmp-bigsmp-173.14.12_2.6.18.8_0.10-0.1.i586.rpm \
      ftp://download.nvidia.com/opensuse/10.2/i586/nvidia-gfxG01-kmp-default-173.14.12_2.6.18.8_0.10-0.1.i586.rpm \
      ftp://download.nvidia.com/opensuse/10.2/i586/x11-video-nvidiaG01-173.14.12-0.1.i586.rpm

      # TODO: move output to /dev/null when main development is over
      ${BUSYBOX} rpm2cpio x11-video-nvidiaG01-173.14.12-0.1.i586.rpm | ${BUSYBOX} cpio -idv
    
      rm -rf ./usr/include
      # Todo: recheck after development progress, perhaps an nvidia x11 tool needs /usr/share/pixmaps
      #       same with var id's
      #rm -rf ./var
      #rm -rf ./usr/share
       
      mv ./usr ..

      # TODO: matching kernel problem... our openslx system picks -bigsmp - unintentionally!
      ${BUSYBOX} rpm2cpio nvidia-gfxG01-kmp-bigsmp-173.14.12_2.6.18.8_0.10-0.1.i586.rpm | ${BUSYBOX} cpio -idv
      #${BUSYBOX} rpm2cpio nvidia-gfxG01-kmp-default-173.14.12_2.6.18.8_0.10-0.1.i586.rpm | ${BUSYBOX} cpio -idv
      #TODO: take care about the kernel issue. Find won't work with two equal kernelmodules in lib/...
      find lib/ -name "*.ko" -exec mv {} ../modules \;

      

  fi

  cd ..
  
  # TODO: after development
  #rm -rf temp/
  sh
fi    
