# Makefile for creating project tarball and installing the project
# to the various destination directories
#
# Lars Mueller <lm@openslx.com>, 2006
# Dirk von Suchodoletz <dvs@openslx.com>, 2006
# mj0, 12-09-2006 - vmware + theming
#
# (c) 2006 - OpenSLX.com

# the following defaults should be filled via 'configure'
# and each of them can be overriden by setting the environment variable
# in the shell that executes this Makefile
ifeq ($(USR_BIN_PATH),)
	USR_BIN_PATH = /usr/bin
endif

ifeq ($(SLX_CONFIG_PATH),)
	SLX_CONFIG_PATH = /etc/opt/openslx
endif
ifeq ($(SLX_BASE_PATH),)
	SLX_BASE_PATH = /opt/openslx
endif
ifeq ($(SLX_BIN_PATH),)
	SLX_BIN_PATH = ${SLX_BASE_PATH}/bin
endif
ifeq ($(SLX_SHARE_PATH),)
	SLX_SHARE_PATH = ${SLX_BASE_PATH}/share
endif
ifeq ($(SLX_VMWARE_PATH),)
	SLX_VMWARE_PATH = ${SLX_BASE_PATH}/vmware
endif

ifeq ($(SLX_PRIVATE_PATH),)
	SLX_PRIVATE_PATH = /var/opt/openslx
endif

ifeq ($(SLX_PUBLIC_PATH),)
	SLX_PUBLIC_PATH = /srv/openslx
endif
ifeq ($(SLX_EXPORT_PATH),)
	SLX_EXPORT_PATH = ${SLX_PUBLIC_PATH}/export
endif
ifeq ($(SLX_TFTPBOOT_PATH),)
	SLX_TFTPBOOT_PATH = ${SLX_PUBLIC_PATH}/tftpboot
endif

