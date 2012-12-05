##JavaScript Haskell Optimiser

###Installing

**NOTE:** The executable is included so you only need to install everything if you intend on modifying it.  If you do not want to modify JSHOP, skip to the "Running" section.

####Prerequisits:

1. [Haskell Platform](http://www.haskell.org/platform/)
2. [GNU Make](http://www.gnu.org/software/make/) `sudo apt-get install make`
3. [Alex Lexer Generator](http://www.haskell.org/alex/) `cabal install alex`
4. [Happy Parser Generator](http://www.haskell.org/happy/) `cabal install happy`
5. [Haddock Documentation Generator](http://www.haskell.org/haddock/) `cabal install haddock`
6. [HsColour Syntax Highlighter](http://www.cs.york.ac.uk/fp/darcs/hscolour/) `sudo apt-get install hscolour` (optional - for nicer documentation)

**NOTE:**

You may have to add the cabal bin folder to your path. Try typing `alex -v` and if it can't be found, add this to `~/.profile`:

```bash
# set PATH so it includes cabal binaries
if [ -d "$HOME/.cabal/bin" ] ; then
  PATH="$PATH:$HOME/.cabal/bin"
fi
```

####Navigate to `src` directory:

```
make
```

###Running

####From directory containing `jshop.exe`:

```
USAGE:
    jshop [options] file.js     Compress "file.js"
    jshop [options]             Read input from standard input.
                                (Terminate with Ctrl+D, Enter in UNIX, or Ctrl+Z,
                                 Enter in Windows. Must be on a new line.)

DEFAULT OUTPUT:
   Compressed JS and ratio of input to output.

OPTIONS:
   Output
       --help, --h
           Print help message and stop.

       --version, --ver, --v
           Print JSHOP version and stop.

       --output, --out, --o
           Write output to [file].min.js. Default it output.min.js if no file given.

       --input, --i
           Print input.

       --tokens, --tok
           Print list of tokens.

       --tree
           Print the Parse tree.

       --lstate
           Print the Lexer state.

       --all
           Print input, tokens, Parse tree, Lexer state, output and ratio.

       --rembloat
           Experimental. Removes bloat from the Parse tree. Can make it unreadable.
           Only works with --tree or --all.

       --prettyprint, --pp
           Experimental. Pretty prints the output for ease of reading.

   Testing
       --test --t ["message"]
           Run full test suite and stop. Message is optional. If added, test
           results will be saved to file.

       --showAverages
           Displays the average compression ratios for all past tests.

       --showTest NUM
           Displays a past test of index NUM.

       --showAllTests
           Displays all past tests.

```