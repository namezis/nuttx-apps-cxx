############################################################################
# apps/Makefile
#
#   Copyright (C) 2011 Uros Platise. All rights reserved.
#   Copyright (C) 2011-2014, 2018-2019 Gregory Nutt. All rights reserved.
#   Authors: Uros Platise <uros.platise@isotel.eu>
#            Gregory Nutt <gnutt@nuttx.org>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with the
#    distribution.
# 3. Neither the name NuttX nor the names of its contributors may be
#    used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
# OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
# AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
############################################################################

APPDIR = $(CURDIR)
include $(APPDIR)/Make.defs

# Symbol table for loadable apps.

SYMTABSRC = symtab_apps.c
SYMTABOBJ = $(SYMTABSRC:.c=$(OBJEXT))

# Build targets

all: $(BIN)
.PHONY: import install dirlinks context context_serialize clean_context context_rest export .depdirs preconfig depend clean distclean
.PRECIOUS: $(BIN)

$(foreach SDIR, $(CONFIGURED_APPS), $(eval $(call SDIR_template,$(SDIR),all)))
$(foreach SDIR, $(CONFIGURED_APPS), $(eval $(call SDIR_template,$(SDIR),install)))
$(foreach SDIR, $(CONFIGURED_APPS), $(eval $(call SDIR_template,$(SDIR),context)))
$(foreach SDIR, $(CONFIGURED_APPS), $(eval $(call SDIR_template,$(SDIR),depend)))
$(foreach SDIR, $(CLEANDIRS), $(eval $(call SDIR_template,$(SDIR),clean)))
$(foreach SDIR, $(CLEANDIRS), $(eval $(call SDIR_template,$(SDIR),distclean)))

$(MKDEP): $(TOPDIR)/tools/mkdeps.c
	$(HOSTCC) $(HOSTINCLUDES) $(HOSTCFLAGS) $< -o $@

$(INCDIR): $(TOPDIR)/tools/incdir.c
	$(HOSTCC) $(HOSTINCLUDES) $(HOSTCFLAGS) $< -o $@

IMPORT_TOOLS = $(MKDEP) $(INCDIR)

# In the KERNEL build, we must build and install all of the modules.  No
# symbol table is needed

ifeq ($(CONFIG_BUILD_KERNEL),y)

install: $(foreach SDIR, $(CONFIGURED_APPS), $(SDIR)_install)

.import: $(foreach SDIR, $(CONFIGURED_APPS), $(SDIR)_all)
	$(Q) $(MAKE) install TOPDIR="$(TOPDIR)"

import: $(IMPORT_TOOLS)
	$(Q) $(MAKE) context TOPDIR="$(APPDIR)$(DELIM)import"
	$(Q) $(MAKE) depend TOPDIR="$(APPDIR)$(DELIM)import"
	$(Q) $(MAKE) .import TOPDIR="$(APPDIR)$(DELIM)import"

else

# In FLAT and protected modes, the modules have already been created.  A
# symbol table is required.

ifeq ($(CONFIG_BUILD_LOADABLE),)

$(BIN): $(foreach SDIR, $(CONFIGURED_APPS), $(SDIR)_all)

else

$(SYMTABSRC): $(foreach SDIR, $(CONFIGURED_APPS), $(SDIR)_all)
	$(Q) $(MAKE) install TOPDIR="$(TOPDIR)"
	$(Q) $(APPDIR)$(DELIM)tools$(DELIM)mksymtab.sh $(BINDIR) >$@.tmp
	$(Q) $(call TESTANDREPLACEFILE, $@.tmp, $@)

$(SYMTABOBJ): %$(OBJEXT): %.c
	$(call COMPILE, -fno-lto $<, $@)

$(BIN): $(SYMTABOBJ)
ifeq ($(CONFIG_CYGWIN_WINTOOL),y)
	$(call ARLOCK, "${shell cygpath -w $(BIN)}", $^)
else
	$(call ARLOCK, $(BIN), $^)
endif

endif # !CONFIG_BUILD_LOADABLE

install: $(foreach SDIR, $(CONFIGURED_APPS), $(SDIR)_install)

# Link nuttx

HEAD_OBJ += $(wildcard $(APPDIR)$(DELIM)import$(DELIM)startup$(DELIM)*$(OBJEXT))
HEAD_OBJ += $(wildcard $(APPDIR)$(DELIM)builtin$(DELIM)*$(OBJEXT))

