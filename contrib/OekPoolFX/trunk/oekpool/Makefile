TARGET  := oekpool
SRCS    := main.cpp Client.cpp 
OBJS    := ${SRCS:.cpp=.o}
DEPS    := ${SRCS:.cpp=.dep} 
XDEPS   := $(wildcard ${DEPS}) 

CC	= g++
DEBUG_CCFLAGS = -O0 -Wall -I/usr/include -I. -ggdb #-ggdb #-Werror
CCFLAGS = -O2 -Wall -I/usr/include -I.
LDFLAGS = -L/usr/lib 
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
