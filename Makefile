# Makefile for OpenGFX Extra SpinOff-NewGRF

MAKEFILELOCAL=Makefile.local
MAKEFILECONFIG=Makefile.config

SHELL = /bin/sh

# Add some OS detection and guess an install path (use the system's default)
OSTYPE=$(shell uname -s)
ifeq ($(OSTYPE),Linux)
INSTALLDIR=$(HOME)/.openttd/data
else
ifeq ($(OSTYPE),Darwin)
INSTALLDIR=$(HOME)/Documents/OpenTTD/data
else
ifeq ($(shell echo "$(OSTYPE)" | cut -d_ -f1),MINGW32)
INSTALLDIR=C:\Documents and Settings\$(USERNAME)\My Documents\OpenTTD\data
else
INSTALLDIR=
endif
endif
endif

# define a few repository references used also in makefile.config
GRF_REVISION = $(shell hg parent --template="{rev}\n")
GRF_MODIFIED = $(shell [ -n "`hg status '.' | grep -v '^?'`" ] && echo "M" || echo "")
REPO_TAGS    = $(shell hg parent --template="{tags}" | grep -v "tip" | cut -d\  -f1)

include ${MAKEFILECONFIG}

# OS detection: Cygwin vs Linux
ISCYGWIN = $(shell [ ! -d /cygdrive/ ]; echo $$?)
NFORENUM = $(shell [ \( $(ISCYGWIN) -eq 1 \) ] && echo renum.exe || echo renum)
GRFCODEC = $(shell [ \( $(ISCYGWIN) -eq 1 \) ] && echo grfcodec.exe || echo grfcodec)

# this overrides definitions from above:
-include ${MAKEFILELOCAL}

DIR_BASE       = $(GRF_FILENAME)-
VERSION_STRING = $(shell [ -n "$(REPO_TAGS)" ] && echo $(REPO_TAGS)$(GRF_MODIFIED) || echo $(GRF_NIGHTLYNAME)-r$(GRF_REVISION)$(GRF_MODIFIED))
DIR_NAME       = $(shell [ -n "$(REPO_TAGS)" ] && echo $(DIR_BASE)$(VERSION_STRING) || echo $(DIR_BASE)$(GRF_NIGHTLYNAME))
DIR_NAME_SRC   = $(DIR_BASE)$(VERSION_STRING)-source
# Tarname has no version: overwrite for make install
TAR_FILENAME   = $(DIR_NAME).$(TAR_SUFFIX)
# The release filenames bear the version being built.
ZIP_FILENAME   = $(DIR_BASE)$(VERSION_STRING).$(ZIP_SUFFIX)
BZIP_FILENAME  = $(DIR_BASE)$(VERSION_STRING).$(BZIP2_SUFFIX)

REPO_DIRS    = $(dir $(BUNDLE_FILES))

-include ${MAKEFILELOCAL}

vpath
vpath %.pfno $(GRF_DEF_DIR)
vpath %.nfo $(GRF_DEF_DIR)

.PHONY: clean all bundle bundle_tar bundle_zip bundle_bzip install release release_zip remake test

# Now, the fun stuff:

# Target for all:

all : test_rev $(GRF_FILENAME).$(GRF_SUFFIX)

-include ${MAKEFILEDEP}

test :
	$(_E) "Call of nforenum:             $(NFORENUM) $(NFORENUM_FLAGS)"
	$(_E) "Call of grfcodec:             $(GRFCODEC) $(GRFCODEC_FLAGS)"
	$(_E) "Local installation directory: $(INSTALLDIR)"
	$(_E) "Repository revision:          r$(GRF_REVISION)"
	$(_E) "GRF title:                    $(GRF_TITLE)"
	$(_E) "GRF filenames:                $(GRF_FILENAME)"
	$(_E) "Documentation filenames:      $(DOC_FILENAMES)"
	$(_E) "nfo files:                    $(NFO_FILENAME)"
	$(_E) "pnfo files:                   $(PNFO_FILENAME)"
	$(_E) "dep files:                    $(DEP_FILENAMES)"
	$(_E) "Bundle files:                 $(BUNDLE_FILES)"
	$(_E) "Bundle filenames:             Tar=$(TAR_FILENAME) Zip=$(ZIP_FILENAME) Bz2=$(BZIP_FILENAME)"
	$(_E) "Dirs (base and full):         $(DIR_BASE) / $(DIR_NAME)"
	$(_E) "Path to Unix2Dos:             $(UNIX2DOS)"
	$(_E) "===="
	
$(REV_FILENAME):
	echo "$(GRF_REVISION)" > $(REV_FILENAME)
test_rev:
	$(_E) "[Version check]"
	$(_E) "$(shell [ "`cat $(REV_FILENAME)`" = "$(VERSION_STRING)" ] && echo "No change." || (echo "Change detected." && echo "$(VERSION_STRING)" > $(REV_FILENAME)))"

