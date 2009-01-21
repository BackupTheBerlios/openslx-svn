# Makefile for creating project tarball and installing the project
# to the various destination directories
#
# Lars Mueller <lm@openslx.com>, 2006
# Dirk von Suchodoletz <dirk@goe.net>, 2006
#
# (c) 2006 - OpenSLX.com

tarball:
	@OPENSLX_SVN_SNAPSHOT=$$( echo $${OPENSLX_SVN_SNAPSHOT} | \
		tr [:upper:] [:lower:]); \
	case "$${OPENSLX_SVN_SNAPSHOT}" in \
		yes|y|1) OPENSLX_VERSION_SVNREV=$$( svnversion) ;; \
	esac; \
	. VERSIONS; \
	echo "Creating OpenSLX $${OPENSLX_VERSION_STRING} tar ball "; \
	if test -e "../openslx-$${OPENSLX_VERSION_STRING}" -a \
	! -L "../openslx-$${OPENSLX_VERSION_STRING}"; then \
		echo "Error: ../openslx-$${OPENSLX_VERSION_STRING} exists and is not a sym link! "; \
		exit 1; \
	fi; \
	svn_repo_name=$$( pwd); \
	svn_repo_name="$${svn_repo_name##*/}"; \
	if ! test -L "../openslx-$${OPENSLX_VERSION_STRING}"; then \
		pushd .. >/dev/null; \
		ln -s "$${svn_repo_name}" "openslx-$${OPENSLX_VERSION_STRING}"; \
		popd >/dev/null; \
		OPENSLX_SOURCEDIR_SYMLINK_CREATED="yes"; \
	fi; \
	pushd .. >/dev/null; \
	tar cfhj \
		"$${svn_repo_name}/openslx-$${OPENSLX_VERSION_STRING}.tar.bz2" \
		--exclude-from="$${svn_repo_name}/tools/tar_exclude_from" \
		"openslx-$${OPENSLX_VERSION_STRING}/"; \
	test "$${OPENSLX_SOURCEDIR_SYMLINK_CREATED}" = "yes" && \
		rm -f "openslx-$${OPENSLX_VERSION_STRING}"; \
	popd >/dev/null

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

clean:
	@echo "Cleanup OpenSLX source directory "
	@for file in openslx-*.tar.bz2; do \
		rm -f $${file}; \
	done
