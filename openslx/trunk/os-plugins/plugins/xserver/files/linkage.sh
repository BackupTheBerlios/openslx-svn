#!/bin/sh

#
#
# general: linking libGL.so and stuff to writable locations
#
#

PLUGIN_FOLDER="/opt/openslx/plugin-repo/xserver/"
MESA_FOLDER="${PLUGIN_FOLDER}mesa/"
# this has to be writable in stage3 - any folder is possible
LINK_FOLDER="/var/lib/X11R6/xserver/"

# these are to link libs to
ATIROOT="${PLUGIN_FOLDER}ati/atiroot"
NVROOT="${PLUGIN_FOLDER}nvidia/nvroot"

# declare array of conflicting libs
# TODO: add conflicting libs for opengl here
declare -a CONFLIBS=("/usr/lib/libGL.so.1.2" "/usr/lib/libGL.so.1")


if [ ! -d "${MESA_FOLDER}usr/lib/" ]; then
  mkdir -p "${MESA_FOLDER}usr/lib/"
fi
if [ ! -d "${LINK_FOLDER}usr/lib/" ]; then
  mkdir -p "${LINK_FOLDER}usr/lib/"
fi










function linkMesa {
  file=$1
  if [ -f "/${file}" ]; then
    # move file to the mesa implementation folder
    mv "${file}" "${MESA_FOLDER}${file}"
    # create links from link-folder to mesa-folder
    ln -s "${MESA_FOLDER}${file}" "${LINK_FOLDER}${file}"
    # create links from sys-folder to link-folder
    ln -s "${LINK_FOLDER}${file}" "${file}"

  else
    # ${file} is a link here
    rm -rf "${file}"
    case ${file} in
      /usr/lib/libGL.so.1)
        ln -s "${LINK_FOLDER}${file}.2" "${LINK_FOLDER}${file}"
        ;;
      *)
        ;;
    esac
  fi
}










# we create links for all of the binary drivers here 
# - as long as it's possible
# - if not, add to array of link files

# ATI
declare -a ATILIBS=($(find ${ATIROOT} -name "*\\.so*" | xargs))
# with stripped ATIROOT path
declare -a UATILIBS=(${ATILIBS[@]#${ATIROOT}})
for lib in ${UATILIBS[@]}; do
  if [ -e $lib ]; then
    # this is a conflicting MESA-Library
    linkMesa $lib
  fi
done
# NVIDIA
for lib in $(find ${NVROOT} -name "*\\.so*" | xargs); do

done







# go through conflicting libs and link them accordingly
for file in ${CONFLIBS[@]}; do
  linkMesa $file
done





