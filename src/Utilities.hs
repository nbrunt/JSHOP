{-
******************************************************************************
*                                      JSHOP                                 *
*                                                                            *
*   Module:   Utilities                                                      *
*   Purpose:  A set of helper functions used by Main and TestSuite           *
*   Author:   Nick Brunt                                                     *
*                                                                            *
*                    Copyright (c) Nick Brunt, 2011 - 2012                   *
*              Subject to MIT License as stated in root directory            *
*                                                                            *
******************************************************************************
-}

-- | A set of helper functions used by Main and TestSuite

module Utilities where

-- Standard library imports
import Control.Monad.Identity
import Control.Monad.Error
import Control.Monad.State
import System.CPUTime
import Text.Printf
import Data.List

-- JSHOP module imports
import Token
import Lexer
import LexerMonad
import ParseTree
import ParseMonad hiding (nl) -- Causes ambiguity with nl function (PP)
import Parser
import Diagnostics
import CodeCompMonad
import CodeCompressor


-- | Parses a string of JavaScript, returning either an error string or a Parse Tree
--   and the lexer state
parseJS :: String -> Either String (Tree, LexerState)
parseJS str
    = runIdentity $ runErrorT $ runStateT parse (startState str)


-- | Generates compresses JavaScript from a Parse Tree
genJS :: Tree -> String
genJS tree = result
    where
      (mbCode, msgs) = runD (genCode tree)
      result = case mbCode of
          Nothing -> "No code generated"
          Just code -> cleanup $ concat code


-- | Saves a given string to a given filename
saveFile :: String -> String -> IO()
saveFile file output = do
    writeFile file output


-- | Generates an output name with "min" before the extension for a given filename
genOutName :: String -> String
genOutName filepath = path ++ "min." ++ ext
    where
        filename = reverse $ takeWhile (/='/') $ reverse filepath -- file.js
        path = reverse $ dropWhile (/='.') (reverse filepath)     -- path/file.
        ext = reverse $ takeWhile (/='.') (reverse filename)      -- js


-- | Shows the ratio of input to output
showRatio :: [a] -> [a] -> String
showRatio inp out = "Reduced by " ++ show reduced ++ " chars,     \t"
    ++ take 5 (show percent) ++ "% of original."
    where
        reduced = (length inp) - (length out)
        percent = intToFloat (length out) / intToFloat (length inp) * 100


-- | Calulates the ratio of input to output
calcRatio :: [a] -> [a] -> Float
calcRatio inp out = percent
    where
        reduced = (length inp) - (length out)
        percent = intToFloat (length out) / intToFloat (length inp) * 100


intToFloat :: Int -> Float
intToFloat n = fromInteger (toInteger n)


mean :: (Real a, Fractional b) => [a] -> b
mean xs = realToFrac (sum xs) / (fromIntegral $ length xs)


-- | Calculates the total execution time based on the given start time
execTime :: Integer -> IO()
execTime startTime = do
    endTime <- getCPUTime
    let execTime = calcTime startTime endTime
    printf "\nTotal execution time: %0.3f secs" execTime


calcTime :: Integer -> Integer -> Double
calcTime start end = (fromIntegral (end - start)) / (10^12)



-- | Final clean to remove things which cannot easily be removed when in Parse Tree format.
--
-- What about if we're in a regex? :S
cleanup :: String -> String
cleanup []               = []
-- Semi-colons
cleanup (';':'}':xs)     = '}':(cleanup xs)
-- Post fix and unary spaces
cleanup ('+':' ':'+':xs) = '+':' ':'+':(cleanup xs)
cleanup ('+':' ':x:xs)   = '+':x:(cleanup xs)
cleanup ('-':' ':'-':xs) = '-':' ':'-':(cleanup xs)
cleanup ('-':' ':x:xs)   = '-':x:(cleanup xs)
-- New Object and Array declarations
cleanup str
    | Just xs <- stripPrefix "new Object()" str = '{':'}':(cleanup xs)
    | Just xs <- stripPrefix "new Object;" str  = '{':'}':';':(cleanup xs)
    | Just xs <- stripPrefix "new Array()" str  = '[':']':(cleanup xs)
    | Just xs <- stripPrefix "new Array;" str   = '[':']':';':(cleanup xs)
-- Return undefined
    | Just xs <- stripPrefix "return undefined;" str = "return;" ++ (cleanup xs)
-- Leave everything else alone
cleanup (x:xs)           = x:(cleanup xs)



