# Makefile for OpenGFX Extra SpinOff-NewGRF

MAKEFILE_CONFIG := Makefile.config
MAKEFILE=Makefile

# Name of the Makefile which contains the local settings. It overrides
# the global settings in Makefile.config.
MAKEFILELOCAL := Makefile.local
MAKEFILE_DEF=scripts/Makefile.def
MAKEFILE_BUNDLES=scripts/Makefile.bundles
MAKEFILE_COMMON=scripts/Makefile.common
MAKEFILE_IN=scripts/Makefile.in
MAKEFILE_DEP=Makefile.dep


# Include the project's configuration file
include ${MAKEFILE_CONFIG}
export
# this overrides definitions from above:
#-include ${MAKEFILELOCAL}

# include the universal Makefile definitions for NewGRF Projects
include ${MAKEFILE_DEF}

# Check dependencies for building all:
all: depend
	$(_V) $(MAKE) $(MAKE_FLAGS) -f $(MAKEFILE) $(MAIN_TARGET)
# 	$(_V) $(MAKE) $(MAKE_FLAGS) -f $(MAKEFILE) $(MAIN_TARGET)
# $(MAIN_TARGET): depend

-include ${MAKEFILE_DEP}

-include ${MAKEFILE_IN}

include ${MAKEFILE_COMMON}
include ${MAKEFILE_BUNDLES}

