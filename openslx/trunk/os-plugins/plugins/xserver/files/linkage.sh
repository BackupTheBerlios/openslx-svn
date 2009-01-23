#!/bin/bash


#
#
# general: linking libGL.so and stuff to writable locations
#
#

PLUGIN_PATH="/opt/openslx/plugin-repo/xserver/"
MESA_PATH="${PLUGIN_PATH}mesa/"

# this has to be writable in stage3
LINK_PATH="/var/lib/X11R6/lib/"

# these are to link libs to
ATIROOT="${PLUGIN_PATH}ati"
NVROOT="${PLUGIN_PATH}nvidia"

# declare array of conflicting libs
# TODO: add conflicting libs for opengl here
declare -a CONF_LIBS=("/usr/lib/libGL.so.1.2" "/usr/lib/libGL.so.1")


if [ ! -d "${MESA_PATH}usr/lib/" ]; then
  mkdir -p "${MESA_PATH}usr/lib/"
fi
if [ ! -d "${LINK_PATH}" ]; then
  mkdir -p "${LINK_PATH}"
fi










function linkMesa {
  file=$1
  l_path="${file/$(basename $file)/}"
  if [ ! -d "${LINK_PATH}${l_path}" ]; then
    mkdir -p ${LINK_PATH}${l_path}
  fi
  if [ -f "/${file}" ]; then
    # move file to the mesa implementation PATH
    mv "${file}" "${MESA_PATH}${file}"
    # create links from link-PATH to mesa-PATH
    ln -s "${MESA_PATH}${file}" "${LINK_PATH}${file}"
    # create links from sys-PATH to link-PATH
    ln -s "${LINK_PATH}${file}" "${file}"

  else
    # ${file} is a link here
    rm -rf "${file}"
    case ${file} in
      /usr/lib/libGL.so.1)
        ln -s "${LINK_PATH}${file}.2" "${LINK_PATH}${file}"
        ;;
      *)
        ;;
    esac
  fi
}


# saves a link of all conflicting 
# libraries into ${LINK_PATH}
# and into system root
function divert {

  # root PATH 
  # as first argument
  ROOT="$1"
  # files to compare 
  CMPROOT="$2"

  # get files (withouth module-path - which we set in xorg.conf)
  local -a LIB_ARRAY=($(find ${ROOT} -type f -wholename \
    ".*[^/xorg/modules/].*so.*"|xargs))

  # go through all libs and see if they are conflicting
  for lib in ${LIB_ARRAY[@]}; do
    # strip leading root and add comparing root
    cmplib="${lib#${ROOT}}"
    if [ -e "${cmplib}" -a -e "${lib}" ]; then
      # system conflicts with root
      # - first we copy to MESA_PATH
      # - and create a link to LINK_PATH
      linkMesa ${cmplib}
      continue
    fi
    if [ -e "${lib}" -a -e "${CMPROOT}${cmplib}" ]; then
      # two roots are conflicting
      # create a link into LINK_PATH
      l_path="${cmplib/$(basename $lib)/}"
      if [ ! -d "${LINK_PATH}${l_path}" -o ! -d "${l_path}" ]; then
        mkdir -p ${LINK_PATH}${l_path} ${l_path}
      fi
      touch ${LINK_PATH}${cmplib}
      ln -s ${LINK_PATH}${cmplib} $cmplib
    else
      # just link library to root folder
      l_path="${cmplib/$(basename $lib)/}"
      if [ ! -d "${l_path}" ]; then
        mkdir -p ${l_path}
      fi
      ln -s $lib $cmplib
    fi
  done
}



divert $NVROOT $ATIROOT
divert $ATIROOT $NVROOT






