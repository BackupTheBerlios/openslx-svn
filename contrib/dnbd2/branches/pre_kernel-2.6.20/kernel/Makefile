#
# kernel/Makefile
#

KDIR	:= /lib/modules/$(shell uname -r)/build
PWD	:= $(shell pwd)

obj-m := dnbd2.o
dnbd2-objs := fops.o sysfs.o servers.o devices.o misc.o core.o

all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

install:
	$(MAKE) -C $(KDIR) M=$(PWD) modules_install

clean:
	rm -rf *.o *.ko *~ *.symvers dnbd2.mod.c .*o.cmd .tmp_versions
