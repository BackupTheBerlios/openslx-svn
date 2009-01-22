
STATIC= -static
CXX=g++
CFLAGS=-c -O2 -I../fltk-2/include/ -I. -Wall
XMLFLAG=`xml2-config --cflags`
LDFLAGS=`../fltk-2/bin/fltk2-config --ldstaticflags` -lXrender -lfontconfig -lxml2 -lXft -lXdmcp -lXau -ldl -lz -lfreetype -lX11

all: main SWindow readXmlDir runImage
	${CXX} ${STATIC} main.o SWindow.o runImage.o readXmlDir.o -o vmchooser ${LDFLAGS}
	strip vmchooser

SWindow:
	${CXX} ${CFLAGS} -c SWindow.cxx -o SWindow.o

readXmlDir:
	${CXX} ${CFLAGS} ${XMLFLAG} -o readXmlDir.o readXmlDir.cxx

runImage:
	${CXX} ${CFLAGS} -o runImage.o runImage.cxx

main:
	${CXX} ${CFLAGS} -c main.cxx -o main.o


clean:
	rm -rf *.o vmchooser
