#!/bin/sh

cd /opt/openslx/plugin-repo/vmware/

### Check if player are still installed
if [ -d ${1}/vmroot/ ]; then
  echo "    * $1 seems to be installed. There shouldn't be a need for a new installation."
  echo "      If you want to reinstall $1 press \"y\" else we will exit"
  read
  if [ "${REPLY}" != "y" ]; then
    echo "    * $1 is already installed. Nothing to do."
    exit
  fi
  echo "     * $1 will be reinstalled"
fi


### Now define values
if [ "$1" = "vmpl1.0" ]; then
  vmplversion="vmpl1.0"
  tgzfile=$(ls packages/VMware-player-1.0.*|sort|tail -n 1)
elif [ "$1" = "vmpl2.0" ]; then
  vmplversion="vmpl2.0"
  tgzfile=$(ls packages/VMware-player-2.0.*|sort|tail -n 1)
elif [ "$1" = "vmpl2.5" ]; then
  vmplversion="vmpl2.5"
  tgzfile=$(ls packages/VMware-Player-2.5.*.bundle|sort|tail -n 1)
else
    echo "Attribute of install-vmpl.sh isn't valid!"
    echo "This shouldn't happen! Fix vmware.pm!"
    exit 1;
fi


### Main installation part
if [ "${vmplversion}" != "vmpl2.5" ]; then
  # tgz Installation of vmpl1.0 and vmpl2.0
  cd ${vmplversion}

  echo "   * Unpacking vmplayer ${vmplversion}"
  tar xfz ../${tgzfile}
  # TODO: errorcheck if tgz wasnt downloaded properly.
  #       ask on mailinglist if theres a way how to handle it
  #       in preInstallation() "exit 1" is enough. Perhaps it will work
  #       here, too. Try first, and then document it in the wiki

  # reduce some errors
  echo "   * deleting old files if available"
  rm -rf vmroot

  echo "   * copying files..."
  mkdir vmroot
  mkdir -p vmroot/modules
  mkdir -p vmroot/lib
  mv vmware-player-distrib/lib vmroot/lib/vmware
  mv vmware-player-distrib/bin vmroot/
  if [ "${vmplversion}" != "vmpl1.0" ]; then
    mv vmware-player-distrib/sbin vmroot/
  fi
  mv vmware-player-distrib/doc vmroot/
  rm -rf vmware-player-distrib/
  rm -rf vmroot/lib/vmware/modules/binary

  echo "   * fixing file permission"
  chmod 04755 vmroot/lib/vmware/bin/vmware-vmx 

  # I don't want to understand what vmware is doing, but without this
  # step we need to have LD_LIBRARY_PATH with 53 entrys. welcome to
  # library hell
  echo "   * fixing librarys..."
  cd vmroot/lib/vmware/lib
  mkdir test
  mv lib* test
  mv test/lib*/* .
  rm -rf test
  cd ../../../..

  echo "   * fixing gdk and pango config files"
  sed -i \
    "s,/build/mts/.*/vmui/../libdir/libconf,/opt/openslx/plugin-repo/vmware/${vmplversion}/vmroot/lib/vmware/libconf," \
    vmroot/lib/vmware/libconf/etc/gtk-2.0/gdk-pixbuf.loaders
  sed -i \
    "s,/build/mts/.*/vmui/../libdir/libconf,/opt/openslx/plugin-repo/vmware/${vmplversion}/vmroot/lib/vmware/libconf," \
    vmroot/lib/vmware/libconf/etc/gtk-2.0/gtk.immodules
  sed -i \
    "s,/build/mts/.*/vmui/../libdir/libconf,/opt/openslx/plugin-repo/vmware/${vmplversion}/vmroot/lib/vmware/libconf," \
    vmroot/lib/vmware/libconf/etc/pango/pango.modules
  sed -i \
    "s,/build/mts/.*/vmui/../libdir/libconf,/opt/openslx/plugin-repo/vmware/${vmplversion}/vmroot/lib/vmware/libconf," \
    vmroot/lib/vmware/libconf/etc/pango/pangorc
  sed -i \
    "s,/etc/pango/pango/,/etc/pango/," \
    vmroot/lib/vmware/libconf/etc/pango/pangorc

  echo "   * creating /etc/vmware"
  mkdir -p /etc/vmware

  echo "   * unpacking kernel modules"
  cd vmroot/lib/vmware/modules/source
  tar xf vmnet.tar
  tar xf vmmon.tar
  if [ "${vmplversion}" != "vmpl1.0" ]; then
    tar xf vmblock.tar
  fi

  echo "   * building vmblock module"
  if [ "${vmplversion}" != "vmpl1.0" ]; then
    cd vmblock-only/
    sed -i "s%^VM_UNAME = .*%VM_UNAME = $(find /lib/modules/2.6* -maxdepth 0|sed 's,/lib/modules/,,g'|sort|tail -n1)%" Makefile
    make -s
    mv vmblock.ko vmblock.o ../../../../../modules
    cd ..
  fi

  echo "   * building vmmon module"
  cd vmmon-only
  sed -i "s%^VM_UNAME = .*%VM_UNAME = $(find /lib/modules/2.6* -maxdepth 0|sed 's,/lib/modules/,,g'|sort|tail -n1)%" Makefile
  make -s
  mv vmmon.ko vmmon.o ../../../../../modules
  cd ..
    
  echo "   * building vmnet module"
  cd vmnet-only
  sed -i "s%^VM_UNAME = .*%VM_UNAME = $(find /lib/modules/2.6* -maxdepth 0|sed 's,/lib/modules/,,g'|sort|tail -n1)%" Makefile
  make -s
  mv vmnet.ko vmnet.o ../../../../../modules
  cd ../../../../../..
        
  echo "   * setting up EULA"
  mv vmroot/doc/EULA vmroot/lib/vmware/share/EULA.txt

  echo "   * finishing installation"


