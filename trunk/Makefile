# Makefile for creating project tarball and installing the project
# to the various destination directories
#
# Lars Mueller <lm@openslx.com>, 2006, 2007
# Dirk von Suchodoletz <dvs@openslx.com>, 2006, 2007
# Michael Janczyk, 2006
#
# (c) 2006, 2007 - OpenSLX GmbH

DESTDIR = /

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

ifeq ($(SLX_INSTALL_LOG),)
	SLX_INSTALL_LOG = install.log
endif
#When adding new directory variables above, consider to add them to the
#packaging tool for .deb packages too.

tarball:
	@OPENSLX_VERSION_SVNREV=$$( svnversion); \
	if test "$${OPENSLX_SVN_SNAPSHOT}" = "0"; then \
		unset OPENSLX_SVN_SNAPSHOT; \
		echo "OPENSLX_SVN_SNAPSHOT=\"0\"" \
			>REVISION; \
	else \
		OPENSLX_SVN_SNAPSHOT="1"; \
		rm -f REVISION; \
	fi; \
	. ./VERSIONS; \
	echo "OPENSLX_VERSION_SVNREV=\"$${OPENSLX_VERSION_SVNREV}\"" \
		>>REVISION; \
	echo "Creating OpenSLX $${OPENSLX_VERSION_STRING} tar ball "; \
	if test -e "../openslx-$${OPENSLX_VERSION_STRING}" -a \
	! -L "../openslx-$${OPENSLX_VERSION_STRING}"; then \
		echo "Error: ../openslx-$${OPENSLX_VERSION_STRING} exists and is not a sym link! "; \
		exit 1; \
	fi; \
	svn_repo_name=$$( pwd); \
	svn_repo_name="$${svn_repo_name##*/}"; \
	if ! test -L "../openslx-$${OPENSLX_VERSION_STRING}"; then \
		cd .. >/dev/null; \
		ln -s "$${svn_repo_name}" "openslx-$${OPENSLX_VERSION_STRING}"; \
		cd - >/dev/null; \
		OPENSLX_SOURCEDIR_SYMLINK_CREATED="yes"; \
	fi; \
	echo -e "$(SLX_CONFIG_PATH)\n\
$(SLX_BASE_PATH)\n\
$(SLX_PRIVATE_PATH)\n\
$(SLX_PUBLIC_PATH)\n\
$(USR_BIN_PATH)/*" \
		>packaging/rpm/openslx-filelist; \
	cd .. >/dev/null; \
	tar cfhj \
		"$${svn_repo_name}/openslx-$${OPENSLX_VERSION_STRING}.tar.bz2" \
		--exclude-from="$${svn_repo_name}/tools/tar_exclude_from" \
		"openslx-$${OPENSLX_VERSION_STRING}/"; \
	test "$${OPENSLX_SOURCEDIR_SYMLINK_CREATED}" = "yes" && \
		rm -f "openslx-$${OPENSLX_VERSION_STRING}"; \
	cd - >/dev/null; \
	rm REVISION packaging/rpm/openslx-filelist

release-tarball:
	@export OPENSLX_SVN_SNAPSHOT=0; \
	make tarball

