#!/bin/sh

#
# Currently only suse 10.2 is supported!
#

BUSYBOX="/mnt/opt/openslx/share/busybox/busybox"

cd /opt/openslx/plugin-repo/xserver

#
# NVidia section
#
if [ "$1" = "nvidia" ]; then
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
  if [ "10.2" = "$(lsb_release -r|sed 's/^.*\t//')" ]; then
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

  if [ "11.0" = "$(lsb_release -r|sed 's/^.*\t//')" ]; then
    # add repository for nvidia drivers
    zypper addrepo http://download.nvidia.com/opensuse/11.0/ NVIDIA
    # confirm authenticity of key (once) 
    # -> After key is cached, this is obsolete
    zypper se -r NVIDIA x11-video-nvidiaG01
    # get URLs
    zypper -n -vv install -D x11-video-nvidiaG01 > logfile

    # take unique urls from logfile
    URLS=$(cat logfile |  grep -P -o "http://.*? " | sort -u | xargs)
    for RPM in $URLS; do
      wget ${RPM}
      RNAME=$(echo ${RPM} | sed -e 's,^.*/\(.*\)$,\1,g')
      # TODO: the following is not working - I don't know why...
      ${BUSYBOX} rpm2cpio ${RNAME} | ${BUSYBOX} cpio -idv 
    done
  fi

  cd .. 
  # TODO: after development
  #rm -rf temp/
fi



#
# ATI section
#
if [ "$1" = "ati" ]; then
  mkdir -p ati/modules ati/temp
  cd ati/temp

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

  cd ..

  # TODO: after development
  #rm -rf temp/
fi
