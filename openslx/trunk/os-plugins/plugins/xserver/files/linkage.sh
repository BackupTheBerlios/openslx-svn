#!/bin/bash

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

# this is the diversion path of libraries
if [ ! -d "${LINK_PATH}" ]; then
  mkdir -p "${LINK_PATH}"
fi


VAL=0 # this is the return value of following helper functions
stripstr() {
  VAL=$(echo ${1} | sed -e "s,^${2},,g")
}
stripbase() {
  VAL=$(echo ${1} | sed -e "s,$(basename ${1}),,g")
}



## additional helper functions without return value
# moves mesa lib to backup
mvmesa() {
  MESALIB="$(echo ${1} | sed -e 's,\.so,_MESA.so,g')"
  mv ${1} ${MESALIB}
}

# makes dir, if not exists
testmkdir() {
  if [ ! -d ${1} ]; then
    mkdir -p ${1}
  fi
}


#######################################
#
#  Link all files FROM $1 to /usr/lib/
#
#  Conflicting files are linked to
#  /var/X11R6/lib
#
#  mesa files are renamed to *_MESA.so*
#
#######################################
divert() {

  ROOT="${1}"
  RR="/usr/lib"
  LPATH="/var/X11R6/lib"

  # link all shared objects in ${1}
  for lib in $(find ${ROOT} -wholename \
	"*/xorg/modules" -prune -a '!' -type d -o -name '*so*'); do

    # strip leading ROOT - to get e.g.: "/usr/lib/libGL.so.1.2"
    stripstr ${lib} ${ROOT}
    rlib=${VAL}
    # strip leading /usr/lib/ - name for /var/X11R6/lib
    stripstr ${rlib} ${RR}
    divname=${VAL}

    #echo "${lib} ${rlib} ${divname} after stripping"

    # divert, if exists
    if [ -e ${rlib} ]; then
      # back up mesa file
      mvmesa ${rlib}
      # link to /var/X11R6/lib
      ln -s ${LPATH}${divname} ${rlib}
    else
      # it does not exist in /usr/lib/
      # just link
      ln -s ${lib} ${rlib}
    fi

  done

  touch ${ROOT}/installed
}


###############################################
# remove all links from system fs
#
# just run this function to clean up system
###############################################
uninstDist() {
  # put mesa implementation back into place
  for file in $(find /usr/lib/ -name '*_MESA.so*' | xargs); do
    mesafile="$(echo ${file}|sed -e 's/_MESA.so/.so/')"
    mv ${file} ${mesafile}
  done

  # somehow we have to repair this - what else? 
  # There is also a generic way, but this is only one file
  ln -sf /usr/lib/libGL.so.1.2 /usr/lib/libGL.so.1
  ln -sf /usr/lib/libGL.so.1.2 /usr/lib/libGL.so

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
  divert $NVROOT
  divert $ATIROOT
#  /bin/bash
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








