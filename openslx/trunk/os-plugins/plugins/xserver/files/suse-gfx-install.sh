#!/bin/sh

#
# Currently suse 10.2 and 11.0 is supported!
#

BUSYBOX="/mnt/opt/openslx/share/busybox/busybox"

cd /opt/openslx/plugin-repo/xserver

if [ -s /boot/vmlinuz ]; then 
    KSUFFIX=$(ls -l /boot/vmlinuz | grep -P -o -e "-[a-z]*$" )
else 
    KSUFFIX=$(ls /boot/vmlinuz-* | head -n1 | grep -P -o -e "-[a-z]*$" )
fi

if [ -z "${KSUFFIX}" ]; then
    echo "Could not determine proper local kernel suffix!"
    echo "This is needed to install kernel modules for graphics drivers!"
    exit 1
fi

##########################################################################
# NVidia section
##########################################################################
if [ "$1" = "nvidia" ]; then
  if [ -e nvidia/usr/lib/libGL.so.1 ]; then
    exit
  fi

  #To handle it under suse is kinda retarded. SuSE 10.2's zypper don't know
  #a flag similiar to "--download-only" (should be supported in a later
  #SuSE Version!)
  #SuSE 10.2 and 10.3 has two Kernelpackages:
  #  nvidia-gfxG01-kmp-bigsmp and -default
  #And its different nameing scheme to suse 11

  mkdir -p nvidia/modules nvidia/temp
  cd nvidia/temp

  #TODO: licence information... even suse requires an accept
  # TODO: let it automatical find the newest file... see ati section
  #       only problem should be the kernel package

  # TODO: the following check doesn't work - why?
  # this is wasted time for suse-11.0 users 
  if [ "10.2" = "`cat /etc/SuSE-release | tail -n1 | cut -d' ' -f3`" ]; then
    echo "  * Downloading nvidia rpm packages... this could take some time..."
    wget -q -c \
      ftp://download.nvidia.com/opensuse/10.2/i586/nvidia-gfxG01-kmp-bigsmp-173.14.12_2.6.18.8_0.10-0.1.i586.rpm \
      ftp://download.nvidia.com/opensuse/10.2/i586/nvidia-gfxG01-kmp-default-173.14.12_2.6.18.8_0.10-0.1.i586.rpm \
      ftp://download.nvidia.com/opensuse/10.2/i586/x11-video-nvidiaG01-173.14.12-0.1.i586.rpm

      ${BUSYBOX} rpm2cpio x11-video-nvidiaG01-173.14.12-0.1.i586.rpm | ${BUSYBOX} cpio -idv > /dev/null

      rm -rf ./usr/include
      # Todo: recheck after development progress, perhaps an nvidia x11 tool needs /usr/share/pixmaps
      #       same with var id's
      #rm -rf ./usr/share

      mv ./usr ..

      # TODO: matching kernel problem... our openslx system picks -bigsmp - unintentionally!
      ${BUSYBOX} rpm2cpio nvidia-gfxG01-kmp-bigsmp-173.14.12_2.6.18.8_0.10-0.1.i586.rpm | ${BUSYBOX} cpio -idv > /dev/null
      #${BUSYBOX} rpm2cpio nvidia-gfxG01-kmp-default-173.14.12_2.6.18.8_0.10-0.1.i586.rpm | ${BUSYBOX} cpio -idv
      #TODO: take care about the kernel issue. Find won't work with two equal kernelmodules in lib/...
      find lib/ -name "*.ko" -exec mv {} ../modules \;
  fi

  if [ "11.0" = "`cat /etc/SuSE-release | tail -n1 | cut -d' ' -f3`" ]; then
    echo "  * Downloading nvidia rpm packages... this could take some time..."
    # add repository for nvidia drivers
    zypper --no-gpg-checks addrepo http://download.nvidia.com/opensuse/11.0/ NVIDIA > /dev/null 2>&1
    # get URLs by virtually installing nvidia-OpenGL driver
    zypper --no-gpg-checks -n -vv install -D x11-video-nvidiaG01 2>&1 > logfile

    # take unique urls from logfile
    URLS=$(cat logfile |  grep -P -o "http://.*?rpm " | sort -u | xargs)
    for RPM in $URLS; do
      RNAME=$(echo ${RPM} | sed -e 's,^.*/\(.*\)$,\1,g')
      if [ ! -e ${RNAME} ]; then
        wget ${RPM} > /dev/null 2>&1
      fi
      # We use rpm2cpio from suse to extract
      rpm2cpio ${RNAME} | ${BUSYBOX} cpio -id > /dev/null 2>&1
    done
    mv ./usr/X11R6/lib/* ./usr/lib/
    mv ./usr ..
    find lib/ -name "*.ko" -exec mv {} ../modules \;
#   echo "DEBUG xserver SUSE-GFX-INSTALL.SH NVIDIA"
#   /bin/bash
#   echo "END DEBUG"
  fi

  cd .. 
  # TODO: after development
  rm -rf temp/
fi



############################################################################
# ATI section
############################################################################
if [ "$1" = "ati" ]; then
  if [ -e ati/usr/lib/libGL.so.1.2 ]; then
    exit
  fi

  mkdir -p ati/modules ati/temp
  cd ati/temp

  if [ "11.0" = "`cat /etc/SuSE-release | tail -n1 | cut -d' ' -f3`" ]; then
    ## SUSE 11.0 Section ###

    echo "  * Downloading ati rpm packages... this could take some time..."

     # add repository for nvidia drivers
    zypper --no-gpg-checks addrepo http://www2.ati.com/suse/11.0/ ATI > /dev/null 2>&1 
    # get URLs by virtually installing fglrx-OpenGL driver
    zypper --no-gpg-checks -n -vv install -D ati-fglrxG01-kmp${KSUFFIX} x11-video-fglrxG01 > logfile

    # take unique urls from logfile
    URLS=$(cat logfile |  grep -P -o "http://.*?rpm " | grep fglrx | sort -u | xargs)
    for RPM in $URLS; do
      RNAME=$(echo ${RPM} | sed -e 's,^.*/\(.*\)$,\1,g')
      if [ ! -e ${RNAME} ]; then
        wget ${RPM} > /dev/null 2>&1 
      fi
      # We use rpm2cpio from suse to extract -> propably new rpm version
      rpm2cpio ${RNAME} | ${BUSYBOX} cpio -id > /dev/null
    done
    mv ./usr/X11R6/lib/* ./usr/lib/
   # fix for fglrx_dri.so 
    mkdir -p ./usr/X11R6/lib/modules/dri
    ln -s ../../../../lib/dri/fglrx_dri.so \
    ./usr/X11R6/lib/modules/dri/fglrx_dri.so
    mv ./usr ..
    mv ./etc ..
    find lib/ -name "*.ko" -exec mv {} ../modules \;
#    echo "DEBUG xserver SUSE-GFX-INSTALL.SH ATI"
#    /bin/bash
#    echo "END DEBUG"
  else

    ## SUSE 10.2 Section ##
  
    #TODO: licence information... even suse requires an accept
    BASEURL="http://www2.ati.com/suse/$(lsb_release -r|sed 's/^.*\t//')"
    # if it dont work in the future, check .../repodata/repomd.xml
    wget -q ${BASEURL}/repodata/primary.xml.gz
    gunzip primary.xml.gz
  
    echo "  * Downloading ati rpm packages... this could take some time..."
    # notice the i586! we can also get x86_64!
    for i in $(grep "<location href=.i586" primary.xml \
               |sed 's/.*<location href="//'|sed 's/".*//g')
    do
      wget -c -q ${BASEURL}/${i}
    done
  
    # TODO: move output to /dev/null when main development is over
    ${BUSYBOX} rpm2cpio $(find . -name "x11*")| ${BUSYBOX} cpio -idv > /dev/null
  
    rm -rf ./usr/include
    rm -rf ./usr/lib/pm-utils
    rm -rf ./usr/lib/powersave
    # Todo: recheck after development progress, perhaps an nvidia x11 tool needs /usr/share/pixmaps
    #       same with var id's
    #rm -rf ./usr/share
  
    mv ./usr ..
  
    # TODO: matching kernel problem... our openslx system picks -bigsmp - unintentionally!
    if [ "10.2" = "$(lsb_release -r|sed 's/^.*\t//')" ]; then
      ${BUSYBOX} rpm2cpio $(find . -name "ati-fglrx*bigsmp*") | ${BUSYBOX} cpio -idv > /dev/null
    fi
    if [ "11.0" = "$(lsb_release -r|sed 's/^.*\t//')" ]; then
      ${BUSYBOX} rpm2cpio $(find . -name "ati-fglrx*default*") | ${BUSYBOX} cpio -idv > /dev/null
    fi
    #${BUSYBOX} rpm2cpio nvidia-gfxG01-kmp-default-173.14.12_2.6.18.8_0.10-0.1.i586.rpm | ${BUSYBOX} cpio -idv
    #TODO: take care about the kernel issue. Find won't work with two equal kernelmodules in lib/...
    find lib/ -name "*.ko" -exec mv {} ../modules \;
  fi

  cd ..

  # TODO: after development
  #rm -rf temp/
fi
