TARGET  := vmchooser
SRCS    := $(wildcard *.cxx)
OBJS    := ${SRCS:.cxx=.o} 
DEPS    := ${SRCS:.cxx=.dep} 
XDEPS   := $(wildcard ${DEPS}) 

CC	= g++
DEBUG_CCFLAGS = -O0 -Wall -I/usr/include -I../fltk-2/include/ -I. `xml2-config --cflags` -ggdb #-ggdb #-Werror
CCFLAGS = -O2 -Wall -I/usr/include -I../fltk-2/include/ -I. `xml2-config --cflags`
LDFLAGS = -L../fltk-2/lib/ -L/usr/lib 
LIBS    = -lpng ../fltk-2/lib/libfltk2_images.a -ljpeg -lz -lXi -lXinerama -lpthread -lm -lXext -lsupc++ -lXrender -lfontconfig -lxml2 -lXft -lXdmcp -lXau -ldl -lz -lfreetype -lX11 ../fltk-2/lib/libfltk2.a /usr/lib/libboost_regex-s.a /usr/lib/libboost_filesystem-s.a

.PHONY: all clean distclean 
all:: ${TARGET} 

ifneq (${XDEPS},) 
include ${XDEPS} 
endif 

${TARGET}: ${OBJS} 
	${CC} ${LDFLAGS} -o $@ $^  ${LIBS} 
	strip $@

debug: ${OBJS}
	${CC} ${LDFLAGS} -o vmchooserdbg $^ ${LIBS}

${OBJS}: %.o: %.cxx %.dep
	${CC} ${CCFLAGS} -o $@ -c $< 

${DEPS}: %.dep: %.cxx Makefile 
	${CC} ${CCFLAGS} -MM $< > $@ 

clean::
	rm -f *~ *.o ${TARGET} vmchooserdbg

install:
	cp vmchooser ../../../../openslx/trunk/os-plugins/plugins/vmchooser/files/

distclean:: clean