install:
	@echo "Checking installation requirements..."; \
	echo $$(date) >${SLX_INSTALL_LOG}; \
	if ! perl -e '$$x=2' 2>>${SLX_INSTALL_LOG} ; then \
		echo "  Perl is required, please install it."; \
		exit 1; \
	fi; \
	# many of the following modules are part of core perl, but we check \
	# for them just to be sure... \
	for m in Carp DBI Fcntl FindBin Getopt::Long Pod::Usage ; do \
		if ! perl -e "use $$m" 2>>${SLX_INSTALL_LOG} ; then \
			echo "  The perl-module '$$m' is required, please install it."; \
			exit 1; \
		fi; \
	done; \
	# specific database modules are optional, but we tell the user if \
	# support for a database is missing: \
	DEFAULT_DB_TYPE=""; \
	for m in SQLite CSV mysql; do \
		if ! perl -e "use DBD::$$m" 2>>${SLX_INSTALL_LOG} ; then \
			echo -e "  'DBD::$$m' not found, so $$m-databases will not be \
supported."; \
		else \
			if test "$${DEFAULT_DB_TYPE}X" = "X"; then \
				DEFAULT_DB_TYPE=$$m; \
				echo "  db-type => $$m"; \
			fi; \
		fi; \
	done; \
	if test "$${DEFAULT_DB_TYPE}X" = "X"; then \
		echo "  None of the DB-modules is available! Please install one of them."; \
		exit 1; \
	else \
		echo $${DEFAULT_DB_TYPE} >DEFAULT-DB-TYPE; \
	fi;
	@echo "Installing OpenSLX project files"
	@mkdir -p $(DESTDIR)$(SLX_CONFIG_PATH) \
	       -p $(DESTDIR)$(SLX_BASE_PATH)/lib \
	       -p $(DESTDIR)$(SLX_BIN_PATH) \
	       -p $(DESTDIR)$(SLX_SHARE_PATH)/templates \
	       -p $(DESTDIR)$(SLX_SHARE_PATH)/initramfs \
	       -p $(DESTDIR)$(SLX_SHARE_PATH)/busybox \
	       -p $(DESTDIR)$(SLX_SHARE_PATH)/squashfs \
	       -p $(DESTDIR)$(SLX_PRIVATE_PATH)/config/default/initramfs \
	       -p $(DESTDIR)$(SLX_PRIVATE_PATH)/config/default/rootfs \
	       -p $(DESTDIR)$(SLX_PRIVATE_PATH)/db \
	       -p $(DESTDIR)$(SLX_PRIVATE_PATH)/stage1 \
	       -p $(DESTDIR)$(SLX_PUBLIC_PATH) \
	       -p $(DESTDIR)$(SLX_TFTPBOOT_PATH) \
	       -p $(DESTDIR)$(SLX_SHARE_PATH)/themes
	@for dir in $(USR_BIN_PATH); do \
		test -d $(DESTDIR)$${dir} || \
			mkdir -p $(DESTDIR)$${dir}; \
	done
	@# copy license
	@cp COPYING $(DESTDIR)$(SLX_BASE_PATH)/
	@# copy initramfs generator scripts (and inject SLX_CONFIG_PATH on the way):
	@cp ./initramfs/mkdxsinitrd $(DESTDIR)$(SLX_BIN_PATH)/
#@cp ./initramfs/slxmkramfs $(DESTDIR)$(SLX_BIN_PATH)/
	@sed -e "s,@@@SLX_CONFIG_PATH@@@,$(SLX_CONFIG_PATH)," \
	  -i $(DESTDIR)$(SLX_BIN_PATH)/mkdxsinitrd
