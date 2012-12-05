{-
******************************************************************************
*                                      JSHOP                                 *
*                                                                            *
*   Module:   LexerMonad                                                     *
*   Purpose:  Monadic wrapper for the Alex lexer to handle regex             *
*   Authors:  Nick Brunt                                                     *
*                                                                            *
*                    Copyright (c) Nick Brunt, 2011 - 2012                   *
*                                                                            *
*     Adapted from http://www.haskell.org/alex/doc/html/wrappers.html        *
*                                                                            *
******************************************************************************
-}

module LexerMonad(lexer,monadicLexer,autoSemiInsert) where

-- Standard library imports
import Data.Char
import qualified Data.ByteString.Char8 as BS
import Control.Monad.State
import Control.Monad.Error
import Debug.Trace

-- JSHOP module imports
import Token
import ParseMonad
import Lexer
import Regex

monadicLexer :: (Token -> P a) -> P a
monadicLexer cont = do
    chr <- get
    put chr { nl = False }
    monadicLexer' cont


monadicLexer' :: (Token -> P a) -> P a
monadicLexer' cont = do
    chr <- get
    case (rest chr) of
        ('\n':xs) -> do
            put chr {rest = xs, lineno = (lineno chr) + 1, nl = True}
            monadicLexer' cont
        ('/':'*':xs) -> do
            put chr {rest = xs}
            scanComment cont
        _ -> do
            let (token, xs) = lexer (rest chr)
            put chr {rest = xs, rest2 = (rest chr), lastToken = Just token}
            cont token


{-monadicLexer :: Int -> (Token -> P a) -> P a
monadicLexer action cont = do
    chr <- get
    put chr { nl = False }
    case action of
        46 -> case parseRegex ('/':(rest chr)) of
            Left s      -> throwError s
            Right (s,r) -> do
                put chr {rest = r, lastToken = Just (Regex "")}
                cont (Regex s)
        _ ->  monadicLexer' action cont


monadicLexer' :: Int -> (Token -> P a) -> P a
monadicLexer' action cont = do
    chr <- get
    case (rest chr) of
        ('\n':xs) -> do
            put chr {rest = xs, lineno = (lineno chr) + 1, nl = True}
            monadicLexer' 0 cont
        ('/':'*':xs) -> do
            put chr {rest = xs}
            scanComment cont
        _ -> do
            let (token, xs) = lexer (rest chr)
            put chr {rest = xs, rest2 = (rest chr), lastToken = Just token}
            cont token -}
            
scanComment :: (Token -> P a) -> P a
scanComment cont = do
    chr <- get 
    case (rest chr) of 
        ('\n':xs) -> do
            put chr {rest = xs, lineno = (lineno chr) + 1}
            scanComment cont
        ('*':'/':xs) -> do
            put chr {rest = xs}
            monadicLexer cont
        (_:xs) -> do
            put chr {rest = xs}
            scanComment cont


-- Given a string, returns a tuple containing the token of the first item in the
-- string and the remaining string.  Ignores whitespace.
lexer :: String -> (Token,String)
lexer input = go ('\n', input)
    where
        go inp@(_,rem) =
            case alexScan inp 0 of
                AlexEOF            -> (EOF, [])
                AlexError _        -> error ("Lexical error")     -- TODO: Handle arguments, use emitErrorD ?
                AlexSkip inp' len  -> go inp'
                AlexToken inp'@(x,xs) len act -> case act (take len rem) of
                    WS    -> go inp'
                    token -> (token, xs)
                    
-- Handle automatic semicolon insertion. This will get passed the current 
-- lookahead token which will get discard so even if we have found a ';' we
-- need to put it back onto the stream so that it gets found again.
-- autoSemiInsert :: Token -> String -> P String
autoSemiInsert tok res = do 
    s <- get 
    case tok == (ResOp {ropName=";"}) || tok == (ResOp {ropName="}"} ) || (nl s) of 
        True -> do 
            let r = if tok == (ResOp {ropName=";"}) then 
                      rest2 s
                     else (';':(rest2 s))
            put s { rest= r }
            return res
        _ -> throwError $ "Expecting Semi or NL " ++ (show tok) ++ (show s)