#!/bin/sh
if [ "$EUID" -ne 0 ]; then
    echo "You need to start this installer as user root"
    exit
fi

cp -Rv dxs /usr/share/
cp -v man/* /usr/share/man/man1/
#Create links to provide the scripts to the user
pushd /usr/sbin > /dev/null
ln -vs ../share/dxs/installer/ld4-inst
ln -vs ../share/dxs/initrd/mkdxsinitrd
popd > /dev/null
echo "Done."
