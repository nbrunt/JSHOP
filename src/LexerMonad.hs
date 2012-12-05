{-
******************************************************************************
*                                      JSHOP                                 *
*                                                                            *
*   Module:   LexerMonad                                                     *
*   Purpose:  Monadic wrapper for the Alex lexer                             *
*   Author:   Nick Brunt                                                     *
*                                                                            *
*                    Copyright (c) Nick Brunt, 2011 - 2012                   *
*              Subject to MIT License as stated in root directory            *
*                                                                            *
*     Adapted from http://www.haskell.org/alex/doc/html/wrappers.html        *
*                                                                            *
******************************************************************************
-}

-- | Monadic wrapper for the Alex lexer

module LexerMonad (
    lexer,            -- String -> Either (Token,String) String
    monadicLexer,     -- (Token -> P a) -> P a
    autoSemiInsert    -- autoSemiInsert :: Token -> a -> P a
) where

-- Standard library imports
import Data.Char
import qualified Data.ByteString.Char8 as BS
import Control.Monad.State
import Control.Monad.Error

-- JSHOP module imports
import Token
import ParseMonad
import Lexer

-- | Main lexer function.  Uses state monad to store current state of the lexer.
monadicLexer :: (Token -> P a) -> P a
monadicLexer cont = do
    chr <- get
    put chr { nl = False }
    monadicLexer' cont

-- | Catches newlines and multi-line comments.  Single-line comments are caught in the lexer.
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
            let lexResult = lexer (rest chr)
            case lexResult of
                -- Specifically check for single line comments.  Increment line number then skip.
                Left (SLCom, xs) -> do
                    put chr {rest = xs, lineno = (lineno chr) + 1, nl = True}
                    monadicLexer' cont
                Left (token, xs) -> do
                    put chr {rest = xs, rest2 = (rest chr), lastToken = Just token}
                    cont token
                Right xs -> do
                    put chr {rest = xs}
                    monadicLexer' cont

-- | Scans to the end of a multiline comment.  Could have used a regex in
-- the lexer but we want to count lines.
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


-- | Given a string, returns a tuple containing the token of the first item in the
-- string and the remaining string.
lexer :: String                         -- ^ The remaining input
      -> Either (Token,String) String   -- ^ Either the token and the remaining string
                                        --   or just the remaining string if the token is
                                        --   to be skipped
lexer input = go ('\n', [], input)
    where
        go inp@(_,_,rem) =
            case alexScan inp 0 of
                AlexEOF            -> Left (EOF, [])
                AlexError (c,_,cs)   -> error ("Lexical error at " ++ take 50 cs)
                AlexSkip inp' len  -> go inp'
                AlexToken inp'@(x,_,xs) len act -> case act (take len rem) of
                    WS      -> Right xs -- Skip whitespace
                    -- Regexs match one char too many (see note in Lexer.x) so this corrects it.
                    Regex s -> Left (Regex (init s), (last s):xs)
                    token   -> Left (token, xs)


{- |
    Handle automatic semicolon insertion. This will get passed the current
    lookahead token which will get discard so even if we have found a ';' we
    need to put it back onto the stream so that it gets found again.

    See ECMA-262 documentation page 21
-}
autoSemiInsert :: Token -> a -> P a
autoSemiInsert token res = do
    s <- get
    if token == (ResOp ";")     -- Next token is a ; anyway, so no need to add another one
        || token == (ResOp "}") -- Next token is a }, so a ; is not necessary, but add one anyway to
                                -- keep the parser happy (pun intended)
        || token == (ResOp "(") -- Next token is a ), so this must have been an exprStmt, so add a ;
        || token == EOF         -- We're at the end of the file, add a ;
        || (nl s)
        then do
            let r = if token == (ResOp ";") then rest2 s
                     else (';':(rest2 s))
            put s { rest = r }
            return res
        else throwError $ "Expecting Semi or NL: " ++
                          "lineno = " ++ show (lineno s) ++
                          ", token = " ++ show token ++
                          ", " ++ take 50 (show s)