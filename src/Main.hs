{-
******************************************************************************
*                                      JSHOP                                 *
*                                                                            *
*   Module:   Main                                                           *
*   Purpose:  Main JSHOP module                                              *
*   Author:   Nick Brunt                                                     *
*                                                                            *
*                   Based (loosely) on the HMTC equivalent                   *
*                 Copyright (c) Henrik Nilsson, 2006 - 2011                  *
*                      http://www.cs.nott.ac.uk/~nhn/                        *
*                                                                            *
*                    Copyright (c) Nick Brunt, 2011 - 2012                   *
*              Subject to MIT License as stated in root directory            *
*                                                                            *
******************************************************************************
-}

module Main where

-- Standard library imports
import System.Environment
import System.CPUTime
import System.IO
import Data.Maybe

-- JSHOP module imports
import Token
import Lexer
import LexerMonad
import ParseTree
import ParseMonad
import Parser
import Diagnostics
import CodeCompMonad
import CodeCompressor
import Utilities

import TestSuite

data Options =
    Options {
        optHelp   :: Bool,
        optVer    :: Bool,
        optOut    :: Bool,
        optInput  :: Bool,
        optTokens :: Bool,
        optTree   :: Bool,
        optLState :: Bool,
        optAll    :: Bool,
        optBloat  :: Bool,
        optPP     :: Bool,
        optTest   :: Bool,
        optST     :: Bool,
        optSAT    :: Bool,
        optSA     :: Bool
    }
    deriving Show


defaultOptions :: Options
defaultOptions =
    Options {
        optHelp   = False,
        optVer    = False,
        optOut    = False,
        optInput  = False,
        optTokens = False,
        optTree   = False,
        optLState = False,
        optAll    = False,
        optBloat  = False,
        optPP     = False,
        optTest   = False,
        optST     = False,
        optSAT    = False,
        optSA     = False
    }


version :: String
version = "1.0"

prompt :: String
prompt = "Please enter some JavaScript here (Terminate with Ctrl+D in UNIX, or Ctrl+Z in Windows, followed by Return. Must be on a new line.):"


------------------------------------------------------------------------
-- Main
------------------------------------------------------------------------


main :: IO()
main = do
    hSetEncoding stdout utf8
    hSetEncoding stdin utf8
    hSetEncoding stderr utf8
    startTime <- getCPUTime
    (opts, mbArgs) <- parseCmdLine
    if optHelp opts then
        printHelp
     else if optVer opts then
        printVersion
     else if optTest opts then
        runTests mbArgs
     else if optST opts then
        showResult $ read $ head $ fromJust mbArgs
     else if optSAT opts then
        showPastResults
     else if optSA opts then
        showAverages
     else do
        -- Get input (from file if given)
        input <-
            case mbArgs of
                Nothing     -> putStrLn prompt >> getContents
                Just [file] -> readFile file
                Just (f:fs) -> readFile f -- Potential support for multiple files
        output <- execute opts input
        execTime startTime

        -- Output to file
        if optOut opts then do
            let outFile = case mbArgs of
                    Nothing     -> "output.min.js"
                    Just (f:fs) -> genOutName f
            saveFile outFile output
            putStrLn $ "\n\nSaved to " ++ outFile
         else
            putChar '\n'


------------------------------------------------------------------------
-- Compressor
------------------------------------------------------------------------

execute :: Options -> String -> IO String
execute opts input = do
    -- Parse
    let parseOutput = parseJS input
    case parseOutput of
        Left error -> do
            putStrLn $ show error
            return ""
        Right (tree, state) -> do
            -- Display input
            if optInput opts || optAll opts then do
                putStrLn "\n\nINPUT:"
                putStrLn input
             else
                putStr "" -- Do nothing

            -- Display tokens
            if optTokens opts || optAll opts then do
                putStrLn "\n\nTOKENS:"
                nonMLexer input
             else
                putStr "" -- Do nothing

            -- Display Parse Tree
            if optTree opts || optAll opts then do
                putStrLn "\n\nPARSE TREE:"
                putStrLn $ ppTree tree (optBloat opts)
                return()
             else
                putStr "" -- Do nothing

            -- Display Lexer State
            if optLState opts || optAll opts then do
                putStrLn "\n\nSTATE:"
                putStrLn $ show state
             else
                putStr "" -- Do nothing

            -- Display output
            putStrLn "\n\nOUTPUT:"
            let output = genJS tree
            if optPP opts
                then putStrLn $ ppOutput output ""
                else putStrLn output

            -- Display stats
            putStrLn "\n\nSTATS:"
            putStrLn $ showRatio input output

            return output

