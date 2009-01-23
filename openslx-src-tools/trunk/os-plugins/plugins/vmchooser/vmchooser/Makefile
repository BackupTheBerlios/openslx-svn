
STATIC=# -static
CXX=g++
CFLAGS=-c -O2 -I../fltk-2/include/ -I. -Wall -g3
XMLFLAG=`xml2-config --cflags`
BOOST=-lboost_regex-s
LDFLAGS=-L../fltk-2/lib/ ../fltk-2/lib/libfltk2.a -lpng ../fltk-2/lib/libfltk2_images.a -ljpeg -lz -lXi -lXinerama -lpthread -lm -lXext -lsupc++ -lXrender -lfontconfig -lxml2 -lXft -lXdmcp -lXau -ldl -lz -lfreetype -lX11

all: main SWindow readXmlDir readLinSess runImage
	${CXX} ${STATIC} main.o SWindow.o runImage.o readLinSess.o readXmlDir.o -o vmchooser ${LDFLAGS} ${BOOST}
	strip vmchooser
	
SWindow:
	${CXX} ${CFLAGS} -c SWindow.cxx -o SWindow.o

readXmlDir:
	${CXX} ${CFLAGS} ${XMLFLAG} -o readXmlDir.o readXmlDir.cxx

readLinSess:
	${CXX} ${CFLAGS} -o readLinSess.o readLinSess.cxx

runImage:
	${CXX} ${CFLAGS} -o runImage.o runImage.cxx

main:
	${CXX} ${CFLAGS} -c main.cxx -o main.o


clean:
	rm -rf *.o test

install:
	cp vmchooser ../../../../../../openslx/trunk/os-plugins/plugins/vmchooser/files/
