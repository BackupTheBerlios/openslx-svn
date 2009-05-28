#!/bin/bash
# -----------------------------------------------------------------------------
# Copyright (c) 2007..2009 - RZ Uni FR
# Copyright (c) 2007..2009 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your suggestions, praise, or complaints to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org/
# -----------------------------------------------------------------------------
# run-virt.sh
#    - This is the generic wrapper for the several virtualization solutions.
#      The idea is to setup a set of variables used by at least two different
#      tools and then include the specific plugin which configures the speci-
#      fied virtualization tool.
# -----------------------------------------------------------------------------

# Sanity checks
###############################################################################

# check for running in graphical environment otherwise no much use here
[ -z "$DISPLAY" ] && echo -e "\n\tStart only within a graphical desktop!\n" \
  && exit 1

# test if the xml path/file is valid (gotten via commandline first parameter)
xml=$1
[ -e "${xml}" ] || { echo -e "\n\tNo XML file given!\n"; exit 1; }

# Read needed variables from XML file
###############################################################################

# file name of the image
imagename=$(grep -io "<image_name param=.*\"" ${xml} | awk -F "\"" '{ print $2 }')
diskfile=$imagename
[ -e $diskfile ] || { echo -e "\n\tImage file $diskfile not found!"; exit 1; }

# short description of the image (as present in the vmchooser menu line)
short_description=$(grep -o "short_description param=.*\"" ${xml} | \
  sed -e "s/&.*;/; /g" | awk -F "\"" '{print $2}')
# if ${short_description} not defined use ${image_name}
short_description=${short_description:-"${image_name}"}
displayname=${short_description}

# type of virtual machine to run
virt_mach=$(grep -o "virtualmachine param=.*\"" ${xml} | \
  sed -e "s/&.*;/; /g" | awk -F "\"" '{print $2}')

# make a guess from the filename extension if ${virt_mach} is empty (not set
# within the xml file)
if [ -z ${virt_mach} ] ; then
  case "${imagename##*.}" in
    vmdk|VMDK)
      virt_mach="vmware"
    ;;
    img|IMG|qcow*|QCOW*)
      virt_mach="qemukvm"
    ;;
    vbox|VBOX)
      virt_mach="qemukvm"
    ;;
  esac
fi

# definition of the client system
vmostype=$(grep -io "<os param=.*\"" ${xml} | awk -F "\"" '{ print $2 }')

# definition of the networking the client system is connected to
network_kind=$(grep -io "<network param=.*\"" ${xml} | awk -F "\"" '{ print $2 }')

# serial port defined (e.g. "ttyS0" or "autodetect")
serial=$(grep -io "<serial port=.*\"" ${xml} | awk -F "\"" '{ print $2 }')


# declaration of default variables
###############################################################################

# standard variables

# get total amount of memory installed in your machine
totalmem=$(expr $(grep -i "memtotal" /proc/meminfo | awk '{print $2}') / 1024)

# configuring ethernet mac address: first four bytes are fixed (00:50:56:0D) 
# the last two bytes are taken from the first local network adaptor of the host
# system
mac=$(/sbin/ifconfig eth0 | grep eth0 | sed -e "s/ //g" \
  | awk -F ":" '{print $(NF-1)":"$NF}')

echo "$totalmem, $mac"

# virtual fd/cd/dvd and drive devices, floppy b: for configuration
#floppya is always false, if we have a floppy device or not isn't
#important.
floppya="FALSE"
floppyb="TRUE"
floppybname="/etc/vmware/loopimg/fd.img"
cdr_1="FALSE"
cdr_2="FALSE"
# ide is expected default, test for the virtual disk image type should
# be done while creating the runscripts ...
ide="TRUE"
scsi="FALSE"
hddrv="ide"

# display resolution
hostres=$(xvidtune -show 2>/dev/null| grep -ve "^$")
xres=$(echo "${hostres}" | awk '{print $3}')
yres=$(echo "${hostres}" | awk '{print $7}')

# set hostname: using original hostname and adding string "-vm"
hostname="VM-${HOST}"

