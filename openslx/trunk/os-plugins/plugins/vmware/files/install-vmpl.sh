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
else
    echo "Attribute of install-vmpl.sh isn't valid!"
    echo "This shouldn't happen! Fix vmware.pm!"
    exit 1;
fi


### Main installation part
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
# TODO: check if /boot/vmlinuz is available if we get the kernel version this way
#       perhaps we don't need a check... perhaps openslx always use
#       /boot/vmlinuz
#       This problem happens 3 times. see below!
# TODO: error check if build environment isn't installed...
#TODO: vmblock only v2
if [ "${vmplversion}" != "vmpl1.0" ]; then
  cd vmblock-only/
  sed -i "s%^VM_UNAME = .*%VM_UNAME = $(ls /boot/vmlinuz*|grep -v -e "^/boot/vmlinuz$$"|sed 's,/boot/vmlinuz-,,'|sort|tail -n 1)%" Makefile
  make -s
  cp vmblock.ko vmblock.o ../../../../../modules
  cd ..
fi

echo "   * building vmmon module"
cd vmmon-only
sed -i "s%^VM_UNAME = .*%VM_UNAME = $(ls /boot/vmlinuz*|grep -v -e "^/boot/vmlinuz$$"|sed 's,/boot/vmlinuz-,,'|sort|tail -n 1)%" Makefile
make -s
cp vmmon.ko vmmon.o ../../../../../modules
cd ..
    
echo "   * building vmnet module"
cd vmnet-only
sed -i "s%^VM_UNAME = .*%VM_UNAME = $(ls /boot/vmlinuz*|grep -v -e "^/boot/vmlinuz$$"|sed 's,/boot/vmlinuz-,,'|sort|tail -n 1)%" Makefile
make -s
cp vmnet.ko vmnet.o ../../../../../modules
cd ../../../../../..
        
echo "   * setting up EULA"
mv vmroot/doc/EULA vmroot/lib/vmware/share/EULA.txt

echo "   * finishing installation"