.import: $(BIN) install
	$(Q) echo "LD: nuttx"
	$(Q) $(LD) --entry=__start $(LDFLAGS) $(LDLIBPATH) $(EXTRA_LIBPATHS) \
	  -L$(APPDIR)$(DELIM)import$(DELIM)scripts -T$(LDNAME) \
	  -o nuttx$(EXEEXT) $(HEAD_OBJ) $(EXTRA_OBJS) $(LDSTARTGROUP) \
	  $(BIN) $(LDLIBS) $(EXTRA_LIBS) $(LDENDGROUP)
ifeq ($(CONFIG_INTELHEX_BINARY),y)
	$(Q) echo "CP: nuttx.hex"
	$(Q) $(OBJCOPY) $(OBJCOPYARGS) -O ihex nuttx$(EXEEXT) nuttx.hex
endif
ifeq ($(CONFIG_RAW_BINARY),y)
	$(Q) echo "CP: nuttx.bin"
	$(Q) $(OBJCOPY) $(OBJCOPYARGS) -O binary nuttx$(EXEEXT) nuttx.bin
endif
	$(call POSTBUILD, $(APPDIR))

import: $(IMPORT_TOOLS)
	$(Q) $(MAKE) context TOPDIR="$(APPDIR)$(DELIM)import"
	$(Q) $(MAKE) depend TOPDIR="$(APPDIR)$(DELIM)import"
	$(Q) $(MAKE) .import TOPDIR="$(APPDIR)$(DELIM)import"

endif # CONFIG_BUILD_KERNEL

dirlinks:
	$(Q) $(MAKE) -C platform dirlinks TOPDIR="$(TOPDIR)" APPDIR="$(APPDIR)"

context_rest: $(foreach SDIR, $(CONFIGURED_APPS), $(SDIR)_context)

context_serialize:
	$(Q) $(MAKE) -C builtin context TOPDIR="$(TOPDIR)" APPDIR="$(APPDIR)"
	$(Q) $(MAKE) context_rest TOPDIR="$(TOPDIR)"

context: context_serialize

Kconfig:
	$(foreach SDIR, $(BUILDIRS), $(call MAKE_template,$(SDIR),preconfig))
	$(Q) $(MKKCONFIG)

preconfig: Kconfig

export:
ifneq ($(EXPORTDIR),)
ifneq ($(BUILTIN_REGISTRY),)
	$(Q) mkdir -p "${EXPORTDIR}"/registry || exit 1; \
	for f in "${BUILTIN_REGISTRY}"/*.bdat "${BUILTIN_REGISTRY}"/*.pdat ; do \
		[ -f "$${f}" ] && cp -f "$${f}" "${EXPORTDIR}"/registry ; \
	done
endif
endif

.depdirs: $(foreach SDIR, $(CONFIGURED_APPS), $(SDIR)_depend)

.depend: Makefile .depdirs
	$(Q) touch $@

depend: .depend

clean_context:
	$(Q) $(MAKE) -C platform clean_context TOPDIR="$(TOPDIR)" APPDIR="$(APPDIR)"
	$(Q) $(MAKE) -C builtin clean_context TOPDIR="$(TOPDIR)" APPDIR="$(APPDIR)"

clean: $(foreach SDIR, $(CLEANDIRS), $(SDIR)_clean)
	$(call DELFILE, $(SYMTABSRC))
	$(call DELFILE, $(SYMTABOBJ))
	$(call DELFILE, $(BIN))
	$(call DELFILE, Kconfig)
	$(call DELDIR, $(BINDIR))
	$(call CLEAN)

distclean: $(foreach SDIR, $(CLEANDIRS), $(SDIR)_distclean)
ifeq ($(CONFIG_WINDOWS_NATIVE),y)
	$(Q) ( if exist  external ( \
		echo ********************************************************" \
		echo * The external directory/link must be removed manually *" \
		echo ********************************************************" \
	)
else
	$(Q) ( if [ -e external ]; then \
		echo "********************************************************"; \
		echo "* The external directory/link must be removed manually *"; \
		echo "********************************************************"; \
		fi; \
	)
endif
	$(call DELFILE, *.lock)
	$(call DELFILE, .depend)
	$(call DELFILE, $(SYMTABSRC))
	$(call DELFILE, $(SYMTABOBJ))
	$(call DELFILE, $(BIN))
	$(call DELFILE, Kconfig)
	$(call DELDIR, $(BINDIR))
	$(call CLEAN)
