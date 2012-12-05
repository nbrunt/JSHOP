#JavaScript Haskell Optimiser

Copyright &copy; 2012 [Nick Brunt](http://nickbrunt.com)

JSHOP is a parser and compressor for JavaScript.  I built this project in my last year at the University of Nottingham while reading for a B.Sc. in Computer Science.  The dissertation is included.

Here is a table to compare its results to other popular JavaScript minifiers and compressors when given the jQuery library:
<table>
  <tr>
    <th>Name of compressor</th>
    <th>URL</th>
    <th>Final size of compressed jQuery library</th>
    <th>Percentage of original</th>
  </tr>
  <tr>
    <td>Yahoo! User Interface (YUI) compressor</td>
    <td>http://developer.yahoo.com/yui/compressor/</td>
    <td>104,684</td>
    <td>42.17</td>
  </tr>
  <tr>
    <td>/packer/</td>
    <td>http://dean.edwards.name/packer/</td>
    <td>114,030</td>
    <td>45.94</td>
  </tr>
  <tr>
    <td>JSMin</td>
    <td>http://www.crockford.com/javascript/jsmin.html</td>
    <td>139,092</td>
    <td>56.03</td>
  </tr>
  <tr>
    <td><b>JavaScript Haskell Optimiser (JSHOP)<b></td>
    <td>https://github.com/nbrunt/jshop</td>
    <td><b>101,236</b></td>
    <td><b>40.78</b></td>
  </tr>
</table>

####Compression techniques include:

1. Removing the following tokens from the source code
  - Single-line comments
  - Multi-line comments
  - Unnecessary whitespace
  - Semi-colons before closing braces
2. Shortening identifiers where possible (identifiers being variable and function names)
3. Converting the following expressions to their shorthand equivalents
  - Ternary conditionals (where possible)
  - Array declarations
  - Object declarations
4. Performing partial evaluation on expressions and statements where possible


##Installing

**Note:** The executable is included so if you do not want to modify JSHOP, skip to the [Running](#running) section.

This guide is aimed at a Linux user, but I have successfully run this through [cygwin](http://cygwin.com) on Windows and I am sure it could be run natively on Windows too but have never tried it.

####Prerequisits
  
1. [Haskell Platform](http://www.haskell.org/platform/) `sudo apt-get install haskell-platform`
2. [GNU Make](http://www.gnu.org/software/make/) `sudo apt-get install make`
3. [Alex Lexer Generator](http://www.haskell.org/alex/) `cabal install alex`
4. [Happy Parser Generator](http://www.haskell.org/happy/) `cabal install happy`
5. [Haddock Documentation Generator](http://www.haskell.org/haddock/) `cabal install haddock` (optional)
6. [HsColour Syntax Highlighter](http://www.cs.york.ac.uk/fp/darcs/hscolour/) `sudo apt-get install hscolour` (optional - for nicer documentation)

  **Note:** You may have to add the cabal bin folder to your path. Try typing `alex -v` and if it can't be found, add this to `~/.profile`:
  
  ```bash
  # set PATH so it includes cabal binaries
  if [ -d "$HOME/.cabal/bin" ] ; then
    PATH="$PATH:$HOME/.cabal/bin"
  fi
  ```
  Then run `source ~/.profile` in your terminal.

####Compiling

Navigate to `src` directory.

1. To compile the project and generate the executable, run `make`
2. To remove compiled classes and objects, run `make clean`
3. To generate documentation, run `make doc`
4. To remove documentation, run `make clean-doc`
5. To clean up the whole project and remove all unnecessary files (including the executable and documentation), run `make really-clean`

<a id="running"></a>
##Running

Example input and output

1. Navigate to the directory containing `jshop.exe`
2. Type the following command where `file.js` is the path to a file with JavaScript in it:

  ```
  ./jshop.exe file.js
  ```

3. The following results will be given:

  ```
  $ ./jshop.exe file.js
  OUTPUT:
  [Compressed JavaScript will go here]
  STATS:
  Reduced by xx chars,
  xx% of original.
  Total execution time: xx secs
  ```

4. To find more information about how to use the program, type the following command:

  ```bash
  ./jshop.exe --help
  ```

The following information will be shown:

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