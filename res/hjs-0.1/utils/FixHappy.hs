module Main where

import Prelude hiding (writeFile, readFile,splitAt)
import Data.ByteString.Char8

repl  :: ByteString -> ByteString
repl s = case findSubstring (pack "lexerM") s of 
                Nothing -> error "Cannot find string"
                Just i -> let (a,b) = splitAt (i+6) s 
                          in a `append` (pack " action ") `append` b


main = do
           s <- readFile "JavaScriptParser.hs"
           writeFile "JavaScriptParser.hs"  (repl s)
