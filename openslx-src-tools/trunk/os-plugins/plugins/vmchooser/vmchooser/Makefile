
STATIC=# -static
CXX=g++
CFLAGS=-c -O2 -I../fltk-2/include/ -I. -Wall -g3 `xml2-config --cflags`
BOOST=-lboost_regex-s
LDFLAGS=-L../fltk-2/lib/ ../fltk-2/lib/libfltk2.a -lpng ../fltk-2/lib/libfltk2_images.a -ljpeg -lz -lXi -lXinerama -lpthread -lm -lXext -lsupc++ -lXrender -lfontconfig -lxml2 -lXft -lXdmcp -lXau -ldl -lz -lfreetype -lX11

all: main.o anyoption.o SWindow.o readXmlDir.o readLinSess.o runImage.o addPrinters.o addScanners.o
	${CXX} ${STATIC} main.o anyoption.o SWindow.o runImage.o readLinSess.o readXmlDir.o addPrinters.o addScanners.o -o vmchooser ${LDFLAGS} ${BOOST}
	#strip vmchooser

main.o: main.cxx
	${CXX} ${CFLAGS} -c main.cxx -o main.o	

anyoption.o: anyoption.cpp inc/anyoption.h
	${CXX} ${CFLAGS} -o anyoption.o anyoption.cpp
	
SWindow.o: SWindow.cxx inc/SWindow.h
	${CXX} ${CFLAGS} -c SWindow.cxx -o SWindow.o

readXmlDir.o: readXmlDir.cxx inc/functions.h
	${CXX} ${CFLAGS} -o readXmlDir.o readXmlDir.cxx

readLinSess.o: readLinSess.cxx inc/functions.h
	${CXX} ${CFLAGS} -o readLinSess.o readLinSess.cxx

runImage.o: runImage.cxx inc/functions.h
	${CXX} ${CFLAGS} -o runImage.o runImage.cxx

addPrinters.o: addPrinters.cxx inc/functions.h
	${CXX} ${CFLAGS} -o addPrinters.o addPrinters.cxx

addScanners.o: addScanners.cxx inc/functions.h
	${CXX} ${CFLAGS} -o addScanners.o addScanners.cxx

clean:
	rm -rf *.o vmchooser

install:
	cp vmchooser ../../../../../../openslx/trunk/os-plugins/plugins/vmchooser/files/