#@sed -e "s,@@@SLX_CONFIG_PATH@@@,$(SLX_CONFIG_PATH)," \
#  -i $(DESTDIR)$(SLX_BIN_PATH)/slxmkramfs

	@# copy all PERL-scripts and their required modules:
	@cp bin/slx* $(DESTDIR)$(SLX_BIN_PATH)/
	@cp config-db/slx* $(DESTDIR)$(SLX_BIN_PATH)/
	@cp installer/slx* $(DESTDIR)$(SLX_BIN_PATH)/
	@tar --exclude=.svn -cp -C lib OpenSLX distro-info | \
	  tar -xp -C $(DESTDIR)$(SLX_BASE_PATH)/lib
	@tar --exclude=.svn -cp -C config-db OpenSLX | \
	  tar -xp -C $(DESTDIR)$(SLX_BASE_PATH)/lib
	@tar --exclude=.svn -cp -C installer OpenSLX | \
	  tar -xp -C $(DESTDIR)$(SLX_BASE_PATH)/lib

	@# link all binaries & scripts into user-path:
	@ln -sf $(SLX_BIN_PATH)/slx* $(DESTDIR)$(USR_BIN_PATH)/
	@ln -sf $(SLX_BIN_PATH)/mkdxsinitrd $(DESTDIR)$(USR_BIN_PATH)/

	@# copy shareable data:
	@cd initramfs/initrd-stuff; tar --exclude=.svn -cp * | \
	  tar -xp -C $(DESTDIR)$(SLX_SHARE_PATH)/initramfs; cd ../..
	@tar --exclude=.svn -cp -C initramfs distro-specs | \
	  tar -xp -C $(DESTDIR)$(SLX_SHARE_PATH)
	@cp -p config-db/PXE-template.example \
	  $(DESTDIR)$(SLX_CONFIG_PATH)/
	@cp -a installer/default_files/machine-setup.default \
	  $(DESTDIR)$(SLX_SHARE_PATH)/templates/
	@tar --exclude=.svn -cp -C installer/default_files tftpboot | \
	  tar -xp -C $(DESTDIR)$(SLX_SHARE_PATH)
	@cd theming; tar --exclude=.svn -cp * | \
	  tar -xp -C $(DESTDIR)$(SLX_SHARE_PATH)/themes; cd ..
	@cp -pP tools/busybox{,.links,.x86_64,.i586} \
	  $(DESTDIR)$(SLX_SHARE_PATH)/busybox/
	@cp -p tools/mksquashfs $(DESTDIR)$(SLX_SHARE_PATH)/squashfs/

	@# create pre-/postinit scripts for us in initramfs:
	@echo -e "#!/bin/sh\n#\n# This script allows the local admin to \
extend the\n# capabilities at the beginning of the initramfs (stage3). \
The toolset is rather\n# restricted and you have to keep in mind that \
stage4 rootfs has the\n# prefix '/mnt'." \
	  > $(DESTDIR)$(SLX_PRIVATE_PATH)/config/default/initramfs/preinit.local
	@echo -e "#!/bin/sh\n#\n# This script allows the local admin to \
extend the\n# capabilities at the end of the initramfs (stage3). The \
toolset is rather\n# restricted and you have to keep in mind that stage4 \
rootfs has the\n# prefix '/mnt'. But you might use some special slx \
functions via\n# inclusion: '. /etc/functions' ..." \
	  > $(DESTDIR)$(SLX_PRIVATE_PATH)/config/default/initramfs/postinit.local
	@chmod u+x $(DESTDIR)$(SLX_PRIVATE_PATH)/config/default/initramfs/*init.local

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
	  > $(DESTDIR)$(SLX_CONFIG_PATH)/settings.default
	@test -e $(DESTDIR)$(SLX_CONFIG_PATH)/settings.local || \
	  echo -e "# local setup for openslx (overrides settings.default)\n" \
	    > $(DESTDIR)$(SLX_CONFIG_PATH)/settings.local

	@# create slxversion script:
	@if test -e REVISION; then \
		. REVISION; \
	else \
		OPENSLX_VERSION_SVNREV=$$(svnversion .); \
	fi; \
	test "$${OPENSLX_SVN_SNAPSHOT}" = "0" && \
		unset OPENSLX_SVN_SNAPSHOT || \
		OPENSLX_SVN_SNAPSHOT="1"; \
	. ./VERSIONS; \
	  echo -e "#! /bin/sh\n\necho $${OPENSLX_VERSION_STRING}" \
	    > $(DESTDIR)${SLX_BIN_PATH}/slxversion
	@chmod a+x $(DESTDIR)${SLX_BIN_PATH}/slxversion
	@ln -sf $(SLX_BIN_PATH)/slxversion $(DESTDIR)$(USR_BIN_PATH)/
	@# set default db-type:
	@DEFAULT_DB_TYPE=$$(cat DEFAULT-DB-TYPE); \
	echo -n '  '; slxsettings --db-type="$${DEFAULT_DB_TYPE}"; \

vmware_install:
	@# we should read the config file here or better have a separate
	@# script for installing vmware related stuff
	@echo "Installing VMware files to $(SLX_VMWARE_PATH)"
	@mkdir -p $(SLX_VMWARE_PATH)/templ \
	       -p $(SLX_VMWARE_PATH)/vmsessions/kdm
	@cp -a vmware/* $(SLX_VMWARE_PATH)/templ/
	@echo -e "Please configure your exports (add $(SLX_VMWARE_PATH) to your list).\nCopy your *.vmdk files into $(SLX_VMWARE_PATH). For interactive mode add for each virtual machine (*.vmdk) a .desktop file into ./vmsessions (example file $(SLX_VMWARE_PATH)/templ/desktop.template). Don't forget to install Xdialog!"

uninstall:
	@echo "Uninstalling openslx.org project files but keeping configs \
and stage1"
	@echo "files in $(SLX_PRIVATE_PATH) (please remove manually)"
	@rm -rf $(SLX_BASE_PATH)
	@rm -rf $(SLX_PUBLIC_PATH)
	@rm -f $(USR_BIN_PATH)/slx*
	@rm -f $(USR_BIN_PATH)/mkdxsinitrd

clean:
	@echo "Cleanup OpenSLX source directory "
	@for file in $(SLX_INSTALL_LOG) openslx-*.tar.bz2; do \
		rm -f $${file}; \
	done
