#JavaScript Haskell Optimiser

##To Install

Navigate to `src` directory:

```
make
```

##To Run

From directory containing `jshop.exe`:

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