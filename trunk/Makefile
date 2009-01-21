# Description:  Makefile for creating project tarball and installing the project
#               to the various destination directories 
#
# Author(s):    Lars Mueller <lm@opendiskless.org>, 11-08-2006
#               Dirk von Suchodoletz <dirk@goe.net>, 15-08-2006
#
# Copyright:    (c) 2006 - opendiskless.org project
#
# Version:      0.0.1b

tarball:
	@echo "Creating tar ball "
	@tar cfhj opendiskless.tar.bz2 \
		--exclude-from=tools/tar_exclude_from \
		.
install:
	@echo "Installing opendiskless.org project files"
	@mkdir -p /var/lib/opendiskless/config/default/initramfs \
	       -p /var/lib/opendiskless/config/default/rootfs \
	       -p /var/lib/opendiskless/db \
	       -p /var/lib/opendiskless/stage1 \
	       -p /usr/share/opendiskless/distro-specs \
	       -p /usr/share/opendiskless/templates \
	       -p /usr/share/opendiskless/initramfs
	@cp initrd/mkdxsinitrd /usr/local/sbin
	@cp -a initrd/initrd-stuff/* /usr/share/opendiskless/initramfs
	@cp -a initrd/distro-specs/* /usr/share/opendiskless/distro-specs
	@cp installer/default_files/machine-setup.default \
	  /usr/share/opendiskless/templates
	@echo -e "#!/bin/sh\n#\n# this script allows the local admin to \
extend the\n# capabilities at the beginning of the initramfs" \
	  > /var/lib/opendiskless/config/default/initramfs/preinit.local
	@echo -e "#!/bin/sh\n#\n# this script allows the local admin to \
extend the\n# capabilities at the end of the initramfs" \
	  > /var/lib/opendiskless/config/default/initramfs/postinit.local
	@chmod u+x /var/lib/opendiskless/config/default/initramfs/*init.local

#uninstall:
#	@echo -e "Uninstalling opendiskless.org project files but keeping configs \
#and stage1\nfiles (please remove manually)"
#	@rm -rf /usr/share/opendiskless
#	@rm /usr/local/sbin/mkdxsinitrd
