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

# Theck for running in graphical environment otherwise no much use here
[ -z "$DISPLAY" ] && echo -e "\n\tStart only within a graphical desktop!\n" \
  && exit 1

# Test if the xml path/file is valid (gotten via commandline first parameter)
xml=$1
[ -e "${xml}" ] || { echo -e "\n\tNo XML file given!\n"; exit 1; }

# Read needed variables from XML file
###############################################################################

# File name of the image
imagename=$(grep -io "<image_name param=.*\"" ${xml} | awk -F "\"" '{ print $2 }')

case ${xml} in 
  /tmp/*)
    # we do not need folder name as it is already included by vmchooser
    diskfile=$imagename
  ;;
  *)
    # Path to the image (readlink produces the absolute path if called relatively)
    [ -z $imgpath ] && \
    { imgpath=$(readlink -f $xml); imgpath=${imgpath%/*.xml}; }
    # Diskfile is file including absolute path to it 
    diskfile=$imgpath/$imagename
  ;;
esac

[ -e $diskfile ] || { echo -e "\n\tImage file $diskfile not found!"; exit 1; }

# Short description of the image (as present in the vmchooser menu line)
short_description=$(grep -o "short_description param=.*\"" ${xml} | \
  sed -e "s/&.*;/; /g" | awk -F "\"" '{print $2}')
# If ${short_description} not defined use ${image_name}
short_description=${short_description:-"${image_name}"}
displayname=${short_description}

# Type of virtual machine to run
virt_mach=$(grep -o "virtualmachine param=.*\"" ${xml} | \
  sed -e "s/&.*;/; /g" | awk -F "\"" '{print $2}')

# Make a guess from the filename extension if ${virt_mach} is empty (not set
# within the xml file)
if [ -z ${virt_mach} ] ; then
  case "$(echo ${imagename##*.}|tr [A-Z] [a-z])" in
    vmdk)
      virt_mach="vmware"
    ;;
    img|qcow*)
      virt_mach="qemukvm"
    ;;
    vbox)
      virt_mach="virtualbox"
    ;;
    *)
      echo "Unknown image type, bailing out"
    ;;
  esac
fi

# Definition of the client system
vmostype=$(grep -io "<os param=.*\"" ${xml} | awk -F "\"" '{ print $2 }')

# Definition of the networking the client system is connected to
network_kind=$(grep -io "<network param=.*\"" ${xml} | awk -F "\"" '{ print $2 }')
network_card=$(grep -io "<netcard param=.*\"" ${xml} | awk -F "\"" '{ print $2 }')

# Serial/parallel ports defined (e.g. "ttyS0" or "autodetect")
serial=$(grep -io "<serialport param=.*\"" ${xml} | awk -F "\"" '{ print $2 }')
parallel=$(grep -io "<parport param=.*\"" ${xml} | awk -F "\"" '{ print $2 }')

# Declaration of default variables
###############################################################################

# Get total amount of memory installed in your machine
totalmem=$(expr $(grep -i "memtotal" /proc/meminfo | awk '{print $2}') / 1024)

# Configuring ethernet mac address: first four bytes are fixed (00:50:56:0D) 
# the last two bytes are taken from the first local network adaptor of the host
# system
mac=$(/sbin/ifconfig eth0 | grep eth0 | sed -e "s/ //g" \
  | awk -F ":" '{print $(NF-1)":"$NF}')

# Virtual fd/cd/dvd and drive devices, floppy b: for configuration file (xml)
floppya="FALSE"
floppyb="TRUE"
floppybname="/etc/vmware/loopimg/fd.img"
cdr_1="FALSE"
cdr_2="FALSE"
# IDE is expected default, test for the virtual disk image type should
# be done while creating the runscripts ...
ide="TRUE"
scsi="FALSE"
hddrv="ide"

# Display resolution within the host system
hostres=$(xvidtune -show 2>/dev/null| grep -ve "^$")
xres=$(echo "${hostres}" | awk '{print $3}')
yres=$(echo "${hostres}" | awk '{print $7}')

# Set hostname: using original hostname and adding string "-vm"
hostname="VM-${HOST}"

# Functions used throughout the script
###############################################################################

# Check for important files used
filecheck ()
{
  filecheck=$(LANG=us ls -lh ${diskfile} 2>&1)
  writelog "Filecheck:\n${filecheck}\n"
  noimage=$(echo ${filecheck} | grep -i "no such file or directory" | wc -l)
  rightsfile=${diskfile}

  # Check if link
  if [ -L "${diskfile}" ]; then
    # take link target
    rightsfile=$(ls -lh ${diskfile} 2>&1 | awk -F "-> *" '{print $2}')
    rightsfile=${vmdir}/${rightsfile}
    filecheck=$(LANG=us ls -lh ${rightsfile} 2>&1)
  fi

  # Does file exist
  if [ "${noimage}" -ge "1" ]; then
    writelog "Virtual Machine Image Problem:\c "
    writelog "\tThe image you've specified doesn't exist."
    writelog "Filecheck says:\c "
    writelog "\t\t${diskfile}:\n\t\t\tNo such file or directory"
    writelog "Hint:\c "
    writelog "\t\t\tCompare spelling of the image with your options.\n"
    exit 1
  fi

  # Readable by calling user
  if ! [ -r "${diskfile}" >/dev/null 2>&1 \
    -o -r "${diskfile}" >/dev/null 2>&1 ]; then
    writelog "Vmware Image Problem:\c "
    writelog "\tThe image you've specified has wrong rights."
    writelog "Filecheck says:\t\t$(echo ${filecheck} \
      | awk '{print $1" "$3" "$4}') ${rightsfile}"
    writelog "Hint:\t\t\tChange rights with: chmod a+r ${rightsfile}\n"
    exit 1
  fi

  # Writable (for persistent-mode)?
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

# Function to write to stdout and logfile
writelog ()
{
  # Write to stdout
  echo -e "$1"

  # Log into file
  echo -e "$1" >>/tmp/run-virt.$$.log
}

# Setup the rest of the environment and run the virtualization tool just confi-
# gured
################################################################################

# The PATH...
export PATH="${PATH}:/var/X11R6/bin:/usr/X11R6/bin"

# Logo for console
cat <<EOL

        .----.--.--.-----.--.--.--.----.-----.
        |   _|  |  |     |  |  |  |   _|_   _|
        |__| |_____|__|__|\___/|__|__|   |_|
OpenSLX script for preparing virtual machine environment ...

EOL


# Adjust sound volume
writelog "Unmuting sound...\c "
amixer -q sset Master 80% unmute 2>/dev/null
amixer -q sset PCM 80% unmute 2>/dev/null
amixer -q sset CD 80% unmute 2>/dev/null
amixer -q sset Headphone 80% unmute 2>/dev/null
amixer -q sset Front 80% umute 2>/dev/null      # In SUSE 11.0 it's Headphone
amixer -q sset Speaker 0 mute 2>/dev/null       # annoying built-in speaker
writelog "finished\n"

# Copy guest configuration (with added information) config.xml to be accessed
# via virtual floppy
# fixme -> to be changed (vmchooser adapts the file content!?)
echo "Please fix the config.xml generation"
cp ${xml} /var/lib/virt/vmchooser/fd-loop/config.xml

# Check if virtual machine container file exists
filecheck

# Get all virtual machine specific stuff from the respective include file
if [ -e /etc/opt/openslx/run-${virt_mach}.include ] ; then
  . /etc/opt/openslx/run-${virt_mach}.include
  # start a windowmanager for player 2+
  # otherwise expect problems with windows opening in background
  if [ "${virt_mach}" = "vmware" ]; then
    case "$vmversion" in
      2.0|6.0|2.5|6.5)
        for dm in metacity kwin fvwm2 ; do
          if which $dm >/dev/null 2>&1 ; then
            if [ "$dm" = "fvwm2" ] ; then
              echo "EdgeScroll 0 0" > ${redodir}/fvwm
              fvwm2 -f ${redodir}/fvwm >/dev/null 2>&1 &
            else
              $dm >/dev/null 2>&1 &
            fi
            break
          fi
        done
      ;;
    esac
  fi
  ${VIRTCMD} ${VIRTCMDOPTS}
  writelog "Bye.\n"
  exit 0
else
  writelog "Failed because of missing ${virt_mach} plugin."
  exit 1
fi

