{-
  Haskell Javascript Parser
  (c) Mark Wassell 2007
  See LICENSE file for license details

-}
module Main(main,lexer,parseProgram,parseFile) where -- parseTest


import Data.ByteString.Char8(split,pack,unpack,readInt) -- join
import Data.List
import Data.Ord
import Data.Char

import System.Console.GetOpt
import Data.Maybe ( fromMaybe )

import Control.Monad.Identity
import Control.Monad.Error
import Control.Monad.State

import System.Directory
import System.Environment

import HJS.Parser.Lexer
import HJS.Parser.LexerM
import HJS.Parser.JavaScriptParser
import HJS.Parser.JavaScript
import HJS.Parser.ParserMonad

import HJS.Interpreter.Interp

data VFlag = Quiet | ShowProgress | ShowErrors | ShowAST deriving (Show,Eq)

-- Parse a JS program
parseProgram str =  runIdentity $ runErrorT $ runStateT jsprogram 
		    (startState str)

-- Parse primitive expression
parsePrimExpr str =  runIdentity $ runErrorT $ runStateT primexpr (startState str)

-- Parse a file with supplied flags
parseFile :: [VFlag] -> String -> IO ()
parseFile flags fname = do
                          ifM (elem ShowProgress flags) (putStr $ "Parsing \"" ++ fname) (return ())
                          s <- readFile fname
                          handleResult flags $ parseProgram s 

handleResult flags (Right r) | (elem ShowProgress flags) = putStrLn ("\"  ok")
                             | (elem ShowAST flags)      = putStrLn ("\" ok " ++ show r)
                             | otherwise = return ()
handleResult flags (Left r)  | (elem ShowProgress flags) = putStrLn ("\"  failed")
                             | (elem ShowErrors flags)   = putStrLn  ("\" failed" ++ r)
                             | otherwise = return ()

lexFile fname = do
                   s <- readFile fname
                   putStrLn $ show $ alexScanTokens s

runFile fname = do
               putStrLn $ "Running: " ++ fname
               s <- readFile fname
               case parseProgram s of 
                              Right (r,s) -> putStrLn $ show $ interp r
                              Left s -> putStrLn s


main = do
         s <- getArgs
	 main' s

main' args = do 
         (opt, files) <- interpOpts args
         case (foldr (\x s -> case x of Version -> (True || s); _ -> s) False opt) of 
             True -> putStrLn "HJS - JavaScript Parser - Version 0.1"
             _ -> return ()
         let vf = foldr (\x s -> case x of (Verbose f) -> (f:s);_ -> s) [] opt
         mapM_ (parseFile vf) files
	
{-
parseTest = do 
	     testFiles "../test" (parseFile [])
	     testFiles "../test/parsingonly" (parseFile [])


runTest = testFiles "../test" runFile

testFiles dir action =   do fileList <- getTestFiles dir
			    mapM_ action  fileList


             
getTestFiles dirName  = do
          dirList <- getDirectoryContents dirName
          return $  map (\f -> dirName ++ "/" ++ f) $
                    map unpack $ 
	            map (Data.ByteString.Char8.join (pack "_"))  $ 
		    sortBy (comparing (readInt . head)) $ 
		    filter (\l -> (<=) 2 (length l)) $ 
		    map (split '_' . pack) $ 
	            filter (\x -> last x /= '~' || head x == '.' ) dirList
-}


    
data Flag  = Verbose VFlag | Version  
		 deriving Show
    
options :: [OptDescr Flag]
options =
     [ Option ['v']     ["verbose"] (OptArg vflag "LEVEL" )       "=1 show progrss, =2 show errors =3 show AST"
     , Option ['V','?'] ["version"] (NoArg Version)       "show version number"
     ]
    
vflag :: Maybe String -> Flag
vflag Nothing = Verbose Quiet
vflag (Just s) = let s' = filter (\c -> not $ isSpace c) s
                 in case s' of 
                          "1" -> Verbose ShowProgress
   		          "2" -> Verbose ShowErrors
                          "3" -> Verbose ShowAST
                          _ -> error $ "Cannot parse verbosity option " ++ s'

--inp,outp :: Maybe String -> Flag
--outp = Output . fromMaybe "stdout"
--inp  = Input  . fromMaybe "stdin"
    
interpOpts :: [String] -> IO ([Flag], [String])
interpOpts argv = 
       case getOpt Permute options argv of
          (o,n,[]  ) -> return (o,n)
          (_,_,errs) -> ioError (userError (concat errs ++ usageInfo header options))
      where header = "Usage: hjs [OPTION...] files..."
