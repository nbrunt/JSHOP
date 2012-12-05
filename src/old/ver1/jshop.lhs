> module JSHOP where

> import System
> import Char


Initial Parser
--------------

Creates an Abstract Syntax Tree of the code dividing it up into either removable comments, removeable spaces,
and any remaining code.

> data Token = Comment  String
>            | Space    String
>            | Other    String
>            deriving (Eq, Show)

>
> type AST   = [Token]


> scanner    :: String -> AST
> scanner cs =  scan cs
>               where
>                 scan        :: String -> AST
>                 scan []     =  []
>                 scan (x:xs) =  case x of
>                                  '/'       -> retPossComment (x:xs)
>                                  ' '       -> retPossSpace (x:xs)
>                                  otherwise -> retOther (x:xs)
>                                  where
>                                    retPossComment xs = -- Decide if comment then return: Comment "comment string" : scan (rest of xs)
>                                    retPossSpace xs   = -- Decide if space then return: Space "space string" : scan (rest of xs)
>                                    retOther xs       = -- Return: Other "other string" : scan (rest of xs)


> main                      :: IO()
> main                      =  do
>                                args <- getArgs
>                                case args of
>                                  [] -> do
>                                    -- No specified file or code, ask for user input
>                                    putStr "Please enter a filename: "
>                                    inFile <- getLine
>                                    compFile inFile
>                                  (inFile:_) -> do
>                                    -- Return file with original filename plus ".min" e.g. test.min.js
>                                    input <- readFile inFile
>                                    let outFile = takeWhile (/='.') inFile ++ ".min" ++ dropWhile (/='.') inFile
>                                    writeFile outFile (compress input)

> compFile                  :: String -> IO()
> compFile file             =  do
>                                input <- readFile file
>                                let output = compress input
>                                putStrLn ("\n" ++ msg ++ "\n" ++ underline ++ "\n")
>                                putStrLn output
>                                putStrLn ("\n" ++ underline ++ "\n")
>                                putStrLn ("Info\n----\n")
>                                putStrLn ("Input size:  " ++ show (length input) ++ " bytes")
>                                putStrLn ("Output size: " ++ show (length output) ++ " bytes")
>                                putStrLn ("Compressed by: " ++ show (length input - length output) ++ " bytes")
>                                  where
>                                    msg       = ("Compressed " ++ file ++ " follows")
>                                    underline = (replicate (length msg) '-')

> compress                  :: String -> String
> compress cs               =  cs