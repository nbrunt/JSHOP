##############################################################################
#
# 	Makefile for JSHOP
#   Copyright (c) Nick Brunt, 2011-2012
#
#   Based on the HMTC makefile
#	  Copyright (c) Henrik Nilsson, 2006
#   http://www.cs.nott.ac.uk/~nhn/
#
##############################################################################

# Initial "all" target:
# This goes first to make it the default target.

.PHONY: all doc clean really-clean

all: jshop


#-----------------------------------------------------------------------------
# Source files: 
#-----------------------------------------------------------------------------

# Haskell sources.
hs_sources = \
    AST.hs \
    Diagnostics.hs \
    Main.hs \
    Name.hs \
    ParseMonad.hs \
    Parser.hs \
    PPAST.hs \
    PPUtilities.hs \
    Scanner.hs \
#    Lexer.hs \
    SrcPos.hs \
    Token.hs


#-----------------------------------------------------------------------------
# Tools, arguments, and auxiliary files
#-----------------------------------------------------------------------------

SHELL = /bin/sh

HS_OPTS += -O $(HS_PACKAGES) $(HS_EXTRA_IMPORTS) $(HS_USER_OPTS)
MAKE.hs  = ghc --make $(HS_OPTS) -o $@

# ghc-specific (for now)
HAPPY = happy -agc


#-----------------------------------------------------------------------------
# Auxiliary variables
#-----------------------------------------------------------------------------

hs_interfaces := $(hs_sources:.hs=.hi)
hs_objects := $(hs_sources:.hs=.o)

#-----------------------------------------------------------------------------
# Implicit rules for Haskell
#-----------------------------------------------------------------------------

# Happy: Run CPP on the output from Happy to make Haddock happy! :-)
%.hs:   %.y
	$(HAPPY) --outfile=happy-output.hs $<
	ghc -cpp -E -optP-P -o $@ happy-output.hs
	rm happy-output.hs


#-----------------------------------------------------------------------------
# Compilation of the JavaScript Haskell Optimiser
#-----------------------------------------------------------------------------

jshop: $(hs_sources)
	$(MAKE.hs) Main


#-----------------------------------------------------------------------------
# Generating documentation
#-----------------------------------------------------------------------------

doc: Doc $(hs_sources)
	haddock --html --odir=Doc $(hs_sources) --title=JSHOP

Doc:
	mkdir Doc


#-----------------------------------------------------------------------------
# Cleaning
#-----------------------------------------------------------------------------

clean:
	-$(RM) $(hs_interfaces) $(hs_objects) jshop

really-clean: clean
	-$(RM) Parser.hs
	-rm -rf Doc
