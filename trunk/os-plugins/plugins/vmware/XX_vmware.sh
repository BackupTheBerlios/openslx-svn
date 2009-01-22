#! /bin/sh

# check if the configuration file is available
if [ -e /initramfs/plugin-conf/vmware.conf ]; then

	# load needed variables
	. /initramfs/plugin-conf/vmware.conf

	# Test if this plugin is activated
	if [ $vmware_active -ne 0 ]; then

		[ $DEBUGLEVEL -gt 0 ] && echo "executing the 'vmware' os-plugin ...";
		
		# Load general configuration
		. /initramfs/machine-setup
		# we need to load the function file for:
		# uri_token, testmkd
		. /etc/functions
		# D_INITDIR is defined in the following file:
		. /etc/sysconfig/config
		
		echo "  * vmware part 1"
		#############################################################################
		# vmware stuff first part: two scenarios
		# * VM images in /usr/share/vmware - then simply link
		# * VM images via additional mount (mount source NFS, NBD, ...)
		if [ "x${vmware}" != "x" ] && [ "x${vmware}" != "xno" ] ; then
		  # map slxgrp to pool, so it's better to understand
		  pool=${slxgrp}
		  # if we dont have slxgrp defined
		  [ -z "${pool}" ] && pool="default"
		
		  # get source of vmware image server (get type, server and path)
		  if strinstr "/" "${vmware}" ; then
		    vmimgprot=$(uri_token ${vmware} prot)
		    vmimgserv=$(uri_token ${vmware} server)
		    vmimgpath="$(uri_token ${vmware} path)"
		  fi
		  if [ -n "${vmimgserv}" ] ; then
		    testmkd /mnt/var/lib/vmware
		    case "${vmimgprot}" in
		      *nbd)
		      ;;
		      lbdev)
		        # we expect the stuff on toplevel directory, filesystem type should be
		        # autodetected here ... (vmimgserv is blockdev here)
		        vmbdev=/dev/${vmimgserv}
		        waitfor ${vmbdev} 20000
		        echo -e "ext2\nreiserfs\nvfat\nxfs" >/etc/filesystems
		        mount -o ro ${vmbdev} /mnt/var/lib/vmware || error "$scfg_evmlm" nonfatal
		      ;;
		      *)
		        # we expect nfs mounts here ...
		        for proto in tcp udp fail; do
		          [ $proto = "fail" ] && { error "$scfg_nfs" nonfatal;
		            noimg=yes; break;}
		          mount -n -t nfs -o ro,nolock,$proto ${vmimgserv}:${vmimgpath} \
		            /mnt/var/lib/vmware && break
		        done
		      ;;
		    esac
		  fi
		fi
		
		echo "  * vmware part 2"
		
		#############################################################################
		# vmware stuff second part: setting up the environment
		
		# create needed directories and files
		if [ "x${vmware}" != "x" ] && [ "x${vmware}" != "xno" ] ; then
		  for i in /etc/vmware/vmnet1/dhcpd /etc/vmware/vmnet8/nat \
		           /etc/vmware/vmnet8/dhcpd /var/run/vmware /etc/vmware/loopimg \
		           /etc/vmware/fd-loop /var/X11R6/bin /etc/X11/sessions; do
		    testmkd /mnt/$i
		  done
		  # create needed devices (not created automatically via module load)
		  for i in "/dev/vmnet0 c 119 0" "/dev/vmnet1 c 119 1" \
		           "/dev/vmnet8 c 119 8" "/dev/vmmon c 10 165"; do
		    mknod $i
		  done
		  # create the vmware startup configuration file /etc/vmware/locations
		  # fixme --> ToDo
		  # echo -e "answer VNET_8_NAT yes\nanswer VNET_8_HOSTONLY_HOSTADDR \n\
		  #192.168.100.1\nanswer VNET_8_HOSTONLY_NETMASK 255.255.255.0\n\
		  #file /etc/vmware/vmnet8/dhcpd/dhcpd.conf\n\
		  # remove_file /etc/vmware/not_configured" >/mnt/etc/vmware/locations
		
		  chmod 0700 /dev/vmnet*
		  chmod 1777 /mnt/etc/vmware/fd-loop
		  # loop file for exchanging information between linux and vmware guest
		  if modprobe ${MODPRV} loop; then
		    mdev -s
		  else
		    : #|| error "" nonfatal
		  fi
		  # mount a clean tempfs (bug in UnionFS prevents loopmount to work)
		  strinfile "unionfs" /proc/mounts && \
		    mount -n -o size=1500k -t tmpfs vm-loopimg /mnt/etc/vmware/loopimg
		  # create an empty floppy image of 1.4MByte size
		  dd if=/dev/zero of=/mnt/etc/vmware/loopimg/fd.img \
		    count=2880 bs=512 2>/dev/null
		  chmod 0777 /mnt/etc/vmware/loopimg/fd.img
		  # use dos formatter from rootfs (later stage4)
		  LD_LIBRARY_PATH=/mnt/lib /mnt/sbin/mkfs.msdos \
		    /mnt/etc/vmware/loopimg/fd.img >/dev/null 2>&1 #|| error
		  mount -n -t msdos -o loop,umask=000 /mnt/etc/vmware/loopimg/fd.img \
		    /mnt/etc/vmware/fd-loop
		  echo -e "usbfs\t\t/proc/bus/usb\tusbfs\t\tauto\t\t 0 0" >> /mnt/etc/fstab
		  # needed for VMware 5.5.3 and versions below
		  echo -e "\tmount -t usbfs usbfs /proc/bus/usb 2>/dev/null" \
		    >>/mnt/etc/${D_INITDIR}/boot.slx
		  # TODO: we still use this function? Prove if we can delete it.
		  config_vmware
          chmod 1777 /mnt/var/run/vmware
          # define a variable where gdm/kdm should look for additional sessions
          # do we really need it? looks like we can delete it...
          # export vmsessions=/var/lib/vmware/vmsessions
		
		  # we configured vmware, so we can delete the not_configured file
		  rm /mnt/etc/vmware/not_configured 2>/dev/null
		
		  # copy dhcpd.conf and nat for vmnet8 (nat)
		  # fixme: It should be possible to start just one vmware dhcp which should
		  # listen to both interfaces vmnet1 and vmnet8 ...
		  #TODO: copy it from plugin source...
		  cp /mnt/var/lib/vmware/templates/dhcpd.conf \
		    /mnt/etc/vmware/vmnet8/dhcpd 2>/dev/null
		  cp /mnt/var/lib/vmware/templates/nat.conf \
		    /mnt/etc/vmware/vmnet8/nat 2>/dev/null
		fi

		# TODO: plugin should copy it... find out how
		# TODO: perhaps we can a) kick out vmdir
		#                      b) configure vmdir by plugin configuration
		# TODO: How to start it. See Wiki. Currently a) implemnted
		#   a) we get get information and start the programm with
		#      /var/X11R6/bin/run-vmware.sh "$imagename" "$name_for_vmwindow" "$ostype_of_vm" "$kind_of_network"
		#   b) we write a wrapper and get the xml-file as attribute
	        cat <<EOF > /mnt/var/X11R6/bin/run-vmware.sh
