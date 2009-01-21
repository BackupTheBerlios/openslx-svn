# Makefile for creating project tarball and installing the project
# to the various destination directories
#
# Lars Mueller <lm@openslx.com>, 2006
# Dirk von Suchodoletz <dvs@openslx.com>, 2006
# mj0, 12-09-2006 - vmware + theming
#
# (c) 2006 - OpenSLX.com

# the following should be filled via 'configure':
ifeq ($(USR_BIN_PATH),)
	USR_BIN_PATH = /usr/bin
endif
ifeq ($(SLX_BASE_PATH),)
	SLX_BASE_PATH = /opt/openslx
endif
ifeq ($(SLX_BIN_PATH),)
	SLX_BIN_PATH = ${SLX_BASE_PATH}/bin
endif
ifeq ($(SLX_CONFIG_PATH),)
	SLX_CONFIG_PATH = /etc/opt/openslx
endif
ifeq ($(SLX_PRIVATE_PATH),)
	SLX_PRIVATE_PATH = /var/opt/openslx
endif
ifeq ($(SLX_PUBLIC_PATH),)
	SLX_PUBLIC_PATH = /srv/openslx
endif
ifeq ($(SLX_SHARE_PATH),)
	SLX_SHARE_PATH = ${SLX_BASE_PATH}/share
endif
ifeq ($(VMWARE_PATH),)
	VMWARE_PATH = ${SLX_BASE_PATH}/vmware
endif

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
	@echo "Installing OpenSLX project files"
	@mkdir -p $(SLX_CONFIG_PATH) \
	       -p $(SLX_BIN_PATH) \
	       -p $(SLX_SHARE_PATH)/distro-specs \
	       -p $(SLX_SHARE_PATH)/templates \
	       -p $(SLX_SHARE_PATH)/initramfs \
	       -p $(SLX_PRIVATE_PATH)/config/default/initramfs \
	       -p $(SLX_PRIVATE_PATH)/config/default/rootfs \
	       -p $(SLX_PRIVATE_PATH)/db \
	       -p $(SLX_PRIVATE_PATH)/stage1 \
	       -p $(SLX_PUBLIC_PATH)/tftpboot \
	       -p $(SLX_SHARE_PATH)/themes
	@cp initramfs/{mkdxsinitrd,slxmkramfs} $(SLX_BIN_PATH)
	@chmod u+x $(SLX_BIN_PATH)/{mkdxsinitrd,slxmkramfs}
	@ln -sf $(SLX_BIN_PATH)/mkdxsinitrd $(USR_BIN)/
	@ln -sf $(SLX_BIN_PATH)/slxmkramfs $(USR_BIN)/
	@cp config-db/slxconfig-demuxer.pl $(SLX_BIN_PATH)/
	@cp -r config-db/OpenSLX $(SLX_BIN_PATH)/
	@ln -sf $(SLX_BIN_PATH)/slxconfig-demuxer.pl $(USR_BIN)/
	@cp -a initramfs/initrd-stuff/* $(SLX_SHARE_PATH)/initramfs
	@cp -a initramfs/distro-specs/* $(SLX_SHARE_PATH)/distro-specs
	@cp -a installer/default_files/machine-setup.default \
	  $(SLX_SHARE_PATH)/templates
	@cp -a installer/default_files/tftpboot $(SLX_SHARE_PATH)
	@cp -a theming/* $(SLX_SHARE_PATH)/themes
	@echo -e "#!/bin/sh\n#\n# This script allows the local admin to \
extend the\n# capabilities at the beginning of the initramfs (stage3). \
The toolset is rather\n# restricted and you have to keep in mind that \
stage4 rootfs has the\n# prefix '/mnt'." \
	  > $(SLX_PRIVATE_PATH)/config/default/initramfs/preinit.local
	@echo -e "#!/bin/sh\n#\n# This script allows the local admin to \
extend the\n# capabilities at the end of the initramfs (stage3). The \
toolset is rather\n# restricted and you have to keep in mind that stage4 \
rootfs has the\n# prefix '/mnt'. But you might use some special slx \
functions via\# inclusion: '. /etc/functions' ..." \
	  > $(SLX_PRIVATE_PATH)/config/default/initramfs/postinit.local
	@chmod u+x $(SLX_PRIVATE_PATH)/config/default/initramfs/*init.local
	@echo -e "# default setup for openslx on this specific system\
\nopenslx-basepath = ${SLX_BASE_PATH}\
\nconfig-path = ${SLX_CONFIG_PATH}\
\nprivate-path = ${SLX_PRIVATE_PATH}\
\npublic-path = ${SLX_PUBLIC_PATH}\
\nshare-path = ${SLX_SHARE_PATH}\n" \
	  > $(SLX_CONFIG_PATH)/settings.default
	@echo -e "# local setup for openslx (overrides settings.default)\n" \
	  > $(SLX_CONFIG_PATH)/settings.local
	@find $(SLX_SHARE_PATH) -depth -regex ".*/\..*" -print0 | xargs -0 rm -rf {}
	@chmod a+w $(SLX_PUBLIC_PATH)/tftpboot
	@chmod a+w $(SLX_PRIVATE_PATH)/db

vmware_install:
	@echo "Installing VMware files to $(VMWARE_PATH)"
	@mkdir -p $(VMWARE_PATH)/templ \
	       -p $(VMWARE_PATH)/vmsessions/kdm
	@cp -a vmware/* $(VMWARE_PATH)/templ/
	@echo -e "Please configure your exports (add $(VMWARE_PATH) to your list).\nCopy your *.vmdk files into $(VMWARE_PATH). For interactive mode add for each virtual machine (*.vmdk) a .desktop file into ./vmsessions (example file $(VMWARE_PATH)/templ/desktop.template). Don't forget to install Xdialog!"

#uninstall:
#	@echo -e "Uninstalling openslx.org project files but keeping configs \
#and stage1\nfiles (please remove manually)"
#	@rm -rf $(SLX_SHARE_PATH)
#	@rm $(USE_BIN_PATH)/{mkdxsinitrd,slxmkramfs}

clean:
	@echo "Cleanup OpenSLX source directory "
	@for file in openslx-*.tar.bz2; do \
		rm -f $${file}; \
	done