# functions used throughout the script
###############################################################################

# check for files
filecheck ()
{
  filecheck=$(LANG=us ls -lh ${diskfile} 2>&1)
  writelog "Filecheck:\n${filecheck}\n"
  #TODO: don't understand the sence in it
  noimage=$(echo ${filecheck} | grep -i "no such file or directory" | wc -l)
  rightsfile=${diskfile}

  # check if link
  # TODO: mistake with 2nd rightsfile if its in another directory?
  if [ -L "${diskfile}" ]; then
    # take link target
    rightsfile=$(ls -lh ${diskfile} 2>&1 | awk -F "-> *" '{print $2}')
    rightsfile=${vmdir}/${rightsfile}
    filecheck=$(LANG=us ls -lh ${rightsfile} 2>&1)
  fi

  # does file exist
  if [ "${noimage}" -ge "1" ]; then
    writelog "Virtual Machine Image Problem:\c "
    writelog "\tThe image you've specified doesn't exist."
    writelog "Filecheck says:\c "
    writelog "\t\t${diskfile}:\n\t\t\tNo such file or directory"
    writelog "Hint:\c "
    writelog "\t\t\tCompare spelling of the image with your options.\n"
    exit 1
  fi

  # readable?
  if ! [ -r "${diskfile}" >/dev/null 2>&1 \
    -o -r "${diskfile}" >/dev/null 2>&1 ]; then
    writelog "Vmware Image Problem:\c "
    writelog "\tThe image you've specified has wrong rights."
    writelog "Filecheck says:\t\t$(echo ${filecheck} \
      | awk '{print $1" "$3" "$4}') ${rightsfile}"
    writelog "Hint:\t\t\tChange rights with: chmod a+r ${rightsfile}\n"
    exit 1
  fi

  # writable (for persistent-mode)?
  if ! [ -w "${diskfile}" >/dev/null 2>&1 \
    -o -w "${diskfile}" >/dev/null 2>&1 ] \
    && [ "${np}" = "independent-persistent" ]; then
    writelog "Vmware Image Problem:\c "
    writelog "\tThe image you have specified has wrong rights."
    writelog "Filecheck says:\t\t$(echo ${filecheck} \
      | awk '{print $1" "$3" "$4}') ${rightsfile}"
    writelog "Hint:\t\t\tUse nonpersistent-mode or change rights to rw\n"
    exit 1
  fi
}

# function to write to stdout and logfile
writelog ()
{
  # write to stdout
  echo -e "$1"

  # log into file
  echo -e "$1" >>run-virt.log
}

# setup the rest of the environment and run the virtualization tool just confi-
# gured
################################################################################

# The PATH...
export PATH="${PATH}:/var/X11R6/bin:/usr/X11R6/bin"

# logo for console
cat <<EOL

     .----.--.--.-----.--.--.--------.--.--.--.---.-.----.-----.
     |   _|  |  |     |  |  |        |  |  |  |  _  |   _|  -__|
     |__| |_____|__|__|\___/|__|__|__|________|___._|__| |_____|
         Script for preparing virtual machine environment ...

EOL


# adjust volume
writelog "Unmuting sound...\c "
amixer -q sset Master 28 unmute 2>/dev/null
amixer -q sset PCM 28 unmute 2>/dev/null
amixer -q sset Headphone 28 unmute 2>/dev/null
amixer -q sset Front 0 mute 2>/dev/null
writelog "finished\n"

# copy guest configuration config.xml to be accessed via virtual floppy
cp ${xml} /var/lib/virt/vmchooser/fd-loop/config.xml

# check if virtual machine container file exists
filecheck


# get all virtual machine specific stuff from the respective include file
if [ -e /etc/opt/openslx/run-${virt_mach}.include ] ; then
  . /etc/opt/openslx/run-${virt_mach}.include
  ${VIRTCMD} ${VIRTCMDOPTS}
  writelog "Bye.\n"
  exit 0
else
  writelog "Failed because of missing ${virt_mach} plugin."
  exit 1
fi

