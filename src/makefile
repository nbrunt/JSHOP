##############################################################################
#                                                                            #
#   Makefile for JSHOP                                                       #
#   Copyright (c) Nick Brunt, 2011-2012                                      #
#   Subject to MIT License as stated in root directory                       #
#                                                                            #
#   Loosely based on the HMTC makefile                                       #
#   Copyright (c) Henrik Nilsson, 2006                                       #
#   http://www.cs.nott.ac.uk/~nhn/                                           #
#                                                                            #
##############################################################################

# Default operation (when you only call "make")
all: jshop


#-----------------------------------------------------------------------------
# Source files:
#-----------------------------------------------------------------------------

# Alex (lexer) source files
alexFiles = \
    Lexer.x

# Happy (parser) source files
happyFiles = \
    Parser.y

# Haskell source files
haskellFiles = \
    Token.hs \
    Lexer.hs \
    LexerMonad.hs \
    ParseTree.hs \
    ParseMonad.hs \
    Parser.hs \
    Diagnostics.hs \
    CodeCompMonad.hs \
    CompUtils.hs \
    Analyser.hs \
    CodeCompressor.hs \
    Utilities.hs \
    TestSuite.hs \
    Main.hs

# Definition of .hi and .o files for cleaning purposes
hs_interfaces := $(haskellFiles:.hs=.hi)
hs_objects := $(haskellFiles:.hs=.o)


#-----------------------------------------------------------------------------
# Compile lexer:
#-----------------------------------------------------------------------------
# Options:
#   g - optimise for ghc
#   i - generate info file
%.hs: %.x
		#
		# Compiling lexer...
		#
		alex -gi $(alexFiles)


#-----------------------------------------------------------------------------
# Compile parser:
#-----------------------------------------------------------------------------
# Options:
#   g - optimise for ghc
#   i - generate info file
#   a - use array-based shift reduce parser.  Much faster when combined with -g
#   d - prints debug info at runtime
%.hs: %.y
		#
		# Compiling parser...
		#
		happy -agi $(happyFiles)


#-----------------------------------------------------------------------------
# Compile JSHOP:
#-----------------------------------------------------------------------------
# Options:
#   make - compile to exe
#   O2   - optimise (level 2)
#   w    - hide warnings
#   o    - specify output filename
jshop: $(haskellFiles)
		#
		# Compiling JSHOP...
		#
		ghc --make -O2 -w Main -o jshop.exe


#-----------------------------------------------------------------------------
# Generate Documentation:
#-----------------------------------------------------------------------------
# Options:
#   HsColour:
#     css - output in HTML 4.01 with CSS
#     anchor - adds an anchor to every entity for use with Haddock
#
#   haddock:
#     odir          - output directory
#     html          - generate documentation in HTML format
#     source-base   - adds link to source code directory
#     source-module - adds link to each individual module
#     source-entity - adds link to each individual entity
#     title         - title to appear at the top of each page
#     w             - supress warnings
doc: clean-doc $(haskellFiles)
		#
		# Generating syntax highlighted HTML source files...
		#
		for file in $(haskellFiles) ; do \
			HsColour -css -anchor $$file > doc/src/`basename $$file .hs`.html ; \
		done
		#
		# Generating documentation...
		#
		haddock --odir=doc --html --source-base=src/ --source-module=src/%M.html --source-entity=src/%M.html#%N --title="JSHOP" $(haskellFiles) -w

#-----------------------------------------------------------------------------
# Cleaning:
#-----------------------------------------------------------------------------

# Remove all .hi and .o files
clean:
		#
		# Removing Haskell interfaces and objects...
		#
		-$(RM) $(hs_interfaces) $(hs_objects)

# Remove all documentation files (except css)
clean-doc:
		#
		# Cleaning documentation...
		#
		-rm doc/*.*
		-rm doc/src/*.html

# Remove ALL unnecessary files leaving only absolute source
really-clean: clean clean-doc
		#
		# Removing extraneous files...
		#
		-$(RM) Parser.hs
		-$(RM) Lexer.hs
		-$(RM) error.log
		-$(RM) Lexer.info
		-$(RM) Parser.info
		-$(RM) jshop