#!/bin/bash
#
# Description:  Script for preparing VMware environment Diskless
#               X Stations and interactive session chooser (v4)
#
# Author(s):    see project authors file
#               letzte Änderung Dirk, 15.10.
# Copyright:    (c) 2003, 2006 - RZ Universitaet Freiburg
#
# Version:      0.16.611
#
################################################################################


################################################################################
##
## Put $HOME to another location
##
################################################################################

# We need to change $HOME so it saves everything to /tmp
#export HOME="/tmp/${USER}"
# following mkdir we have now twice in this script... but better twice
# as not seperated. Now its no problem to delete this
# "Put $HOME to another location" section later
#mkdir /tmp/${USER}
#ln -s /home/${USER}/.Xauthority /tmp/${USER}/.Xauthority



### VARIABLES SECTION ##########################################################
##
## declaration of default variables
##
################################################################################

## "static" variables only changed within the script

# The PATH...
export PATH="\${PATH}:/var/X11R6/bin:/usr/X11R6/bin"

# Last two values for MAC address
mac=

# memory information. permem is value to calculate needed memory
mem=
totalmem=
permem=66

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
hddrv="lsilogic"

# Displayresolution needed for vmware.config
hostres=\$(xvidtune -show 2>/dev/null| grep -ve "^$")
xres=\$(echo "\${hostres}" | awk '{print \$3}')
yres=\$(echo "${hostres}" | awk '{print \$7}')

# VMplayer buildversion
vmbuild=

# VMware start options
#-X = fullscreen
vmopt="-X"

# temporary disk space for logs, etc...
# use /tmp/vmware/\${USER} if /tmp sits on NFS import
export tmpdir=/tmp/\${USER}

