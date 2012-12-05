module HJS.Parser.ParserMonad where


import Control.Monad.Identity
import Control.Monad.Error
import Control.Monad.State

import HJS.Parser.Lexer


data ParseResult a = Ok a | Failed String deriving Show
data LexerMode = Normal | InComment | InRegex  deriving Show
data LexerState = LS { rest::String,lineno::Int,mode::LexerMode,tr:: [String], 
		       nl:: Bool, rest2 :: String, expectRegex :: Bool, lastToken::(Maybe Token)} deriving Show

startState str = LS { rest=str, lineno=1, mode =Normal, tr=[], nl = False, rest2 = "", expectRegex = False,lastToken=Nothing}

type P  = StateT LexerState (ErrorT String Identity)

getLineNo :: P Int
getLineNo = do
                s <- get
                return $ lineno s

putLineNo :: Int -> P ()
putLineNo l = do
                 s <- get 
                 put s { lineno = l }



trace :: String -> P ()
trace ts = do 
             s  <- get 
             put s { tr = ts : (tr s) }

ifM a b c = do 
	        case a of 
		   True -> b
                   False -> c