# Makefile for creating project tarball and installing the project
# to the various destination directories
#
# Lars Mueller <lm@openslx.com>, 2006, 2007
# Dirk von Suchodoletz <dvs@openslx.com>, 2006, 2007
# Michael Janczyk, 2006
#
# (c) 2006, 2007 - OpenSLX GmbH

# enforce the use of bash (/bin/sh might be a link to incomplete shells)
SHELL = /bin/bash

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
ifeq ($(SLX_PRIVATE_PATH),)
	SLX_PRIVATE_PATH = /var/opt/openslx
endif
ifeq ($(SLX_PUBLIC_PATH),)
	SLX_PUBLIC_PATH = /srv/openslx
endif
ifeq ($(SLX_TEMP_PATH),)
	SLX_TEMP_PATH = /tmp
endif

ifeq ($(SLX_INSTALL_LOG),)
	SLX_INSTALL_LOG = install.log
endif

tarball:
	@OPENSLX_VERSION_SVNREV=$$( svnversion .); \
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
	
install: check-upgrade
	@if test "${TRACE_INSTALLATION}" = "1"; then set -x; fi; \
	echo "Checking installation requirements..."; \
	echo $$(date) >${SLX_INSTALL_LOG}; \
	if ! perl -e '$$x=2' 2>>${SLX_INSTALL_LOG} ; then \
		echo "  Perl is required, please install it."; \
		exit 1; \
	fi;

	@   # many of the following modules are part of core perl, but we check
	@   # for them just to be sure...
	@for m in Carp Clone Config::General Cwd DBI Digest::MD5 Encode Fcntl \
	          File::Basename File::Find File::Glob File::Path FindBin \
	          Getopt::Long List::Util Pod::Usage POSIX Socket Storable \
	          Sys::Hostname Term::ReadLine ; do \
		if ! perl -e "use $$m" 2>>${SLX_INSTALL_LOG} ; then \
			echo "  The perl module '$$m' is required, please install it."; \
			exit 1; \
		fi; \
	done;

	@   # specific database modules are optional, but we tell the user if
	@   # support for a database is missing:
	@DEFAULT_DB_TYPE=""; \
	if test -e ${SLX_CONFIG_PATH}/settings; then \
		echo "Reading local settings..."; \
		. ${SLX_CONFIG_PATH}/settings; \
	fi; \
	for m in $${SLX_DB_TYPE} SQLite mysql; do \
		if ! perl -Ilib -Iconfig-db -e "use OpenSLX::MetaDB::$$m" 2>>${SLX_INSTALL_LOG} ; then \
			echo -e "  'DBD::$$m' not found (or too old), so $$m-databases will not be \
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
	fi; \
	if ! which rsync >/dev/null 2>&1; then \
		echo "  rsync is required, please install it."; \
		exit 1; \
	fi; \
	echo "Installing OpenSLX project files"; \
	mkdir -p $(SLX_BUILD_PATH)$(SLX_CONFIG_PATH)/boot-env/pxe/themes \
	      -p $(SLX_BUILD_PATH)$(SLX_BASE_PATH)/lib \
	      -p $(SLX_BUILD_PATH)$(SLX_BASE_PATH)/bin \
        -p $(SLX_BUILD_PATH)$(SLX_BASE_PATH)/share/boot-env \
        -p $(SLX_BUILD_PATH)$(SLX_BASE_PATH)/share/busybox \
        -p $(SLX_BUILD_PATH)$(SLX_BASE_PATH)/share/initramfs \
        -p $(SLX_BUILD_PATH)$(SLX_BASE_PATH)/share/preboot \
        -p $(SLX_BUILD_PATH)$(SLX_BASE_PATH)/share/squashfs \
	      -p $(SLX_BUILD_PATH)$(SLX_BASE_PATH)/share/templates \
        -p $(SLX_BUILD_PATH)$(SLX_BASE_PATH)/share/ramfstools \
	      -p $(SLX_BUILD_PATH)$(SLX_PRIVATE_PATH)/config/default/initramfs \
	      -p $(SLX_BUILD_PATH)$(SLX_PRIVATE_PATH)/config/default/rootfs \
	      -p $(SLX_BUILD_PATH)${USR_BIN_PATH};

	@   # copy license
	@cp COPYING $(SLX_BUILD_PATH)$(SLX_BASE_PATH)/;

	@   # copy all PERL-scripts and their required modules:
	@cp bin/slx* $(SLX_BUILD_PATH)$(SLX_BASE_PATH)/bin/; \
	cp config-db/slx* $(SLX_BUILD_PATH)$(SLX_BASE_PATH)/bin/; \
	cp installer/slx* $(SLX_BUILD_PATH)$(SLX_BASE_PATH)/bin/; \
	cp os-plugins/slx* $(SLX_BUILD_PATH)$(SLX_BASE_PATH)/bin/; \
	tar --exclude=.svn -cp -C lib OpenSLX \
	  | tar -xp -C $(SLX_BUILD_PATH)$(SLX_BASE_PATH)/lib; \
  tar --exclude=.svn -cp -C boot-env OpenSLX \
    | tar -xp -C $(SLX_BUILD_PATH)$(SLX_BASE_PATH)/lib; \
	tar --exclude=.svn -cp -C config-db OpenSLX \
	  | tar -xp -C $(SLX_BUILD_PATH)$(SLX_BASE_PATH)/lib; \
	tar --exclude=.svn -cp -C initramfs OpenSLX \
	  | tar -xp -C $(SLX_BUILD_PATH)$(SLX_BASE_PATH)/lib; \
	tar --exclude=.svn -cp -C installer OpenSLX \
	  | tar -xp -C $(SLX_BUILD_PATH)$(SLX_BASE_PATH)/lib; \
	tar --exclude=.svn -cp -C os-plugins OpenSLX \
	  | tar -xp -C $(SLX_BUILD_PATH)$(SLX_BASE_PATH)/lib; \
	tar --exclude=.svn -cp -C os-plugins plugins \
	  | tar -xp -C $(SLX_BUILD_PATH)$(SLX_BASE_PATH)/lib; \

	@   # copy distro-info (some parts into /opt, others into /etc):
	@tar --exclude=.svn --exclude=*.example \
	    -cp -C lib distro-info \
	  | tar -xp -C $(SLX_BUILD_PATH)$(SLX_BASE_PATH)/share; \
	tar --exclude=.svn --exclude=prereqfiles --exclude=trusted-package-keys/* \
	    --exclude=*.default --exclude=mirrors \
	    -cp -C lib distro-info \
	  | tar -xp -C $(SLX_BUILD_PATH)$(SLX_CONFIG_PATH); \

	@   # link all binaries & scripts into user-path:
	@ln -sf $(SLX_BASE_PATH)/bin/slx* $(SLX_BUILD_PATH)$(USR_BIN_PATH)/; \

	@   # copy shareable data:
	@tar --exclude=.svn -cp -C initramfs preboot | \
	  tar -xp -C $(SLX_BUILD_PATH)$(SLX_BASE_PATH)/share; \
	tar --exclude=.svn -cp -C initramfs initrd-stuff/ | \
	  tar -xp --strip-components 1 \
	      -C $(SLX_BUILD_PATH)$(SLX_BASE_PATH)/share/initramfs; \
	tar --exclude=.svn -cp -C initramfs distro-specs | \
	  tar -xp -C $(SLX_BUILD_PATH)$(SLX_BASE_PATH)/share; \
  tar --exclude=.svn --exclude *.example -cp -C boot-env pxe | \
    tar -xp -C $(SLX_BUILD_PATH)$(SLX_BASE_PATH)/share/boot-env; \
  cp -p boot-env/pxe/menu-template.example \
    $(SLX_BUILD_PATH)$(SLX_CONFIG_PATH)/boot-env/pxe/; \
  cp -a installer/default_files/machine-setup.default \
    $(SLX_BUILD_PATH)$(SLX_BASE_PATH)/share/templates/; \
  cp -a installer/default_files/hwdata/{pcitable.local,Cards.local} \
    $(SLX_BUILD_PATH)$(SLX_BASE_PATH)/share/templates/; \
  tar --exclude=.svn -cp -C installer/default_files tftpboot | \
    tar -xp -C $(SLX_BUILD_PATH)$(SLX_BASE_PATH)/share; \
  cp -pP tools/busybox{,.x86_64,.i586} \
    $(SLX_BUILD_PATH)$(SLX_BASE_PATH)/share/busybox/; \
  cp -pP tools/{ddcprobe,915resolution}{,.x86_64,.i586} \
    $(SLX_BUILD_PATH)$(SLX_BASE_PATH)/share/ramfstools; \
  cp -p tools/mksquashfs $(SLX_BUILD_PATH)$(SLX_BASE_PATH)/share/squashfs/; \
  tar --exclude=.svn -cp -C initramfs tpm | \
    tar -xp -C $(SLX_BUILD_PATH)$(SLX_BASE_PATH)/share; \

	@   # create default config folder hierarchy:
	@perl -Ilib -e 'use OpenSLX::ConfigFolder; createConfigFolderForDefaultSystem();'

	@   # create complete default settings and empty local settings file:
	@echo -e "# default setup for OpenSLX-installation\
\n\
\n# paths that are fixed at packaging/installation time:\
\nSLX_BASE_PATH=${SLX_BASE_PATH}\
\nSLX_CONFIG_PATH=${SLX_CONFIG_PATH}\
\n\
\n# paths which can be adjusted after installation:\
\nSLX_PRIVATE_PATH=${SLX_PRIVATE_PATH}\
\nSLX_PUBLIC_PATH=${SLX_PUBLIC_PATH}\
\nSLX_TEMP_PATH=${SLX_TEMP_PATH}\n" \
	  > $(SLX_BUILD_PATH)$(SLX_BASE_PATH)/share/settings.default; \
	test -e $(SLX_BUILD_PATH)$(SLX_CONFIG_PATH)/settings || \
	  echo -e "# Local setup for OpenSLX (overrides default settings).\
\n#\n# Please look at $(SLX_BASE_PATH)/share/settings.default and the docs to learn\
\n# about the available options.\n" \
	    > $(SLX_BUILD_PATH)$(SLX_CONFIG_PATH)/settings; \

	@   # create slxversion script:
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
	    > $(SLX_BUILD_PATH)$(SLX_BASE_PATH)/bin/slxversion; \
	chmod a+x $(SLX_BUILD_PATH)$(SLX_BASE_PATH)/bin/slxversion; \
	ln -sf $(SLX_BASE_PATH)/bin/slxversion $(SLX_BUILD_PATH)$(USR_BIN_PATH)/; \

	@   # set default db-type:
	@DEFAULT_DB_TYPE=$$(cat DEFAULT-DB-TYPE); \
	rm DEFAULT-DB-TYPE; \
	echo -n '  '; slxsettings set db-type="$${DEFAULT_DB_TYPE}";

vmware_install:
	@# we should read the config file here or better have a separate
	@# script for installing vmware related stuff
	@echo "Installing VMware files to $(SLX_BASE_PATH)/vmware"
	@mkdir -p $(SLX_BASE_PATH)/vmware/templ \
	       -p $(SLX_BASE_PATH)/vmware/vmsessions/kdm
	@cp -a vmware/* $(SLX_BASE_PATH)/vmware/templ/
	@echo -e "Please configure your exports (add $(SLX_BASE_PATH)/vmware to your list).\nCopy your *.vmdk files into $(SLX_BASE_PATH)/vmware. For interactive mode add for each virtual machine (*.vmdk) a .desktop file into ./vmsessions (example file $(SLX_BASE_PATH)/vmware/templ/desktop.template). Don't forget to install Xdialog!"

prepare_upgrade:
	@rm -rf $(SLX_BASE_PATH)
	@rm -f $(USR_BIN_PATH)/slx*

uninstall:
	@echo "Uninstalling openslx.org project files but keeping configs \
and stage1"
	@rm -rf $(SLX_BASE_PATH)
	@echo "keeping files in $(SLX_CONFIG_PATH)"
	@echo "keeping files in $(SLX_PRIVATE_PATH)"
	@rm -rf $(SLX_PUBLIC_PATH)
	@rm -f $(USR_BIN_PATH)/slx*

mrproper:
	@echo "Wiping all!"
	@rm -rf $(SLX_BASE_PATH)
	@rm -rf $(SLX_CONFIG_PATH)
	@rm -rf $(SLX_PRIVATE_PATH)
	@rm -rf $(SLX_PUBLIC_PATH)
	@rm -f $(USR_BIN_PATH)/slx*

check-upgrade:
	@   # find out if there is an older version installed and, if so, clean that
	@INSTALLED_VERSION=$$(slxversion 2>/dev/null); \
	if ! test -z "$${INSTALLED_VERSION}"; then \
		if test -e REVISION; then \
			. REVISION; \
		else \
			OPENSLX_VERSION_SVNREV=$$(svnversion .); \
		fi; \
		test "$${OPENSLX_SVN_SNAPSHOT}" = "0" && \
			unset OPENSLX_SVN_SNAPSHOT || \
			OPENSLX_SVN_SNAPSHOT="1"; \
		. ./VERSIONS; \
		if test $${INSTALLED_VERSION} != $${OPENSLX_VERSION_STRING}; then \
			echo "preparing upgrade from version ($${INSTALLED_VERSION})"; \
			make prepare_upgrade; \
		fi; \
	fi

clean:
	@echo "Cleanup OpenSLX source directory "
	@for file in $(SLX_INSTALL_LOG) openslx-*.tar.bz2; do \
		rm -f $${file}; \
	done
