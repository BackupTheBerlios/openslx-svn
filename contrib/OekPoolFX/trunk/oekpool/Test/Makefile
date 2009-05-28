TARGET  := oekpool_test
SRCS    := main.cpp NetworkTests.cpp
OBJS    := ${SRCS:.cpp=.o}
DEPS    := ${SRCS:.cpp=.dep} 
XDEPS   := $(wildcard ${DEPS})
OBJ_BASE := $(filter-out ../main.o, $(wildcard ../*.o))

CC	= g++
DEBUG_CCFLAGS = -O0 -Wall -I/usr/include -I. -I.. -I/usr/include/ldap -I../lib/ldapc++ -I../lib/libSockets -I/usr/include/libxml2 -ggdb #-ggdb #-Werror
CCFLAGS = -O2 -Wall -I/usr/include -I. -I.. -I../lib/ldapc++ -I../lib/libSockets -I/usr/include/libxml2
LDFLAGS = -L/usr/lib -lldap -lxml2 $(OBJ_BASE)
LIBS    = ../lib/libldapcpp.a ../lib/libSockets.a #-lboost_statechart

.PHONY: all clean distclean 
all:: ${TARGET} 

ifneq (${XDEPS},) 
include ${XDEPS} 
endif 

${TARGET}: $(OBJS)
	${CC} ${LDFLAGS} -o $@ $^ ${LIBS} 
	strip $@

test: $(OBJS)
	${CC} ${LDFLAGS} -o ${TARGET}_dbg $^ ${LIBS} 

#${DBG_OBJS}: %.o: %.cpp %.dep
#	${CC} ${DEBUG_CCFLAGS} -o $@ -c $<


# ADD HERE DEBUG_ to the CCFLAGS to set to debug configuration
${OBJS}: %.o: %.cpp %.dep
	${CC} ${DEBUG_CCFLAGS} -o $@ -c $< 

${DEPS}: %.dep: %.cpp Makefile 
	${CC} ${CCFLAGS} -MM $< > $@ 

clean::
	rm -f *~ *.o ${TARGET}

#install:
#	 add here installation command

distclean:: clean
