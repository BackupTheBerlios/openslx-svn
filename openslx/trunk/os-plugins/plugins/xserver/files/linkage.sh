#!/bin/bash --debugger

#
#
# general: linking libGL.so and stuff to writable locations
#
#

PLUGIN_PATH="/opt/openslx/plugin-repo/xserver/"

# this has to be writable in stage3
LINK_PATH="/var/X11R6/lib/"

# these are to link libs to
ATIROOT="${PLUGIN_PATH}ati"
NVROOT="${PLUGIN_PATH}nvidia"

# this is a backup folder for mesa files
MESAROOT="${PLUGIN_PATH}mesa/"
if [ ! -d "${MESAROOT}usr/lib/" ]; then
  mkdir -p "${MESAROOT}usr/lib/"
fi
if [ ! -d "${LINK_PATH}" ]; then
  mkdir -p "${LINK_PATH}"
fi





##########################################
# saves a mesa file into MESAROOT
# and creates a link
##########################################
linkMesa() {
  file=$1
 
  # get path without /usr/lib/
  bname=$(basename ${file})
  l_path="$(echo ${file}|sed 's,${bname},,g')"
  l_path="$(echo ${l_path}|sed 's,/usr/lib,,g')"
  if [ ! -d "${LINK_PATH}${l_path}" ]; then
    mkdir -p ${LINK_PATH}${l_path}
  fi

  if [ -h "${file}" ]; then
    # this is a link
    ln -sf ${LINK_PATH}$(echo $file| sed -e 's,/usr/lib,,g') $file # link to writable dir
  elif [ -f "${file}" ]; then
    # this is a real file
    mv ${file} $(echo $file|sed -e 's,.so,_MESA.so,g') 2&>1 >/dev/null # rename file
  fi
}



########################################
# this is the main installation
# 
# ALL conflicting libs are detected
# and linked to /var/X11R6/lib
#
########################################
divert() {

  # root PATH 
  # as first argument
  ROOT="$1"
  # files to compare 
  CMPROOT="$2"

  # go through all libs and see if they are conflicting
  for lib in $(find ${ROOT} -wholename \
	"*/xorg/modules" -prune -a '!' -type d \
	-o -wholename '*so*'|xargs ); do
    # strip leading ROOT
    cmplib="${lib#${ROOT}}"

    echo ${cmplib} ${lib}
    if [ -e "${cmplib}" -a -e "${lib}" ]; then
      # system folder conflicts with ROOT
      linkMesa ${cmplib}
      continue
    fi

    # throwing away the basename
    # leaving the folder
    bname=$(basename ${lib})
    l_path="$(echo ${cmplib}|sed 's,${bname},,g')"
    l_path=${l_path#/usr/lib}

    # here is the hairy function
    # if CMPROOT="", just link the lib
    # if two libs conflicts, link to /var/X11R6/lib/

    if [ -n "${CMPROOT}" -a -e "${lib}" -a -e "${CMPROOT}${cmplib}" ]; then
      # two roots are conflicting
      # create a link into LINK_PATH
      if [ -h "${LINK_PATH}$( echo ${cmplib}| sed 's,/usr/lib,,g')" ]; then
        # it already exists
        continue
      fi
      if [ ! -d "${LINK_PATH}${l_path}" -o ! -d "${l_path}" ]; then
        mkdir -p ${LINK_PATH}${l_path} ${l_path}
      fi
      
      # create link ladder (defaults to first called implementation)
      #TODO: Check this part. Every 2nd time of 'linkage.sh clean;linkage.sh both'
      #      the following error occurs:
      #      ln: creating symbolic link `/var/X11R6/lib//libGL.so.1/libGL.so.1': File exists
      ln -s ${ROOT}${cmplib} ${LINK_PATH}$(echo ${cmplib} | sed -e 's/\/usr\/lib//g')
    else


      # just link library to root folder
      # nothing conflicts here
      l_path="${cmplib/$(basename $lib)/}"
      if [ ! -d "${l_path}" ]; then
        mkdir -p ${l_path}
      fi
      ln -s $lib $cmplib
    fi
  done
}



###############################################
# remove all links from system fs
#
# just run this function to clean up system
###############################################
function uninstDist() {
  # put mesa implementation back into place
  for file in $(find /usr/lib/ -name '*_MESA.so*' | xargs); do
    mesafile="$(echo ${file}|sed -e 's/_MESA.so/.so/')"
    mv ${file} ${mesafile}
  done

  # somehow we have to repair this - what else? 
  # There is also a generic way, but this is only one file
  ln -sf /usr/lib/libGL.so.1.2 /usr/lib/libGL.so.1

  # delete all remaining links to /opt/openslx and /var/X11R6/lib
  find /usr/lib -lname "${PLUGIN_PATH}*"  \
    -o -lname "${LINK_PATH}*" |xargs rm -rf 
  # delete LINK_PATH
  rm -rf ${LINK_PATH} 
}

if [ "$1" = "clean" ]; then
  uninstDist
  exit
fi 

if [ "$1" = "both" ]; then
  divert $NVROOT $ATIROOT
  divert $ATIROOT $NVROOT
  exit
fi

if [ "$1" = "nvidia" ]; then
  divert ${NVROOT}
  exit
fi

if [ "$1" = "ati" ]; then
  divert ${ATIROOT}
  exit
fi