# configfile
confile="\${tmpdir}/runvmware.conf"

# users vmware config folder
vmhome="\${HOME}/.vmware"
#vmhome="/tmp/\${USER}/.vmware"


# unknow variables needed vor vmwplayer configuration
confver=8
hver=4

# set hostname: using original hostname and adding string "-vm"
# variable isn't used anywhere in this script. but still works (however)
# TODO: Test it commented out
hostname="VM-\${HOST}"

# Folder of VirtualMachine Images
vmdir="/var/lib/vmware"

# special Variables, persistence vmware?
#TODO: do we really need it? Should be everywhere nonpersistent
np="independent-nonpersistent"

########
## TODO: everything clean till here
########

# File if its a link. Stupid crap
#TODO: perhaps we don't need it
rightsfile=
#TODO: don't know what it is for. check later
noimage=0
# image checking variable
filecheck=


## Image depending variables. This values will be changed by the script

# vmware image file
imagename="\$1"
diskfile="\${vmdir}/\${imagename}"

#TODO: check for a faster way, perhaps we should put this into XML
# oh - yeah!! Why not do it on the SERVER??? It has enough power and has
# to do it once and not during every start on a client :)
#grepping every file could take much (network) resources. And if its
#an IDE Image, but has somewhere the string ddb.adapterType stuff can
#become screwed
# NOOOOOOO - We do not check on every start on every client!!!
# check if IDE or SCSI
#hddrv=\$(grep -m 1 -ia "ddb.adapterType" \${diskfile} | awk -F "\"" '{print \$2}')
#if [ "\${hddrv}" = "ide" ]; then
#  ide="TRUE"
#  scsi="FALSE"
#elif [ "\${hddrv}" = "lsilogic" ]; then
#  ide="FALSE"
#  scsi="TRUE"  
#elif [ "\${hddrv}" = "buslogic" ]; then
#  ide="FALSE"
#  scsi="TRUE"  
#fi

# define name for VMware window
displayname="\$2"

# Definition of the client system
vmostype="\$3"

# Definition of the client system
network="\$4"


# command line variables
# start with this this default commmand line options + extra
# TODO: defaults laut datei --include /var/lib/vmware/tmpl/winconfig
#     --include <includefile> include code right before program start

# Should we debug? Hell yes, we should always debug!
debug=0

#TODO: Bad done... we should do this another way later
last_changes=\$(head -n 15 \$0 | grep "@" | awk -F ", " '{print \$2}' \
  | awk -F "-" '{print \$3" "\$2" "\$1}' | sort -bfnr \
  | awk '{print \$3"-"\$2"-"\$1}' | grep -m 1 [0-9])
version=\$(head -n 15 \$0 | grep "# Version: " | awk '{print \$3}')

#############
## TODO: End of uncleaned area
#############






### FUNCTION SECTION ###########################################################
##
## In this script used functions
##
################################################################################

### write runvmware.conf #######################################################
#TODO: only not yet checked function
filecheck ()
{
  filecheck=\$(LANG=us ls -lh \${diskfile} 2>&1)
  writelog "Filecheck:\n\${filecheck}\n"
  #TODO: don't understand the sence in it
  noimage=\$(echo \${filecheck} | grep -i "no such file or directory" | wc -l)
  rightsfile=\${diskfile}

  # check if link
  # TODO: mistake with 2nd rightsfile if its in another directory?
  if [ -L "\${diskfile}" ]; then
    # take link target
    rightsfile=\$(ls -lh \${diskfile} 2>&1 | awk -F "-> *" '{print \$2}')
    rightsfile=\${vmdir}/\${rightsfile}
    filecheck=\$(LANG=us ls -lh \${rightsfile} 2>&1)
  fi

  # does file exist
  if [ "\${noimage}" -ge "1" ]; then
    writelog "Vmware Image Problem:\c"
    writelog "\tThe image you've specified doesn't exist."
    writelog "Filecheck says:\c"
    writelog "\t\t\${diskfile}:\n\t\t\tNo such file or directory"
    writelog "Hint:\c"
    writelog "\t\t\tCompare spelling of the image with your options.\n"
    exit 1
  fi

  # readable?
  if ! [ -r "\${diskfile}" >/dev/null 2>&1 \
    -o -r "\${diskfile}" >/dev/null 2>&1 ]; then
    writelog "Vmware Image Problem:\c"
    writelog "\tThe image you've specified has wrong rights."
    writelog "Filecheck says:\t\t\$(echo \${filecheck} \
      | awk '{print \$1" "\$3" "\$4}') \${rightsfile}"
    writelog "Hint:\t\t\tChange rights with: chmod a+r \${rightsfile}\n"
    exit 1
  fi

  # writable (for persistent-mode)?
  if ! [ -w "\${diskfile}" >/dev/null 2>&1 \
    -o -w "\${diskfile}" >/dev/null 2>&1 ] \
    && [ "\${np}" = "independent-persistent" ]; then
    writelog "Vmware Image Problem:\c"
    writelog "\tThe image you've specified has wrong rights."
    writelog "Filecheck says:\t\t\$(echo \${filecheck} \
      | awk '{print \$1" "\$3" "\$4}') \${rightsfile}"
    writelog "Hint:\t\t\tUse nonpersistent-mode or change rights to rw\n"
    exit 1
  fi
}


