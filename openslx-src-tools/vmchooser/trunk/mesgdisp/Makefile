CC=g++
LIBS=-lXinerama -lXi -lXrender -lXft ../fltk-2/lib/libfltk2.a -I../fltk-2/include/

TARGET=mesgdisp
SRC=$(wildcard *.cxx)

all: MessageWindow.cxx
	$(CC) -o $(TARGET) $(SRC) $(LIBS)
	strip $(TARGET)

install: all
	cp $(TARGET) ../../../../openslx/trunk/os-plugins/plugins/vmchooser/files/