------------------------------------------------------------------------
-- Parse command line arguments
------------------------------------------------------------------------

parseCmdLine :: IO (Options, Maybe [String])
parseCmdLine = do
    args <- getArgs
    (opts, mbFiles) <- processOptions defaultOptions args
    return (opts, mbFiles)


processOptions :: Options -> [String] -> IO (Options, Maybe [String])
processOptions opts args = do
    (opts', mbArgs) <- posAux opts args
    return (opts', mbArgs)
    where
        posAux :: Options -> [String] -> IO (Options, Maybe [String])
        -- No arguments left
        posAux opts [] = return (opts, Nothing)
        posAux opts arguments@(arg:args)
            -- No options, just other args
            | take 2 arg /= "--" = return (opts, Just arguments)
            -- Options
            | otherwise = do
                -- Process option (dropping the --)
                opts' <- poAux opts (drop 2 arg)
                -- Move on to next option
                posAux opts' args

        poAux :: Options -> String -> IO Options
        poAux opts o
            | o == "help" || o == "h" =
                return (opts {optHelp = True})
            | o == "version" || o == "ver" || o == "v" =
		            return (opts {optVer = True})
            | o == "output" || o == "out" || o == "o" =
                return (opts {optOut = True})
            | o == "input" || o == "i" =
                return (opts {optInput = True})
            | o == "tokens" || o == "tok" =
                return (opts {optTokens = True})
            | o == "tree" =
                return (opts {optTree = True})
            | o == "lstate" =
                return (opts {optLState = True})
            | o == "all" =
                return (opts {optAll = True})
            | o == "rembloat" =
                return (opts {optBloat = True})
            | o == "prettyprint" || o == "pp" =
                return (opts {optPP = True})
            | o == "test" || o == "t" =
                return (opts {optTest = True})
            | o == "showTest" =
                return (opts {optST = True})
            | o == "showAllTests" =
                return (opts {optSAT = True})
            | o == "showAverages" =
                return (opts {optSA = True})
            | otherwise = do
                putStrLn ("Unknown option \"--" ++ o ++ "\"")
                return opts


------------------------------------------------------------------------
-- Miscellaneous output
------------------------------------------------------------------------

printHelp :: IO()
printHelp = putStr
    "USAGE:\n\
    \    jshop [options] file.js     Compress \"file.js\"\n\
    \    jshop [options]             Read input from standard input.\n\
    \                                (Terminate with Ctrl+D, Enter in UNIX, or Ctrl+Z,\n\
    \                                 Enter in Windows. Must be on a new line.)\n\
    \\n\
    \DEFAULT OUTPUT:\n\
    \   Compressed JS and ratio of input to output.\n\
    \\n\
    \OPTIONS:\n\
    \   Output\n\
    \       --help, --h\n\
    \           Print help message and stop.\n\n\
    \       --version, --ver, --v\n\
    \           Print JSHOP version and stop.\n\n\
    \       --output, --out, --o\n\
    \           Write output to [file].min.js. Default it output.min.js if no file given.\n\n\
    \       --input, --i\n\
    \           Print input.\n\n\
    \       --tokens, --tok\n\
    \           Print list of tokens.\n\n\
    \       --tree\n\
    \           Print the Parse tree.\n\n\
    \       --lstate\n\
    \           Print the Lexer state.\n\n\
    \       --all\n\
    \           Print input, tokens, Parse tree, Lexer state, output and ratio.\n\n\
    \       --rembloat\n\
    \           Experimental. Removes bloat from the Parse tree. Can make it unreadable.\n\
    \           Only works with --tree or --all.\n\n\
    \       --prettyprint, --pp\n\
    \           Experimental. Pretty prints the output for ease of reading.\n\n\
    \   Testing\n\
    \       --test --t [\"message\"]\n\
    \           Run full test suite and stop. Message is optional. If added, test\n\
    \           results will be saved to file.\n\n\
    \       --showAverages\n\
    \           Displays the average compression ratios for all past tests.\n\n\
    \       --showTest NUM\n\
    \           Displays a past test of index NUM.\n\n\
    \       --showAllTests\n\
    \           Displays all past tests.\n\n\
    \"


printVersion :: IO()
printVersion = do
    putStrLn "\nJavaScript Haskell Optimiser (JSHOP)"
    putStrLn $ "Version " ++ version