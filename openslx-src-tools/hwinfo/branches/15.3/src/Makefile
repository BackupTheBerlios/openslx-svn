TOPDIR		= ..
SUBDIRS		= hd isdn ids
TARGETS		= touch $(LIBHD) $(LIBHD_SO)
CLEANFILES	= $(LIBHD) $(LIBHD_D) $(LIBHD_SO) *.so *.so.* *.a

.PHONY: touch

include $(TOPDIR)/Makefile.common

ifneq "$(findstring $(ARCH), i386 x86_64 ia64)" ""
ifneq ($(LIBHD_BASE), libhd_tiny)
SUBDIRS	+= x86emu int10
endif
endif

#ifeq "$(findstring $(ARCH), i386 alpha)" ""
#SUBDIRS	:= $(filter-out pnpdump, $(SUBDIRS))
#endif

$(LIBHD): $(OBJS)
	ar r $@ $?
	@rm -f $(LIBHD_D)

ifdef SHARED_FLAGS
$(LIBHD_SO): $(LIBHD)
	$(CC) -shared $(SO_LIBS) -Wl,--whole-archive $(LIBHD) -Wl,--no-whole-archive \
		-Wl,-soname=$(LIBHD_SONAME) \
		-o $(LIBHD_SO) 
	ln -snf $(LIBHD_NAME) $(LIBHD_SONAME)
	ln -snf $(LIBHD_SONAME) $(LIBHD_BASE).so
else
$(LIBHD_SO):
endif

subdirs: touch

touch:
	@touch -r $(LIBHD) $(LIBHD_D) 2>/dev/null || true
