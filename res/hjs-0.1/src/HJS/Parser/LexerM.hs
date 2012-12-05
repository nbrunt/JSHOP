{-

     The Monadic Lexer.
     Provides a monadic wrapper around the Alex lexer and handles nasties

-}

module HJS.Parser.LexerM(lexer,lexerM,autoSemiInsert) where

import Data.Char
import qualified Data.ByteString.Char8 as BS
import Control.Monad.State
import Control.Monad.Error
import Debug.Trace

import HJS.Parser.ParserMonad
import HJS.Parser.Lexer
import HJS.Parser.Regex

-- Cut down lexer for parsing comments. Cannot just skip over as we want to count the lines
lexerComment :: (Token -> P a) -> P a
lexerComment cont  = do
                       st  <- get 
                       case (rest st) of 
                         ('\n':cs) -> do put st { rest = cs, lineno = 1 + (lineno st) }; lexerComment cont
                         ('*':'/':cs) -> do put st { rest = cs }; lexerM 0 cont
                         (_:cs) ->  do put st { rest = cs}; lexerComment cont



lexerM :: Int -> (Token -> P a) -> P a
lexerM action cont = do
                  st <- get
                  put st { nl = False }
                  case action of 
                        46 -> case parseRegex ('/':(rest st)) of 
                                                    Left s -> throwError s
                                                    Right (s,r) -> do  
								     put st { rest = r, lastToken=Just $ TokenRegex ""}
                                                                     cont (TokenRegex s)
                        _ -> lexerM' action cont
 {-                 case expectRegex st && ((lastToken st) == (Just $ TokenROP "/")) of
                        True -> do 
                                                  case parseRegex ('/':(rest st)) of 
                                                    Left s -> throwError s
                                                    Right (s,r) -> do  
                                                          put st { rest = r, lastToken=Just $ TokenRegex ""}
                                                          cont (TokenRegex s)
                        False -> lexerM' cont -}
 


lexerM' :: Int -> (Token -> P a) -> P a
lexerM' action cont = do
                   st <- get
                   case (rest st) of 
                            ('\n':cs) -> do put st { rest = cs, lineno = 1 + (lineno st),nl=True }; lexerM' 0 cont
                            ('/':'*':cs) -> do put st { rest = cs }; lexerComment cont
                            _ -> do let (token, cs) = lexer (rest st) 
                                    put st { rest=cs,rest2= (rest st),lastToken= Just token }
                                    cont token

lexerRegex :: String -> (Token,String)
lexerRegex s = case span (\c -> c /= '/') s of 
                       (regex, rest) -> (TokenRegex regex, rest)

lexer :: String -> (Token,String)
lexer str =  go ('\n',str)
  where go inp@(_,str) =
          case alexScan inp 0 of
                AlexEOF -> (TokenEof, [])
                AlexError (c,cs) -> error ("lexical error on " ++ cs)
                AlexSkip  inp' len     -> go inp'
                AlexToken inp'@(c,cs) len act -> case act (take len str) of 
                                               TokenWhite -> go inp'
                                               tok -> (tok, cs)



-- Handle automatic semicolon insertion. This will get passed the current 
-- lookahead token which will get discard so even if we have found a ';' we
-- need to put it backonto the stream so that it gets found again.
-- autoSemiInsert :: Token -> String -> P String
autoSemiInsert tok res = do 
		   s <- get 
	           case tok == (TokenROP ";") || tok == (TokenROP "}" ) || (nl s) of 
                      True -> do 
                                 let r = if tok == (TokenROP ";") then 
                                               rest2 s
                                         else (';':(rest2 s))
                                 put s { rest= r }
                                 return res
		      _ -> throwError $ "Expecting Semi or NL " ++ (show tok) ++ (show s)


showToken tok = do
		  Debug.Trace.trace ("Token is " ++ (show tok)) ""