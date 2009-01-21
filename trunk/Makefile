# Makefile for creating project tarball and installing the project
# to the various destination directories
#
# Lars Mueller <lm@openslx.com>, 2006
# Dirk von Suchodoletz <dirk@goe.net>, 2006
#
# (c) 2006 - OpenSLX.com

tarball:
	@echo "Creating tar ball "
	@tar cfhj openslx.tar.bz2 \
		--exclude-from=tools/tar_exclude_from \
		.
install:
	@echo "Installing openslx.org project files"
	@mkdir -p /var/lib/openslx/config/default/initramfs \
	       -p /var/lib/openslx/config/default/rootfs \
	       -p /var/lib/openslx/db \
	       -p /var/lib/openslx/stage1 \
	       -p /usr/share/openslx/distro-specs \
	       -p /usr/share/openslx/templates \
	       -p /usr/share/openslx/initramfs
	@cp initrd/mkdxsinitrd /usr/local/sbin
	@cp -a initrd/initrd-stuff/* /usr/share/openslx/initramfs
	@cp -a initrd/distro-specs/* /usr/share/openslx/distro-specs
	@cp installer/default_files/machine-setup.default \
	  /usr/share/openslx/templates
	@echo -e "#!/bin/sh\n#\n# This script allows the local admin to \
extend the\n# capabilities at the beginning of the initramfs (stage3). \
The toolset is rather\n# restricted and you have to keep in mind that \
stage4 rootfs has the\n# prefix '/mnt'." \
	  > /var/lib/openslx/config/default/initramfs/preinit.local
	@echo -e "#!/bin/sh\n#\n# This script allows the local admin to \
extend the\n# capabilities at the end of the initramfs (stage3). The \
toolset is rather\n# restricted and you have to keep in mind that stage4 \
rootfs has the\n# prefix '/mnt'." \
	  > /var/lib/openslx/config/default/initramfs/postinit.local
	@chmod u+x /var/lib/openslx/config/default/initramfs/*init.local

#uninstall:
#	@echo -e "Uninstalling openslx.org project files but keeping configs \
#and stage1\nfiles (please remove manually)"
#	@rm -rf /usr/share/openslx
#	@rm /usr/local/sbin/mkdxsinitrd
