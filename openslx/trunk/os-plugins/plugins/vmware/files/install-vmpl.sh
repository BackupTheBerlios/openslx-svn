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
  rm -rf /etc/vmware
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
    sed -i "s%^VM_UNAME = .*%VM_UNAME = $(find /boot/vmlinuz* -maxdepth 0|sed 's,/boot/vmlinuz-,,g'|sort|tail -n 1)%" Makefile
    make -s
    mv vmblock.ko vmblock.o ../../../../../modules
    cd ..
  fi

  echo "   * building vmmon module"
  cd vmmon-only
  sed -i "s%^VM_UNAME = .*%VM_UNAME = $(find /boot/vmlinuz* -maxdepth 0|sed 's,/boot/vmlinuz-,,g'|sort|tail -n 1)%" Makefile
  make -s
  mv vmmon.ko vmmon.o ../../../../../modules
  cd ..
    
  echo "   * building vmnet module"
  cd vmnet-only
  sed -i "s%^VM_UNAME = .*%VM_UNAME = $(find /boot/vmlinuz* -maxdepth 0|sed 's,/boot/vmlinuz-,,g'|sort|tail -n 1)%" Makefile
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
  mkdir -p vmroot/modules

  mv temp/vmware-player/lib vmroot/lib/vmware
  mv temp/vmware-player/sbin vmroot/
  # the following shouldn't be needed, just to have it 1:1 self-created
  # copy of /usr/lib/vmware
  # Todo: clean it out when everything is running
  mv temp/vmware-installer vmroot/lib/vmware/installer
  rm -rf vmroot/lib/vmware/installer/.installer
  rm -rf vmroot/lib/vmware/installer/bootstrap
  mkdir -p vmroot/lib/vmware/setup
  mv temp/vmware-player-setup/vmware-config vmroot/lib/vmware/setup
  mv temp/vmware-player/doc vmroot/
  mv temp/vmware-player/bin vmroot/

  ##
  ## left files/dirs
  ##
  # temp/vmware-player/files/index.theme ... hopefully not needed,
  # temp/vmware-player/share => /usr/share ... icons 
  # temp/vmware-player/etc/... => /etc
  # temp/vmware-player/build => unknown...  not found...

  
  # etc/vmware/
  #   bootstrap => Path definitions. confusing due of version 1.0
  #                 which looks like the instller version
  #                 perhaps just for installer... hopefully
  #   config => path definition, networking, different configurations
  #   database => sqlite3 db. includes all files mapped to component
  #               hopefully just used by installer and some path config
  #   networking => networking config... has options which are in
  #                 dhcpd.conf, hopefully not needed
  #   vmnet(1|8) => we know it from v1/v2

  echo "   * fixing file permission"
  chmod 755 vmroot/lib/vmware/bin/*
  chmod 04755 vmroot/lib/vmware/bin/vmware-vmx 
  chmod 04755 vmroot/lib/vmware/bin/vmware-vmx-debug
  chmod 04755 vmroot/lib/vmware/bin/vmware-vmx-stats
  chmod 755 vmroot/bin/*
  chmod 755 vmroot/lib/vmware/lib/wrapper-gtk24.sh

  # I don't want to understand what vmware is doing, but without this
  # step we need to have LD_LIBRARY_PATH with 53 entrys. welcome to
  # library hell
  # if this fact is still valid for 2.5 is unclear, but lets do it
  echo "   * fixing librarys..."
  cd vmroot/lib/vmware/lib
  mkdir test
  mv lib* test
  mv test/lib*/* .
  rm -rf test
  cd ../../../..

  echo "   * fixing gdk and pango config files"
  sed -i \
    "s,@@LIBCONF_DIR@@,/opt/openslx/plugin-repo/vmware/${vmplversion}/vmroot/lib/vmware/libconf," \
    vmroot/lib/vmware/libconf/etc/gtk-2.0/gdk-pixbuf.loaders
  sed -i \
    "s,@@LIBCONF_DIR@@,/opt/openslx/plugin-repo/vmware/${vmplversion}/vmroot/lib/vmware/libconf," \
    vmroot/lib/vmware/libconf/etc/gtk-2.0/gtk.immodules
  sed -i \
    "s,@@LIBCONF_DIR@@,/opt/openslx/plugin-repo/vmware/${vmplversion}/vmroot/lib/vmware/libconf," \
    vmroot/lib/vmware/libconf/etc/pango/pango.modules
  sed -i \
    "s,@@LIBCONF_DIR@@,/opt/openslx/plugin-repo/vmware/${vmplversion}/vmroot/lib/vmware/libconf," \
    vmroot/lib/vmware/libconf/etc/pango/pangorc
  sed -i \
    "s,/etc/pango/pango/,/etc/pango/," \
    vmroot/lib/vmware/libconf/etc/pango/pangorc

  echo "   * creating /etc/vmware"
  rm -rf /etc/vmware
  mkdir -p /etc/vmware

  echo "   * unpacking kernel modules"
  cd vmroot/lib/vmware/modules/source
  tar xf vmnet.tar
  tar xf vmmon.tar
  tar xf vmblock.tar
  #tar xf vmci.tar        # just for 2 or more VMs => not needed
  #tar xf vmppuser.tar    # we don't need it
  tar xf vsock.tar

  echo "   * building vmblock module"
  cd vmblock-only/
  sed -i "s%^VM_UNAME = .*%VM_UNAME = $(find /boot/vmlinuz* -maxdepth 0|sed 's,/boot/vmlinuz-,,g'|sort|tail -n 1)%" Makefile
  make -s
  mv vmblock.ko vmblock.o ../../../../../modules
  cd ..

  echo "   * building vmmon module"
  cd vmmon-only
  sed -i "s%^VM_UNAME = .*%VM_UNAME = $(find /boot/vmlinuz* -maxdepth 0|sed 's,/boot/vmlinuz-,,g'|sort|tail -n 1)%" Makefile
  make -s
  mv vmmon.ko vmmon.o ../../../../../modules
  cd ..
    
  echo "   * building vmnet module"
  cd vmnet-only
  sed -i "s%^VM_UNAME = .*%VM_UNAME = $(find /boot/vmlinuz* -maxdepth 0|sed 's,/boot/vmlinuz-,,g'|sort|tail -n 1)%" Makefile
  make -s
  mv vmnet.ko vmnet.o ../../../../../modules
  cd ..
        
  echo "   * building vmsock module"
  cd vsock-only
  sed -i "s%^VM_UNAME = .*%VM_UNAME = $(find /boot/vmlinuz* -maxdepth 0|sed 's,/boot/vmlinuz-,,g'|sort|tail -n 1)%" Makefile
  make -s
  mv vsock.ko vsock.o ../../../../../modules
  cd ../../../../../..

  echo "   * setting up EULA"
  mv vmroot/doc/EULA vmroot/lib/vmware/share/EULA.txt

  echo "   * finishing installation"

fi