# Compile GRF
%.$(GRF_SUFFIX) : $(GRF_DEF_DIR)/%.$(NFO_SUFFIX)
	$(_E) "[Generating] $@"
	$(_V)$(GRFCODEC) $(GRFCODEC_FLAGS) $@ $(GRF_DEF_DIR)
	$(_E)

# NFORENUM process copy of the NFO
.SECONDARY: %.$(NFO_SUFFIX)
.PRECIOUS: %.$(NFO_SUFFIX)
%.$(NFO_SUFFIX) : %.$(PNFO_SUFFIX)
	$(_E) "[Checking] $@"
	$(_V) $(CC) -D VERSION="\"$(VERSION_STRING)\"" $(CC_FLAGS) $< > $@
	$(_E) "[nforenum] $@"
	$(_V)-$(NFORENUM) $(NFORENUM_FLAGS) $@

# Clean the source tree
clean:
	$(_E) "[Cleaning]"
	$(_V)-rm -rf *.orig *.pre *.bak *.grf *.new *~ $(GRF_FILENAME)* $(DEP_FILENAMES)  $(GRF_DEF_DIR)/*.bak $(GRF_DEF_DIR)/*.nfo $(DOC_FILENAMES) $(MAKEFILEDEP) $(REV_FILENAME)

mrproper: clean
	$(_V)-rm -rf $(DIR_BASE)* $(GRF_DEF_DIR)/$(GRF_FILENAME) $(DIR_NAME_SRC)

$(DIR_NAME) : all $(DOC_FILENAMES)
	$(_E) "[BUNDLE]"
	$(_E) "[Generating:] $@/."
	$(_V)if [ -e $@ ]; then rm -rf $@; fi
	$(_V)mkdir $@
	$(_V)-for i in $(BUNDLE_FILES); do cp $$i $@; done
	$(_V) if [ `type -p $(UNIX2DOS)` ]; then $(UNIX2DOS) $(addprefix $@/,$(notdir $(DOC_FILENAMES))) &> /dev/null && echo " - Converting to DOS line endings"; else echo " - Cannot convert to DOS line endings!"; fi

bundle: $(DIR_NAME)

%.$(TXT_SUFFIX): %.$(PTXT_SUFFIX)
	$(_E) "[Generating] $@"
	$(_V) cat $< \
		| sed -e "s/$(GRF_TITLE_DUMMY)/$(GRF_TITLE)/" \
		| sed -e "s/$(REVISION_DUMMY)/$(GRF_REVISION)/" \
		> $@

%.$(TAR_SUFFIX): $(DIR_NAME)
# Create the release bundle with all files in one tar
	$(_E) "[Generating:] $@"
	$(_V)$(TAR) $(TAR_FLAGS) $@ $(basename $@)
	$(_E)

bundle_tar: $(TAR_FILENAME)
bundle_zip: $(ZIP_FILENAME)
$(ZIP_FILENAME): $(DIR_NAME)
	$(_E) "[Generating:] $@"
	$(_V)$(ZIP) $(ZIP_FLAGS) $@ $^
bundle_bzip: $(BZIP_FILENAME)
$(BZIP_FILENAME): $(TAR_FILENAME)
	$(_E) "[Generating:] $@"
	$(_V)$(BZIP) $(BZIP_FLAGS) $^

# Installation process
install: $(TAR_FILENAME) $(INSTALLDIR)
	$(_E) "[INSTALL] to $(INSTALLDIR)"
	$(_V)-cp $(TAR_FILENAME) $(INSTALLDIR)
	$(_E)

bundle_src:
	$(_V) rm -rf $(DIR_NAME_SRC)
	$(_V) mkdir -p $(DIR_NAME_SRC)
	$(_V) cp -R $(GRF_DEF_DIR) $(DOCDIR) Makefile Makefile.config $(DIR_NAME_SRC)
	$(_V) cp Makefile.local.sample $(DIR_NAME_SRC)/Makefile.local
	$(_V) echo 'GRF_REVISION = $(GRF_REVISION)' >> $(DIR_NAME_SRC)/Makefile.local
	$(_V) echo 'GRF_MODIFIED = $(GRF_MODIFIED)' >> $(DIR_NAME_SRC)/Makefile.local
	$(_V) echo 'REPO_TAGS    = $(REPO_TAGS)'    >> $(DIR_NAME_SRC)/Makefile.local
	$(_V) $(MAKE) -C $(DIR_NAME_SRC) mrproper
	$(_V) $(TAR) --gzip -cf $(DIR_NAME_SRC).tar.gz $(DIR_NAME_SRC)
	$(_V) rm -rf $(DIR_NAME_SRC)

$(INSTALLDIR):
	$(_E) "Install dir didn't exist. Creating $@"
	$(_V) mkdir -p $(INSTALLDIR)
	
remake: clean all