-- | Pretty print the ParseTree
--
-- So far this just puts a blank line between each source (function or statement) and does some
-- simple indentations for each branch.  Suffice to say I'm not putting much effort into making
-- the Parse Tree readable as it's not that important.  It just needs to be debuggable for my sake.
ppTree :: Tree -> Bool -> String
ppTree (Tree sources) remBloat
    = if remBloat then
          ppRemBloat tree
       else
          tree
      where
          tree = ppIndent $ concat [show x ++ "\n\n" | x <- sources]

-- | Make newline and indent every time a branch terminates.
ppIndent :: String -> String
ppIndent []           = []
ppIndent (')':' ':xs) = ')':'\n':'\t':(ppIndent xs)
ppIndent (')':',':xs) = ')':',':'\n':'\t':(ppIndent xs)
ppIndent (']':' ':xs) = ']':'\n':'\t':(ppIndent xs)
ppIndent (x:xs)       = x:(ppIndent xs)

-- | HIGHLY EXPERIMENTAL.  This is designed to remove a lot of the bloat in the Parse Tree by
-- taking out all the logOr, relExpr, ShiftExpr type stuff.  NOTE, sometimes this stuff is
-- necessary to understand the structure, so it's best to leave it in.  However, for browsing,
-- it can be easier to remove it.
ppRemBloat :: String -> String
ppRemBloat [] = []
ppRemBloat str
    | Just xs <- stripPrefix "CondExpr" str  = ppRemBloat $ shrink xs
    | Just xs <- stripPrefix "ShiftExpr" str = ppRemBloat $ shrink xs
    | Just xs <- stripPrefix "AddExpr" str   = ppRemBloat $ shrink xs
ppRemBloat (x:xs) = x:(ppRemBloat xs)

shrink :: String -> String
shrink xs = "..." ++ '(':(leaf branch) ++ ')':(dropWhile (/= ')') xs)
    where
        branch = takeWhile (/= ')') xs
        leaf = reverse . takeWhile (/= '(') . reverse

-- | EXPERIMENTAL.  Rudimentaty JS pretty printer.
ppOutput :: String -> ShowS
ppOutput str = ppOutput' str 0
    where
        ppOutput' :: String -> Int -> ShowS
        -- End of file
        ppOutput' [] _        = showString ""
        -- End of statement, begin new line
        ppOutput' (';':xs) n  = showChar ';' . nl . indent n . ppOutput' xs n
        -- Begining of block statement, indent + 1
        ppOutput' ('{':xs) n  = showChar '{' . nl . indent (n+1) . ppOutput' xs (n+1)
        -- End of block statement, indent - 1
        ppOutput' ('}':xs) n  = nl . indent (n-1) . showChar '}'
                              . nl . indent (n-1) . ppOutput' xs (n-1)
        -- Any other char, continue
        ppOutput' (x:xs) n    = showChar x . ppOutput' xs n


-- Pretty printing utils
indent :: Int -> ShowS
indent n = showString (take (2 * n) (repeat ' '))

nl :: ShowS
nl  = showChar '\n'

spc :: ShowS
spc = showChar ' '

ppSeq :: Int -> (Int -> a -> ShowS) -> [a] -> ShowS
ppSeq _ _  []     = id
ppSeq n pp (x:xs) = pp n x . ppSeq n pp xs


-- | Given a JavaScript string, writes a list of tokens (1 per line)
--
-- Non monad version of the lexer
nonMLexer :: String -> IO()
nonMLexer str = do
    let ts = tokens str
    putStrLn $ concat [show t ++ "\n"| t <- ts]

nonMLexFile :: String -> IO()
nonMLexFile file = do
    input <- readFile file
    nonMLexer input


-- | Converts a JavaScript string into a list of tokens
tokens :: String -> [Token]
tokens [] = []
tokens str' =
    case str' of
      ('\n':xs)    -> tokens xs
      ('/':'*':xs) -> nonMScanComment xs
      _ -> ts
    where
        lexResult = lexer str'
        ts = case lexResult of
            Left (t, rest) -> (t:tokens rest)
            Right rest     -> tokens rest


-- | Scans multi-line comments
nonMScanComment :: String -> [Token]
nonMScanComment str = do
    case str of
        ('\n':xs) -> nonMScanComment xs
        ('*':'/':xs) -> (Other "COMMENT":tokens xs)
        (_:xs) -> nonMScanComment xs