### write runvmware.conf #######################################################
runvmwareconfheader ()
{
  echo "
  ##############################################################################
  ###### This configuration file was generated by 'runvmware',            ######
  ###### dont use it for your own configurations - it will be overwritten ######
  ######                                                                  ######

  ###### identity ##############################################################
  displayName = \"\${displayname}\"
  guestOS = \"\${vmostype}\"
  config.version = \"\${confver}\"
  virtualHW.version = \"\${hver}\"

  memsize = \"\${mem}\"
  numvcpus = \"1\"

  ###### ide-disks #############################################################
  ide0:0.mode = \"\${np}\"
  ide0:0.present = \"\${ide}\"
  ide0:0.fileName = \"\${diskfile}\" 

  ide1:0.present = \"\${cdr_1}\"
  ide1:0.autodetect = \"TRUE\"
  ide1:0.fileName = \"auto detect\"
  ide1:0.deviceType = \"cdrom-raw\"

  ide1:1.present = \"\${cdr_2}\"
  ide1:1.autodetect = \"TRUE\"
  ide1:1.fileName = \"auto detect\"
  ide1:1.deviceType = \"cdrom-raw\"

  ###### scsi-disks ############################################################
  scsi0.present = \"\${scsi}\"
  scsi0.virtualDev = \"lsilogic\"
  scsi0:0.mode = \"\${np}\"
  scsi0:0.present = \"\${scsi}\"
  scsi0:0.fileName = \"\${diskfile}\"

  ###### nics ##################################################################
  ethernet0.present = \"TRUE\"
  ethernet0.addressType = \"static\"
  ethernet0.connectionType = \"\${network}\"
  ethernet0.address = \"00:50:56:0D:\${mac}\"

  ###### sound #################################################################
  sound.present = \"TRUE\"
  sound.virtualDev = \"es1371\"

  ###### usb ###################################################################
  usb.present = \"TRUE\"
  usb.generic.autoconnect = \"TRUE\"

  ###### floppies ##############################################################
  floppy0.present = \"\${floppya}\"
  floppy0.fileName = \"auto detect\"

  # we need floppy b: this for our windows client configuration
  floppy1.present = \"\${floppyb}\"
  floppy1.fileType = \"file\"
  floppy1.fileName = \"\${floppybname}\"
  floppy1.startConnected = \"TRUE\"

  ###### ports #################################################################
  parallel0.present = \"FALSE\"

  serial0.present = \"FALSE\"

  ###### shared folders ########################################################
  sharedFolder0.present = \"TRUE\"
  sharedFolder0.enabled = \"TRUE\"
  sharedFolder0.expiration = \"never\"
  sharedFolder0.guestName = \"Home\"
  sharedFolder0.hostPath = \"\${HOME}\"
  sharedFolder0.readAccess = \"TRUE\"
  sharedFolder0.writeAccess = \"TRUE\"
  sharedFolder.maxNum = \"1\"

  ###### misc ##################################################################
  tmpDirectory = \"\${tmpdir}\"
  mainMem.useNamedFile = \"TRUE\"
  snapshot.disabled = \"TRUE\"
  tools.syncTime = \"TRUE\"
  # use redoLogDir = \"/dev/shm\" if sitting on NFS import
  redoLogDir = \"\${tmpdir}\"
  hints.hideAll = \"TRUE\"
  logging = \"FALSE\"
  isolation.tools.hgfs.disable = \"FALSE\"
  isolation.tools.dnd.disable = \"TRUE\"
  isolation.tools.copy.enable = \"TRUE\"
  isolation.tools.paste.enabled = \"TRUE\"
  gui.restricted = \"TRUE\"
  pref.hotkey.shift = \"TRUE\"
  pref.hotkey.control = \"TRUE\"
  pref.hotkey.alt = \"TRUE\"
  svga.maxWidth = \"\${xres}\"
  svga.maxHeight = \"\${yres}\"
  " \
  >\${confile}

  # set the appropriate permissions for the vmware config file
  chmod u+rwx \${confile} >/dev/null 2>&1
}


