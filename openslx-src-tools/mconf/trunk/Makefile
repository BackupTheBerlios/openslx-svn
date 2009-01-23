CC = /usr/bin/gcc
LIBS = -lncurses
INCLUDES = -I/usr/include/ncurses -I.
OPTS = -DKBUILD_NO_NLS -DCURSES_LOC="<ncurses.h>" -DLOCALE -g -O2

all:  zconf.tab.o conf.o mconf.o lxdialog_checklist.o lxdialog_util.o lxdialog_inputbox.o lxdialog_textbox.o lxdialog_yesno.o lxdialog_menubox.o 
	${CC} ${OPTS} ${INCLUDES} ${LIBS} mconf.o zconf.tab.o lxdialog/checklist.o lxdialog/util.o lxdialog/inputbox.o lxdialog/textbox.o lxdialog/yesno.o lxdialog/menubox.o -o mconf

zconf.tab.o:
	${CC} ${OPTS} ${INCLUDES} -c zconf.tab.c -o zconf.tab.o 

conf.o: 
	${CC} ${OPTS} ${INCLUDES} -c conf.c -o conf.o 

mconf.o:
	${CC} ${OPTS} ${INCLUDES} -c mconf.c -o mconf.o 

lxdialog_checklist.o:
	${CC} ${OPTS} ${INCLUDES} -c lxdialog/checklist.c -o lxdialog/checklist.o 

lxdialog_util.o:
	${CC} ${OPTS} ${INCLUDES} -c lxdialog/util.c -o lxdialog/util.o 

lxdialog_inputbox.o:
	${CC} ${OPTS} ${INCLUDES} -c lxdialog/inputbox.c -o lxdialog/inputbox.o 

lxdialog_textbox.o:
	${CC} ${OPTS} ${INCLUDES} -c lxdialog/textbox.c -o lxdialog/textbox.o 

lxdialog_yesno.o:
	${CC} ${OPTS} ${INCLUDES} -c lxdialog/yesno.c -o lxdialog/yesno.o 

lxdialog_menubox.o:
	${CC} ${OPTS} ${INCLUDES} -c lxdialog/menubox.c -o lxdialog/menubox.o 

clean:
	rm mconf *.o lxdialog/*.o
