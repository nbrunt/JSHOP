{-

  TODO
  ----

  - what about line endings? /r/n?
  - Really got to switch to PCRE...
  

-}
module JSHOP where -- JavaScript Haskell OPtimiser

import Char
import Text.Regex.Posix
import Text.Regex.Base.RegexLike
import System

type Code                 = [Char]
type Regexp               = [Char]
type Matches              = [(Int,Int)]

-- Regular Expressions
sComments = "//[^\n]*"                                     -- Single line comments            e.g. // comment
mComments = "/\\*[^*]*\\*+([^/][^*]*\\*+)*/"               -- Multi line comments             e.g. /* comment */
cComments = "/\\*@[^*]*\\*+([^/][^*]*(@\\*)+)*/"           -- Conditional comments            e.g. /*@ comment @*/
sString   = "\'(\\.|[^\'\\])*\'"                           -- Single quote strings            e.g. 'a string'
dString   = "\"(\\.|[^\"\\])*\""                           -- Double quote strings            e.g. "a string"
jsRegex   = "[^*/]/(\\[/\\]|[^*/])(\\.|[^/\n\\])*/[gim]*"  -- Regular expression              e.g. /pattern/modifiers
space     = "[ \t\r\n\v\f]+"                               -- Whitespace                      e.g. spaces, tabs, newlines etc.
plusplus  = "([+-])"++space++"([+-])"                      -- Incrementors or decrementors    e.g. a++ +b
word      = "[A-Za-z0-9_]"
nonWord   = "[^A-Za-z0-9_]"
wBoundary = "[(?<="++nonWord++")(?="++word++")|(?<="++word++")(?="++nonWord++")]"
something = wBoundary++space++"\\$"++space++wBoundary


-- Returns a list of the offset and length of each match to pat in cs
getMatches                :: Regexp -> Code -> Matches
getMatches pat cs         = getAllMatches (match regex cs) :: [(MatchOffset,MatchLength)]
                              where
                                -- Allow multiline matching
                                regex = makeRegexOpts (defaultCompOpt - compNewline) defaultExecOpt pat

                                
noConflict                :: Matches -> (Int,Int) -> Bool
noConflict [] _           = True
noConflict ((ro,rl):rs) (o,l)
                          = not (o >= ro && o < (ro + rl)) && noConflict rs (o,l)
                                
                                
-- Recursively replace each match.  Note that this is done in reverse to prevent the offsets getting out of line
-- when each match is removed.  This could be compensated for using the length of the match just removed, but
-- reversing the list is the simplest solution.
remMatches                :: Code -> Matches -> Code
remMatches cs []          = cs
remMatches [] _           = []
remMatches cs ms          = remMatches (take offset cs) (reverse (tail rms)) ++ drop (offset + length) cs
                              where
                                rms              = reverse ms
                                (offset, length) = head rms


remove                    :: Regexp -> (Code -> Matches) -> Code -> Code
remove pat fExcep cs      = remMatches cs validMatches
                              where
                                validMatches = filter (noConflict exceptions) matches
                                matches      = getMatches pat cs
                                exceptions   = fExcep cs
                                               
                                               
comExceptions             :: Code -> Matches
comExceptions cs          = getMatches dString cs ++
                            getMatches sString cs ++
                            getMatches cComments cs ++
                            getMatches jsRegex cs
                            
                            
spaceExceptions           :: Code -> Matches
spaceExceptions cs        = getMatches dString cs ++
                            getMatches sString cs ++
                            getMatches cComments cs ++
                            getMatches jsRegex cs ++
                            getMatches plusplus cs {-++
                            getMatches something cs-}
                              
                              
-- Remove comments.  Note that multi line comments must be removed first otherwise the closing */
-- would get removed accidentally in a situation like this: /* comment // comment */
remComments               :: Code -> Code
remComments               = remove sComments comExceptions .
                            remove mComments comExceptions
                            
                            
remWhitespace             :: Code -> Code
remWhitespace             = remove space spaceExceptions


compress                  :: Code -> Code
compress                  = remWhitespace . remComments


compFile                  :: String -> IO()
compFile file             = do
                              input <- readFile file
                              let output = compress input
                              putStrLn ("\n" ++ msg ++ "\n" ++ underline ++ "\n")
                              putStrLn output
                              putStrLn ("\n" ++ underline ++ "\n")
                              putStrLn ("Info\n----\n")
                              putStrLn ("Input size:  " ++ show (length input) ++ " bytes")
                              putStrLn ("Output size: " ++ show (length output) ++ " bytes")
                              putStrLn ("Compressed by: " ++ show (length input - length output) ++ " bytes")
                                where
                                  msg       = ("Compressed " ++ file ++ " follows")
                                  underline = (replicate (length msg) '-')


main                      :: IO()
main                      = do
                              args <- getArgs
                              case args of
                                [] -> do
                                  -- No specified file or code, ask for user input
                                  putStr "Please enter a filename: "
                                  inFile <- getLine
                                  compFile inFile
                                (inFile:_) -> do
                                  -- Return file with original filename plus ".min" e.g. test.min.js
                                  input <- readFile inFile
                                  let outFile = takeWhile (/='.') inFile ++ ".min" ++ dropWhile (/='.') inFile
                                  writeFile outFile (compress input)
                                  
                                  
                                  
-- Some testing functions

findPat                   :: [Char] -> Code -> IO()
findPat pattern code      = do
                              putStrLn ("\nMatches:\n--------\n\nOffset, Length: Code extract\n")
                              putStrLn (concat [show offset ++ ", "
                                                ++ show length ++ ": "
                                                ++ take length (drop offset code)
                                                ++ "\n" | (offset,length) <- matches])
                              where
                                matches = getMatches pattern code
                                
                                
findPatFile               :: String -> String -> IO()
findPatFile file pattern  = do
                              input <- readFile file
                              findPat pattern input