else
  # bundle Installation of vmpl2.5
  # note: the rpm just include the stupid .bundle file...
  cd ${vmplversion}

  echo "   * Manipulating and extracting vmplayer ${vmplversion} package. this may take a while"
  
  # fool non-root user extraction... just for testing
  sed -i 's/ exit 1/ echo 1/' ../${tgzfile}
  # don't use deinstallation stuff and checks of /etc...
  # and don't modify file size, else it wont work!
  sed -i 's/ migrate_networks/ echo te_networks/' ../${tgzfile} 
  sed -i 's/ uninstall_legacy/ echo tall_legacy/' ../${tgzfile} 
  sed -i 's/ uninstall_rpm/ echo tall_rpm/' ../${tgzfile} 
  sed -i 's/ uninstall_bundle/ echo tall_bundle/' ../${tgzfile} 
  # this won't work as root on our clients... I hope it don't break
  # anything on our clients in stage1
  sh ../${tgzfile} -x temp
  # TODO: errorcheck if rpm wasnt downloaded properly.
  #       ask on mailinglist if theres a way how to handle it
  #       in preInstallation() "exit 1" is enough. Perhaps it will work
  #       here, too. Try first, and then document it in the wiki

  # reduce some errors
  echo "   * deleting old files if available"
  rm -rf vmroot

  echo "   * copying files..."
  mkdir -p vmroot
  mkdir -p vmroot/lib
  ##
  ## /usr/lib/vmware
  ##
  mv temp/vmware-player/lib vmroot/lib/vmware
  # the following shouldn't be needed, just to have it 1:1 self-created
  # copy of /usr/lib/vmware 
  mv temp/vmware-installer vmroot/lib/vmware/installer
  rm -rf vmroot/lib/vmware/installer/.installer
  rm -rf vmroot/lib/vmware/installer/bootstrap
  mkdir -p vmroot/lib/vmware/setup
  mv temp/vmware-player-setup/vmware-config vmroot/lib/vmware/setup
  # files that differ so far... yes the normal hack we know from v1َ/v2a
  # .../installer/ shouldn't be needed, too
  #vmroot/lib/vmware/installer/lib/libconf/etc/gtk-2.0/gdk-pixbuf.loaders
  #vmroot/lib/vmware/installer/lib/libconf/etc/gtk-2.0/gtk.immodules
  #vmroot/lib/vmware/installer/lib/libconf/etc/pango/pango.modules
  #vmroot/lib/vmware/installer/lib/libconf/etc/pango/pangorc
  #vmroot/lib/vmware/libconf/etc/gtk-2.0/gdk-pixbuf.loaders
  #vmroot/lib/vmware/libconf/etc/gtk-2.0/gtk.immodules
  #vmroot/lib/vmware/libconf/etc/pango/pango.modules
  #vmroot/lib/vmware/libconf/etc/pango/pangorc

  ##
  ## left files/dirs
  ##
  # temp/vmware-player/sbin => /usr/sbin
  # temp/vmware-player/doc/ => /usr/share/doc/vmware-player/ => EULA
  # temp/vmware-player/bin => /usr/bin
  # temp/vmware-player/files/index.theme ... hopefully not needed,
  # temp/vmware-player/share => /usr/share ... icons 
  # temp/vmware-player/etc/... => /etc
  # temp/vmware-player/build => unknown... not found on system


