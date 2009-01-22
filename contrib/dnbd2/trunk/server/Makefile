#
# server/Makefile
#

CPPFLAGS = -I../include
CFLAGS   = -Wall -O2 -D_GNU_SOURCE -D_FILE_OFFSET_BITS=64
VPATH    = ../include
APP      = dnbd2-server

all: $(APP)

install: $(APP)
	cp $(APP) /usr/local/sbin

dnbd2-server: main.o config.o query.o tree.o file.o
	$(CC) -o $@ $^

main.o: config.h query.h tree.h file.h dnbd2.h

config.o: config.h tree.h file.h dnbd2.h

query.o: query.h tree.h file.h dnbd2.h

tree.o: tree.h dnbd2.h

file.o: file.h

.PHONY:
clean:
	$(RM) *.o *~ $(APP)
