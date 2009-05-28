TARGET  := oekpool
SRCS    := main.cpp ClientStates.cpp Client.cpp Network.cpp Ssh.cpp Ldap.cpp Configuration.cpp Utility.cpp
OBJS    := ${SRCS:.cpp=.o}
DEPS    := ${SRCS:.cpp=.dep} 
XDEPS   := $(wildcard ${DEPS})

CC	= g++
DEBUG_CCFLAGS = -O0 -Wall -I/usr/include -I. -I/usr/include/ldap -Ilib/ldapc++ -Ilib/libSockets -I/usr/include/libxml2 -ggdb #-ggdb #-Werror
CCFLAGS = -O2 -Wall -I/usr/include -I. -Ilib/ldapc++ -Ilib/libSockets -I/usr/include/libxml2
LDFLAGS = -L/usr/lib -lldap -lxml2
LIBS    = lib/libldapcpp.a lib/libSockets.a #-lboost_statechart

.PHONY: all clean distclean 
all:: ${TARGET} 

ifneq (${XDEPS},) 
include ${XDEPS} 
endif 

${TARGET}: $(OBJS)
	${CC} ${LDFLAGS} -o $@ $^ ${LIBS} 
	strip $@

debug: $(OBJS)
	${CC} ${LDFLAGS} -o ${TARGET}_dbg $^ ${LIBS} 

#${DBG_OBJS}: %.o: %.cpp %.dep
#	${CC} ${DEBUG_CCFLAGS} -o $@ -c $<


# ADD HERE DEBUG_ to the CCFLAGS to set to debug configuration
${OBJS}: %.o: %.cpp %.dep
	${CC} ${DEBUG_CCFLAGS} -o $@ -c $< 

${DEPS}: %.dep: %.cpp Makefile 
	${CC} ${CCFLAGS} -MM $< > $@

test: debug
	make -C Test test

clean::
	rm -f *~ *.o ${TARGET}

#install:
#	 add here installation command

distclean:: clean
