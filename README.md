#JavaScript Haskell Optimiser

Copyright &copy; 2012 [Nick Brunt](http://nickbrunt.com)

JSHOP is a parser and [compressor](http://en.wikipedia.org/wiki/Minification_(programming\)) for JavaScript written in the functional programming language [Haskell](http://www.haskell.org/haskellwiki/Haskell).  The project was the subject of my dissertation (included).

Here is a table to compare its results to other popular JavaScript minifiers and compressors when given the jQuery library (v1.7.1 which is 248,235 chars long uncompressed):
<table>
  <thead>
    <tr>
      <th>Name of compressor</th>
      <th>Final size of compressed jQuery library (chars)</th>
      <th>Percentage of original</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><a href="http://www.crockford.com/javascript/jsmin.html">JSMin</a></td>
      <td>139,092</td>
      <td>56.03</td>
    </tr>
    <tr>
      <td><a href="http://dean.edwards.name/packer/">/packer/</a></td>
      <td>114,030</td>
      <td>45.94</td>
    </tr>
    <tr>
      <td><a href="http://developer.yahoo.com/yui/compressor/">Yahoo! User Interface (YUI) compressor</a></td>
      <td>104,684</td>
      <td>42.17</td>
    </tr>
    <tr class="info">
      <td><a href="https://github.com/nbrunt/jshop">JavaScript Haskell Optimiser (JSHOP)</a></td>
      <td>101,236</td>
      <td>40.78</td>
    </tr>
  </tbody>
</table>

####Compression techniques:

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
5. Various other small optimisations


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

Navigate to the `src` directory.

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

  Contents of `file.js`:

  ```javascript
  function complexTest(arg1, arg2) {
    var result = 0,
        accumulator = new Array();

    if (arg1 > 0) {
      result += arg1;
    } else {
      result += arg2;
    }

    alert('Nick\'s ' + "result = " + 5/2 * result);
    return accumulator.push(result);

    // How many optimisations can you spot?
  }
  ```

3. The following results will be given:

  ```javascript
  $ ./jshop.exe file.js
  OUTPUT:
  function complexTest(a,b){var c=0,d=[];c+=a>0?a:b;alert("Nick's result = "+2.5*c);return d.push(c)}

  STATS:
  Reduced by 190 chars,       34.25% of original.
  Total execution time: 0.004 secs
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