### creates user configurationfile in \${vmhome} ################################
preferencesheader ()
{
  echo "
  ##############################################################################
  ###### This configuration file was generated by 'runvmware',            ######
  ###### dont use it for your own configurations - it will be overwritten ######
  ######                                                                  ######
  ################################## Wichtig! ##################################
  ###### *.vmem wird immer angelegt und frisst soviel Speicher, wie fuer  ######
  ###### den Gast vorgesehen. Sollte nicht im tempfs liegen. NFS OK, da   ######
  ###### IO nur einmal beim Start erheblich. Wird gesteuert ueber         ######
  ###### tmpDirectory = /nfs-viel-platz und darin wird dann vmware-\$user ######
  ###### angelegt.        

  hints.hideAll = \"true\"
  pref.exchangeSelections = \"true\"
  pref.hotkey.shift = \"true\"
  pref.tip.startup = \"false\"
  pref.vmplayer.exit.vmAction = \"poweroff\"
  pref.vmplayer.fullscreen.autohide = \"true\"
  pref.vmplayer.webUpdateOnStartup = \"false\"
  prefvmx.defaultVMPath = \"\${vmhome}\"
  prefvmx.mru.config = \"\${confile}:\"
  tmpDirectory = \"\${tmpdir}\"
  webUpdate.checkPeriod = \"manual\"
  pref.eula.size = \"2\"
  pref.eula.0.appName = \"VMware Player\"
  pref.eula.0.buildNumber = \"\${vmbuild}\"
  pref.eula.1.appName = \"VMware Workstation\"
  pref.eula.1.buildNumber = \"\${vmbuild}\"
  " \
  >\${vmhome}/preferences
}


### log function ###############################################################
# function to write to stdout and logfile
writelog ()
{
  # write to stdout
  echo -e "\$1"

  # log in file
  echo -e "\$1" >>\${tmpdir}/runvmware.\${USER}.log
}




### MAIN SECTION ###############################################################
##
## Main part of the script...
##
################################################################################