ifeq ($(SLX_TEMP_PATH),)
	SLX_TEMP_PATH = /tmp
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
	       -p $(SLX_BASE_PATH)/lib \
	       -p $(SLX_BIN_PATH) \
	       -p $(SLX_SHARE_PATH)/templates \
	       -p $(SLX_SHARE_PATH)/initramfs \
	       -p $(SLX_PRIVATE_PATH)/config/default/initramfs \
	       -p $(SLX_PRIVATE_PATH)/config/default/rootfs \
	       -p $(SLX_PRIVATE_PATH)/db \
	       -p $(SLX_PRIVATE_PATH)/stage1 \
	       -p $(SLX_PUBLIC_PATH) \
	       -p $(SLX_TFTPBOOT_PATH) \
	       -p $(SLX_SHARE_PATH)/themes

	@# copy initramfs generator scripts (and inject SLX_CONFIG_PATH on the way):
	@cp initramfs/{mkdxsinitrd,slxmkramfs} $(SLX_BIN_PATH)
	@sed -e "s,@@@SLX_CONFIG_PATH@@@,$(SLX_CONFIG_PATH)," \
	  -i $(SLX_BIN_PATH)/mkdxsinitrd
	@sed -e "s,@@@SLX_CONFIG_PATH@@@,$(SLX_CONFIG_PATH)," \
	  -i $(SLX_BIN_PATH)/slxmkramfs

	@# copy all PERL-scripts from config-db and their required modules:
	@cp config-db/slx* $(SLX_BIN_PATH)/
	@tar --exclude=.svn -cp -C config-db OpenSLX | \
	  tar -xp -C $(SLX_BASE_PATH)/lib

	@# link all binaries & scripts into user-path:
	@ln -sf $(SLX_BIN_PATH)/slx* $(USR_BIN_PATH)/
	@ln -sf $(SLX_BIN_PATH)/mkdxsinitrd $(USR_BIN_PATH)/

	@# copy shareable data:
	@cd initramfs/initrd-stuff; tar --exclude=.svn -cp * | \
	  tar -xp -C $(SLX_SHARE_PATH)/initramfs; cd ../..
	@tar --exclude=.svn -cp -C initramfs distro-specs | \
	  tar -xp -C $(SLX_SHARE_PATH)
	@cp -a installer/default_files/machine-setup.default \
	  $(SLX_SHARE_PATH)/templates
	@tar --exclude=.svn -cp -C installer/default_files tftpboot | \
	  tar -xp -C $(SLX_SHARE_PATH)
	@cd theming; tar --exclude=.svn -cp * | \
	  tar -xp -C $(SLX_SHARE_PATH)/themes; cd ..

	@# create pre-/postinit scripts for us in initramfs:
	@echo -e "#!/bin/sh\n#\n# This script allows the local admin to \
extend the\n# capabilities at the beginning of the initramfs (stage3). \
The toolset is rather\n# restricted and you have to keep in mind that \
stage4 rootfs has the\n# prefix '/mnt'." \
	  > $(SLX_PRIVATE_PATH)/config/default/initramfs/preinit.local
	@echo -e "#!/bin/sh\n#\n# This script allows the local admin to \
extend the\n# capabilities at the end of the initramfs (stage3). The \
toolset is rather\n# restricted and you have to keep in mind that stage4 \
rootfs has the\n# prefix '/mnt'. But you might use some special slx \
functions via\n# inclusion: '. /etc/functions' ..." \
	  > $(SLX_PRIVATE_PATH)/config/default/initramfs/postinit.local
	@chmod u+x $(SLX_PRIVATE_PATH)/config/default/initramfs/*init.local

	@# create complete default settings and empty local settings file:
	@echo -e "# default setup for OpenSLX-installation\
\nSLX_BASE_PATH=${SLX_BASE_PATH}\
\nSLX_BIN_PATH=${SLX_BIN_PATH}\
\nSLX_CONFIG_PATH=${SLX_CONFIG_PATH}\
\nSLX_EXPORT_PATH=${SLX_EXPORT_PATH}\
\nSLX_PRIVATE_PATH=${SLX_PRIVATE_PATH}\
\nSLX_PUBLIC_PATH=${SLX_PUBLIC_PATH}\
\nSLX_SHARE_PATH=${SLX_SHARE_PATH}\
\nSLX_TEMP_PATH=${SLX_TEMP_PATH}\
\nSLX_TFTPBOOT_PATH=${SLX_TFTPBOOT_PATH}\
\nSLX_VMWARE_PATH=${SLX_VMWARE_PATH}\n" \
	  > $(SLX_CONFIG_PATH)/settings.default
	@echo -e "# local setup for openslx (overrides settings.default)\n" \
	  > $(SLX_CONFIG_PATH)/settings.local

	@# create slxversion script:
	@OPENSLX_VERSION_SVNREV=$$(svnversion) . VERSIONS; \
	  echo "echo $${OPENSLX_VERSION_STRING}" \
	    > ${SLX_BIN_PATH}/slxversion
	@chmod a+x ${SLX_BIN_PATH}/slxversion
	@ln -sf $(SLX_BIN_PATH)/slxversion $(USR_BIN_PATH)/

vmware_install:
	@echo "Installing VMware files to $(SLX_VMWARE_PATH)"
	@mkdir -p $(SLX_VMWARE_PATH)/templ \
	       -p $(SLX_VMWARE_PATH)/vmsessions/kdm
	@cp -a vmware/* $(SLX_VMWARE_PATH)/templ/
	@echo -e "Please configure your exports (add $(SLX_VMWARE_PATH) to your list).\nCopy your *.vmdk files into $(SLX_VMWARE_PATH). For interactive mode add for each virtual machine (*.vmdk) a .desktop file into ./vmsessions (example file $(SLX_VMWARE_PATH)/templ/desktop.template). Don't forget to install Xdialog!"

uninstall:
	@echo -e "Uninstalling openslx.org project files but keeping configs \
and stage1\nfiles in $SLX_PRIVATE_PATH (please remove manually)"
	@rm -rf $(SLX_BASE_PATH)
	@rm -rf $(SLX_PUBLIC_PATH)
	@rm $(USR_BIN_PATH)/{mkdxsinitrd,slx*}

clean:
	@echo "Cleanup OpenSLX source directory "
	@for file in openslx-*.tar.bz2; do \
		rm -f $${file}; \
	done