#  echo "   * fixing file permission"
#  chmod 04755 vmroot/lib/vmware/bin/vmware-vmx 
#
#  # I don't want to understand what vmware is doing, but without this
#  # step we need to have LD_LIBRARY_PATH with 53 entrys. welcome to
#  # library hell
#  echo "   * fixing librarys..."
#  cd vmroot/lib/vmware/lib
#  mkdir test
#  mv lib* test
#  mv test/lib*/* .
#  rm -rf test
#  cd ../../../..
#
#  echo "   * fixing gdk and pango config files"
#  sed -i \
#    "s,/build/mts/.*/vmui/../libdir/libconf,/opt/openslx/plugin-repo/vmware/${vmplversion}/vmroot/lib/vmware/libconf," \
#    vmroot/lib/vmware/libconf/etc/gtk-2.0/gdk-pixbuf.loaders
#  sed -i \
#    "s,/build/mts/.*/vmui/../libdir/libconf,/opt/openslx/plugin-repo/vmware/${vmplversion}/vmroot/lib/vmware/libconf," \
#    vmroot/lib/vmware/libconf/etc/gtk-2.0/gtk.immodules
#  sed -i \
#    "s,/build/mts/.*/vmui/../libdir/libconf,/opt/openslx/plugin-repo/vmware/${vmplversion}/vmroot/lib/vmware/libconf," \
#    vmroot/lib/vmware/libconf/etc/pango/pango.modules
#  sed -i \
#    "s,/build/mts/.*/vmui/../libdir/libconf,/opt/openslx/plugin-repo/vmware/${vmplversion}/vmroot/lib/vmware/libconf," \
#    vmroot/lib/vmware/libconf/etc/pango/pangorc
#  sed -i \
#    "s,/etc/pango/pango/,/etc/pango/," \
#    vmroot/lib/vmware/libconf/etc/pango/pangorc
#
#  echo "   * creating /etc/vmware"
#  mkdir -p /etc/vmware
#
#  echo "   * unpacking kernel modules"
#  cd vmroot/lib/vmware/modules/source
#  tar xf vmnet.tar
#  tar xf vmmon.tar
#  if [ "${vmplversion}" != "vmpl1.0" ]; then
#    tar xf vmblock.tar
#  fi
#
#  echo "   * building vmblock module"
#  if [ "${vmplversion}" != "vmpl1.0" ]; then
#    cd vmblock-only/
#    sed -i "s%^VM_UNAME = .*%VM_UNAME = $(find /lib/modules/2.6* -maxdepth 0|sed 's,/lib/modules/,,g'|sort|tail -n1)%" Makefile
#    make -s
#    mv vmblock.ko vmblock.o ../../../../../modules
#    cd ..
#  fi
#
#  echo "   * building vmmon module"
#  cd vmmon-only
#  sed -i "s%^VM_UNAME = .*%VM_UNAME = $(find /lib/modules/2.6* -maxdepth 0|sed 's,/lib/modules/,,g'|sort|tail -n1)%" Makefile
#  make -s
#  mv vmmon.ko vmmon.o ../../../../../modules
#  cd ..
#    
#  echo "   * building vmnet module"
#  cd vmnet-only
#  sed -i "s%^VM_UNAME = .*%VM_UNAME = $(find /lib/modules/2.6* -maxdepth 0|sed 's,/lib/modules/,,g'|sort|tail -n1)%" Makefile
#  make -s
#  mv vmnet.ko vmnet.o ../../../../../modules
#  cd ../../../../../..
#        
#  echo "   * setting up EULA"
#  mv vmroot/doc/EULA vmroot/lib/vmware/share/EULA.txt
#
#  echo "   * finishing installation"


fi