# Delete the LOCK file. its unsecure, but ...
rm -f \${tmpdir}/*LOCK >/dev/null 2>&1

# create vmware directories
mkdir -p \${tmpdir} >/dev/null 2>&1
mkdir -p \${vmhome} >/dev/null 2>&1

# NO X-server, no runvmware ;)
[ -z "\$DISPLAY" ] && echo -e "\n\tStart only within a desktop!\n" && exit 1

# logo for console
cat <<EOL

           .----.--.--.-----.--.--.--------.--.--.--.---.-.----.-----.
           |   _|  |  |     |  |  |        |  |  |  |  _  |   _|  -__|
           |__| |_____|__|__|\___/|__|__|__|________|___._|__| |_____|
                Script for preparing VMware environment...(v\${version})


EOL


### CHECK MACHINE SETUP ########################################################

## log script information
writelog "##################################################\n"
writelog "# File created by \$0 (v.\${version})\n# on \$(date)\n"
writelog "##################################################\n"
writelog "Starting...\$(echo \${np} | sed 's/i.*-//g' \
  | tr [a-z] [A-Z])-mode\n"

## log disksetup
writelog "Directories:
  \tTmpdir:\t\t\${tmpdir}\n\tVMhome:\t\t\${vmhome}\n\tTmpdir info:\
  \t\$(mount | grep -i "/tmp ")\n"

## configuring MAC address: first four bytes are fixed (00:50:56:0D) the
## last two bytes are taken from the local network adaptor
writelog "Starting hardware / device detection...\c"

## Get last two MAC values for VMPlayer
# NF = Number of Fields of found values in awk
mac=\$(/sbin/ifconfig eth0 | grep eth0 | sed -e "s/ //g" \
  | awk -F ":" '{print \$(NF-1)":"\$NF}')


## check if we have enough free memory

# get memory in MB
totalmem=\$(expr \$(grep -i "memtotal" /proc/meminfo | awk '{print \$2}') / 1024)

# calculate memory for vmplayer
# TODO: unhappy how it is calculated
mem=\$(expr \${totalmem} / 100 \* \${permem} / 4 \* 4)

# check memory range
memtest=\${totalmem}-128
if [ "\${mem}" -lt "128" ] || [ "\${mem}" -gt "\${totalmem}" ]; then
  writelog "\n\n\tYour memory is out of range: \${mem} MB.
    \tMin. 128 MB for host and guest!\n\tTry --mem option.\n"
  exit 1
fi


## look for cdrom, dvd and add them to the vm config file
if [ -L /dev/cdrom ] ; then
  cdr_1="TRUE"
fi

if [ -L /dev/cdrom1 ] ; then
  cdr_2="TRUE"
fi


## Write all results to logfile
writelog "finished\nResults:\n\tMAC:\t\t00:50:56:0D:\${mac}\n\tMem:\t\t
  \${mem} MB \tMax. res.:\t\${xres}x\${yres}\n\t\tCD-ROM_1:\t\${cdr_1}\n\t
  CD-ROM_2:\t\${cdr_2}\n"
writelog "finished\nResults:\n\tDiskfile:\t\${diskfile}\n\tDisktype:\t\${hddrv}
  \tVMostype:\t\${vmostype}\n\tDisplayname:\t\${displayname}\n"

# check if image exists, etc...
filecheck

# VMPlayer Version.
# strings is the fastest and most secure way, vmplayer -v takes too much time
# and resources
vmbuild=\$(strings /usr/lib/vmware/bin/vmplayer \
    | grep -m 1 "build-"|sed 's/.*build-//')
if [ ! -n \${vmbuild} ]; then
  vmbuild=\$(vmplayer -v | sed 's/.*build-//')
fi

### write configuration files ##################################################
# create preferences
preferencesheader

# create VMware startup file
runvmwareconfheader

# poolconfiguration config.xml
#TODO: change default to global variable \${POOL} in the future
#comment out cause of scanner... we do it now by hand... just a hack
#TODO: cleaner source...
#sed -e "s/HOSTNAME/\${hostname}/" \
#    -e "s/USER/\${USER}/" /var/lib/vmware/templates/client-config.xml.default \
#    > /etc/vmware/fd-loop/config.xml
echo "<settings>" > /etc/vmware/fd-loop/config.xml
echo "  <eintrag>" >> /etc/vmware/fd-loop/config.xml
echo "   <computername param=\"\${hostname}\">" >> /etc/vmware/fd-loop/config.xml
echo "   </computername>" >> /etc/vmware/fd-loop/config.xml
echo "   <username param=\"\${USER}\">" >> /etc/vmware/fd-loop/config.xml
echo "   </username>" >> /etc/vmware/fd-loop/config.xml
# if we have a scanner, then copy scannerinformation to this xml
sanelines="\$(wc -l /etc/sane.d/net.conf|awk '{ print \$1 };')"
if [ -f /etc/sane.d/net.conf ] && [ "\${sanelines}" -eq 1 ]; then
  echo "<scanner param=\"\$(cat /etc/sane.d/net.conf)\">" \
     >> /etc/vmware/fd-loop/config.xml
  echo "</scanner>" >> /etc/vmware/fd-loop/config.xml
fi
echo "  </eintrag>" >> /etc/vmware/fd-loop/config.xml
echo "</settings>" >> /etc/vmware/fd-loop/config.xml

# sync is needed to ensure that data is really written to virtual disk
sync

# own nvram. We need it for floppy drive b, default nvram has just drive a
#TODO copy it from plugin location (like this script)
cp /var/lib/vmware/templates/nvram.5.0 \${tmpdir}/nvram

# adjust volume
writelog "Unmuting sound...\c"
amixer -q sset Master 28 unmute
amixer -q sset PCM 28 unmute
writelog "finished\n"

### run vmplayer ###############################################################
# ...with the automatically written config file
if [ \$(which vmplayer 2>/dev/null) ]; then writelog "\nStarting VMplayer..."
  # run VMplayer
  writelog "... vmplayer \${vmopt} \${confile}...\n"
  vmplayer \${vmopt} \${confile} 2>&1 >/dev/null
else
  writelog "\nNo VMware/VMPlayer found!\n"
  exit 1
fi

writelog "\nBye.\n"
exit 0
EOF

		[ $DEBUGLEVEL -gt 0 ] && echo "done with 'vmware' os-plugin ...";

	fi
fi
