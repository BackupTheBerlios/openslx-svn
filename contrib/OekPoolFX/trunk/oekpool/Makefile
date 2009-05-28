TARGET  := oekpool
SRCS    := main.cpp ClientStates.cpp Client.cpp Network.cpp Ssh.cpp Ldap.cpp
OBJS    := ${SRCS:.cpp=.o}
DEPS    := ${SRCS:.cpp=.dep} 
XDEPS   := $(wildcard ${DEPS}) 

CC	= g++
DEBUG_CCFLAGS = -O0 -Wall -I/usr/include -I. -I/usr/include/ldap -Ilib/ldapc++ -ggdb #-ggdb #-Werror
CCFLAGS = -O2 -Wall -I/usr/include -I. -Ilib/ldapc++
LDFLAGS = -L/usr/lib -lldap
LIBS    = #-lboost_statechart

.PHONY: all clean distclean 
all:: ${TARGET} 

ifneq (${XDEPS},) 
include ${XDEPS} 
endif 

${TARGET}: $(OBJS)
	${CC} ${LDFLAGS} -o $@ $^ ${LIBS} 
	strip $@

debug: $(OBJS)
	${CC} ${LDFLAGS} -o ${TARGET}_dbg $^ ${LIBS} lib/libldapcpp.a 

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
