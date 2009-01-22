#
# Global Makefile
#

DIRS = server test-app kernel init-script
VPATH = $(DIRS)

all:
	@for dir in $(DIRS) ; do make -C $$dir ; done

install:
	@for dir in $(DIRS) ; do make -C $$dir install ; done

.PHONY:
clean:
	@for dir in $(DIRS) ; do make -C $$dir clean ; done
