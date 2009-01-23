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
function linkMesa() {
  file=$1
 
  # get path without /usr/lib/
  l_path="${file/$(basename $file)/}"
  l_path=${l_path/\/usr\/lib/}
  if [ ! -d "${LINK_PATH}${l_path}" ]; then
    mkdir -p ${LINK_PATH}${l_path}
  fi

  if [ -e "/${file}" ]; then
    file=${file/\/usr\/lib/}
    # move file to the mesa implementation PATH
    mv "/usr/lib/${file}" "${MESAROOT}${file}" >/dev/null 2&>1
    # create links from link-PATH to mesa-PATH
    ln -s "${MESAROOT}${file}" "${LINK_PATH}${file}"
    # create links from sys-PATH to link-PATH
    ln -s "${LINK_PATH}${file}" "/usr/lib/${file}"
  fi
}



########################################
# this is the main installation
# 
# ALL conflicting libs are detected
# and linked accordingly 
#
# saves a link of all conflicting 
# libraries into ${LINK_PATH}
# and into system root
########################################
function divert() {

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


    if [ -f "${cmplib}" -a -f "${lib}" ]; then
      # system folder conflicts with ROOT
      linkMesa ${cmplib}
      continue
    fi

    # throwing away the basename
    # leaving the folder
    l_path="${cmplib/$(basename $lib)/}"
    l_path=${l_path#/usr/lib}

    # here is the hairy thing
    # if CMPROOT="", just link the lib
    # if two libs conflicts, link to /var/X11R6/lib/

    if [ -n "${CMPROOT}" -a -e "${lib}" -a -e "${CMPROOT}${cmplib}" ]; then
      # two roots are conflicting
      # create a link into LINK_PATH
      if [ -h "${l_path}${cmplib}" ]; then
        # it already exists
        continue
      fi
      if [ ! -d "${LINK_PATH}${l_path}" -o ! -d "${l_path}" ]; then
        mkdir -p ${LINK_PATH}${l_path} ${l_path}
      fi
      
      # create link ladder (defaults to first called implementation)
      ln -s ${ROOT}${cmplib} ${LINK_PATH}${cmplib}
      ln -s ${LINK_PATH}${cmplib} $cmplib
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
  # put mesa implementation back to 
  mv ${MESAROOT}/usr/* /usr/lib/

  # somehow we have to repair this
  ln -sf /usr/lib/libGL.so.1.2 /usr/lib/libGL.so.1

  # delete all remaining links to /opt/openslx and /var/X11R6/lib
  find /usr/lib -lname "${PLUGIN_PATH}*"  \
    -o -lname "${LINK_PATH}*" |xargs rm -rf 
  # delete LINK_PATH
  rm -rf ${LINK_PATH}  # we could also delete ${MESAROOT}

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








