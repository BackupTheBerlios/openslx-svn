#
# test-apps/Makefile
#

CPPFLAGS = -I../include
CFLAGS   = -Wall -O2 -D_GNU_SOURCE -D_FILE_OFFSET_BITS=64
VPATH    = ../include
APP      = data-client

all: $(APP)

install:
	cp $(APP) /usr/local/bin

.PHONY:
clean:
	$(RM) *.o *~ $(APP)
