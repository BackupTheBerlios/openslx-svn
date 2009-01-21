#!/bin/sh
# Deinstall dxs
rm -vrf /usr/share/dxs
rm -vf /usr/sbin/mkdxsinitrd
rm -vf /usr/sbin/ld4-inst
rm -vf /usr/share/man/man1/mkdxsinitrd.1.gz
echo "Done."
