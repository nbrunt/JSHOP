{-
******************************************************************************
*                                      JSHOP                                 *
*                                                                            *
*   Module:   TestSuite                                                      *
*   Purpose:  A set of tests to run on a selection of inputs                 *
*   Author:   Nick Brunt                                                     *
*                                                                            *
*                    Copyright (c) Nick Brunt, 2011 - 2012                   *
*              Subject to MIT License as stated in root directory            *
*                                                                            *
******************************************************************************
-}

module TestSuite where

-- Standard library imports
import System.Directory
import System.CPUTime
import Data.Maybe
import Control.Monad

-- JSHOP module imports
import Utilities


-- Test result data structures
data TestResults =
    TestResults {
        testNum     :: Int,
        message     :: String,
        strucTests  :: [Test],
        libTests    :: [Test],
        time        :: Double,
        average     :: Float
    }
    deriving (Read, Show)

data Test =
    Test {
        name        :: String,
        result      :: Bool, -- True = pass, False = fail
        errorMsg    :: String,
        inputSize   :: Int,
        outputSize  :: Int,
        reduction   :: Int,
        percentage  :: Float
    }
    deriving (Read, Show)


defaultTest :: Test
defaultTest =
    Test {
        name        = "",
        result      = False,
        errorMsg    = "",
        inputSize   = 0,
        outputSize  = 0,
        reduction   = 0,
        percentage  = 0
    }

testResultsFile :: String
testResultsFile = "tests/testResults.log"


-- Structure tests
funcFile :: String
funcFile = "tests/structure/functions.js"

exprFile :: String
exprFile = "tests/structure/expressions.js"

statFile :: String
statFile = "tests/structure/statements.js"



runTests :: Maybe [String] -> IO()
runTests mbArgs = do
    startTime <- getCPUTime
    putStrLn "Starting test suite"
    putStrLn "-------------------\n"

    let msg = head $ fromMaybe ["No message"] mbArgs

    -- Structure tests run every possible JavaScript control structure
    -- through the program to test that they can be fully parsed.
    funcTest <- runParseTest (defaultTest {name="Functions"}) funcFile
    exprTest <- runParseTest (defaultTest {name="Expressions"}) exprFile
    statTest <- runParseTest (defaultTest {name="Statements"}) statFile

    -- Library tests run a set of JavaScript libraries through the program
    -- to test real world code and also to check compression ratios.

    -- Get list of files in libraries directory
    files <- getDirectoryContents "tests/libraries"
    -- Filter out ".." and "." and add path
    let names = filter (\x -> head x /= '.') files
    let libs = ["tests/libraries/" ++ f | f <- names]
    let libTests = [defaultTest {name=libName} | libName <- names]

    libTests' <- zipWithM runParseTest libTests libs

    nextTestNum <- getNextTestNum
    endTime <- getCPUTime
    let testResults = TestResults {
        testNum = nextTestNum,
        message = msg,
        strucTests = funcTest:exprTest:[statTest],
        libTests = libTests',
        time = calcTime startTime endTime,
        average = mean $ map percentage libTests'
    }

    -- Pretty print results
    putStrLn $ ppTestResults testResults ""

    -- Write results to file
    if msg /= "No message" then
        if nextTestNum == 0 then
            writeFile testResultsFile (show testResults)
         else
            appendFile testResultsFile ('\n':(show testResults))
     else
        putStr ""



runParseTest :: Test -> String -> IO Test
runParseTest test file = do
    input <- readFile file
    let parseOutput = parseJS input
    case parseOutput of
        Left error -> do
            return (test {
                result    = False,
                errorMsg  = error,
                inputSize = length input
            })
        Right (tree, state) -> do
            let output = genJS tree
            let outFile = outTestFile file
            saveFile outFile output
            -- Write to file
            return (test {
                result      = True,
                inputSize   = length input,
                outputSize  = length output,
                reduction   = (length input) - (length output),
                percentage  = calcRatio input output
            })
    where
        outTestFile :: String -> String
        outTestFile inFile = "tests/outputLibraries/" ++ minFile
            where
                file    = reverse $ takeWhile (/='/') $ reverse inFile
                minFile = reverse $ takeWhile (/='.') (reverse file)
                          ++ ".nim" ++ dropWhile (/='.') (reverse file)



showPastResults :: IO()
showPastResults = do
    f <- readFile testResultsFile
    let results = [ppTestResults tr "" | tr <- map read (lines f)]
    mapM_ putStrLn results

showLastResult :: IO()
showLastResult = do
    f <- readFile testResultsFile
    putStrLn $ ppTestResults (read $ last (lines f)) ""

showResult :: Int -> IO()
showResult n = do
    f <- readFile testResultsFile
    putStrLn $ ppTestResults (read $ (lines f) !! n) ""

showAverages :: IO()
showAverages = do
    putStrLn "Percentage of output to input:\n"
    f <- readFile testResultsFile
    let tests = [tr | tr <- map read (lines f)]
    let strings = ["Test " ++ (show $ testNum t) ++
                   " average:\t" ++ (show $ average t) ++
                   "    \t" ++ (message t) | t <- tests]
    mapM_ putStrLn strings


getNextTestNum :: IO Int
getNextTestNum = do
    f <- readFile testResultsFile
    return $ length $ lines f


ppTestResults :: TestResults -> ShowS
ppTestResults (TestResults {testNum = n, message = m,
                           strucTests = sts, libTests = lts,
                           time = t, average = a}) =
    showString "Test number" . spc . showString (show n) . nl
    . indent 1 . showString "Message:" . spc . showString m . nl . nl
    . indent 1 . showString "STRUCTURE TESTS" . nl
    . ppSeq 1 ppTest sts . nl
    . indent 1 . showString "LIBRARY TESTS" . nl
    . ppSeq 1 ppTest lts . nl
    . showString "Completed in" . spc . showString (take 5 (show t))
    . spc . showString "seconds" . nl
    . showString "Average compression:" . spc
    . showString (take 5 (show a)) . showChar '%' . nl

ppTest :: Int -> Test -> ShowS
ppTest idnt (Test {name = n, result = r, errorMsg = e,
                inputSize = i, outputSize = o,
                reduction = d, percentage = p}) =
    indent idnt . showString n . nl
    . indent (idnt+1) . showString "Result:" . spc . ppResult r . nl
    . ppErrorMsg (idnt+1) e
    . indent (idnt+1) . showString "Input size:" . spc . showString (show i) . nl
    . indent (idnt+1) . showString "Output size:" . spc . showString (show o) . nl
    . indent (idnt+1) . showString "Reduced by:" . spc . showString (show d) . nl
    . indent (idnt+1) . showString "Percentage of original:" . spc
    . showString (take 5 (show p)) . showChar '%' . nl

ppResult :: Bool -> ShowS
ppResult True  = showString "PASS"
ppResult False = showString "FAIL"

ppErrorMsg :: Int -> String -> ShowS
ppErrorMsg _ ""  = showString ""
ppErrorMsg n msg = indent n . showString "Error message:"
    . spc . showString msg . nl