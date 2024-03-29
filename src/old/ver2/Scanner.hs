{-
******************************************************************************
*                                      JSHOP                                 *
*                                                                            *
*   Module:   Scanner                                                        *
*   Purpose:  JavaScript lexical analyser                                    *
*   Authors:  Nick Brunt, Henrik Nilsson                                     *
*                                                                            *
*                       Based on the HMTC equivalent                         *
*                 Copyright (c) Henrik Nilsson, 2006 - 2011                  *
*                      http://www.cs.nott.ac.uk/~nhn/                        *
*                                                                            *
*                         Revisions for JavaScript                           *
*                    Copyright (c) Nick Brunt, 2011 - 2012                   *
*                                                                            *
******************************************************************************
-}

-- | JavaScript lexical analyser

-- The scanner and parser are both monadic, making use of the parse monad
-- monad P. See the Happy documentation on monadic parsers for further
-- details.

module Scanner (
    scanner,     -- ((Token, SrcPos) -> P a) -> P a
    testScanner  -- String -> IO ()
) where

-- Standard library imports
import Char (isDigit, isAlpha, isAlphaNum)

-- JSHOP module imports
import SrcPos
import Token
import Diagnostics
import ParseMonad


-- Operator characters. 
-- The present scanner allows multi-character operators. This means that
-- strings of operator characters will be scanned as a signle token as opposed
-- to a sequence of tokens. Operators characters are all non-alphanumerical
-- ASCII characters except the parentheses ('(', ')', '[', ']', '{', '}'),
-- double, single, and back quote quote ('"', '\''', '`'), and underscore
-- ('_').
isOpChr :: Char -> Bool
isOpChr '!'  = True
isOpChr '#'  = True
isOpChr '$'  = True
isOpChr '%'  = True
isOpChr '&'  = True
isOpChr '*'  = True
isOpChr '+'  = True
isOpChr '-'  = True
isOpChr '.'  = True
isOpChr '/'  = True
isOpChr ':'  = True
isOpChr '<'  = True
isOpChr '='  = True
isOpChr '>'  = True
isOpChr '?'  = True
isOpChr '@'  = True
isOpChr '\\' = True
isOpChr '^'  = True
isOpChr '|'  = True
isOpChr '~'  = True
isOpChr _    = False


-- Tab stop separation
tabWidth :: Int
tabWidth = 8


nextTabStop :: Int -> Int
nextTabStop n = n + (tabWidth - (n-1) `mod` tabWidth)


-- | JavaScript scanner. 

scanner :: ((Token, SrcPos) -> P a) -> P a
scanner cont = P $ scan
    where
        -- scan :: Int -> Int -> String -> D a
        -- End Of File
        scan l c []              = retTkn EOF l c c []
        -- Skip white space and comments
        scan l c ('\n' : s)      = scan (l + 1) 1 s
        scan l c ('\r' : s)      = scan l 1 s
        scan l c ('\t' : s)      = scan l (nextTabStop c) s
        scan l c (' ' : s)       = scan l (c + 1) s
        scan l c ('/' : '/' : s) = scan l c (dropWhile (/='\n') s)
        -- Scan graphical tokens
        scan l c ('(' : s)       = retTkn LPar l c (c + 1) s
        scan l c (')' : s)       = retTkn RPar l c (c + 1) s
        scan l c ('{' : s)       = retTkn LBrace l c (c + 1) s
        scan l c ('}' : s)       = retTkn RBrace l c (c + 1) s
        scan l c (',' : s)       = retTkn Comma l c (c + 1) s
        scan l c (';' : s)       = retTkn Semicol l c (c + 1) s
        -- Scan character literals
        scan l c ('\'' : s)     = scanLitChr l c s
        -- Scan numeric literals, operators, identifiers, and keywords
        scan l c (x : s) | isDigit x = scanLitInt l c x s
                         | isAlpha x = scanIdOrKwd l c x s
                         | isOpChr x = scanOperator l c x s
                         | otherwise = do
                                          emitErrD (SrcPos l c)
                                                   ("Lexical error: Illegal \
                                                    \character "
                                                    ++ show x
                                                    ++ " (discarded)")
                                          scan l (c + 1) s

        
        -- Note: column c refers to position of already discarded start quote.
        -- scanLitChr :: Int -> Int -> String -> D a
        scanLitChr l c ('\\' : x : '\'' : s) =
            case encodeEsc x of
                Just e  -> retTkn (LitChr e) l c (c + 4) s
                Nothing -> do
                    emitErrD (SrcPos l c)
                             ("Lexical error: Illegal escaped character "
                              ++ show x ++ " in character literal (discarded)")
                    scan l (c + 4) s
        scanLitChr l c (x : '\'' : s)
            | x >= ' ' && x <= '~' && x /= '\'' && x /= '\\' =
                retTkn (LitChr x) l c (c + 3) s
            | otherwise = do
                emitErrD (SrcPos l c)
                         ("Lexical error: Illegal character "
                          ++ show x ++ " in character literal (discarded)")
                scan l (c + 3) s
        scanLitChr l c s = do
            emitErrD (SrcPos l c)
                     ("Lexical error: Malformed character literal \
                      \(discarded)")
            scan l (c + 1) s

        encodeEsc 'n'  = Just '\n'
        encodeEsc 'r'  = Just '\r'
        encodeEsc 't'  = Just '\t'
        encodeEsc '\\' = Just '\\'
        encodeEsc '\'' = Just '\''
        encodeEsc _    = Nothing


        -- scanLitInt :: Int -> Int -> Char -> String -> D a
        scanLitInt l c x s = retTkn (LitInt (read (x : tail))) l c c' s'
            where
                (tail, s') = span isDigit s
                c'         = c + 1 + length tail

        -- Allows multi-character operators.
        -- scanOperator :: Int -> Int -> Char -> String -> D a
        scanOperator l c x s = retTkn (mkOpOrSpecial (x:tail)) l c c' s'
            where
                (tail, s') = span isOpChr s
                c'         = c + 1 + length tail

        mkOpOrSpecial :: String -> Token
        mkOpOrSpecial ":"  = Colon
--        mkOpOrSpecial ":=" = ColEq
        mkOpOrSpecial "="  = Equals
        mkOpOrSpecial "?"  = Cond
        mkOpOrSpecial name = Op {opName = name}

        -- scanIdOrKwd :: Int -> Int -> Char -> String -> D a
        scanIdOrKwd l c x s = retTkn (mkIdOrKwd (x : tail)) l c c' s'
            where
                (tail, s') = span isAlphaNum s
                c'         = c + 1 + length tail

        mkIdOrKwd :: String -> Token
--        mkIdOrKwd "begin"  = Begin
--        mkIdOrKwd "const"  = Const
        mkIdOrKwd "do"     = Do
        mkIdOrKwd "else"   = Else
--        mkIdOrKwd "elsif"  = Elsif
--        mkIdOrKwd "end"    = End
        mkIdOrKwd "if"     = If
        mkIdOrKwd "in"     = In
--        mkIdOrKwd "let"    = Let
--        mkIdOrKwd "repeat" = Repeat
--        mkIdOrKwd "then"   = Then
--        mkIdOrKwd "until"  = Until
        mkIdOrKwd "var"    = Var
        mkIdOrKwd "while"  = While
        mkIdOrKwd name     = Id {idName = name}

        -- Return token, position of token, updated position, and remaning
        -- input. We assume tnat no MiniTriangle token span multiple
        -- lines. Hence only one line number argument is needed.
        -- retTkn :: Token -> Int -> Int -> Int -> String -> D a
        retTkn t l c c' = unP (cont (t, SrcPos {spLine = l, spCol = c})) l c'


-- | Test utility. Scans the input and, if successful, prints the resulting
-- tokens.

testScanner :: String -> IO ()
testScanner s = do
    putStrLn "Diagnostics:"
    mapM_ (putStrLn . ppDMsg) (snd result)
    putStrLn ""
    case fst result of
        Just tss -> do
                        putStrLn "Tokens:"
                        mapM_ (putStrLn . show) tss
        Nothing -> putStrLn "Scanning produced no result."
    putStrLn ""
    where
        result :: (Maybe [(Token,SrcPos)], [DMsg])
        result = runD (runP (scanner (acceptToken [])) s)

        acceptToken :: [(Token,SrcPos)] -> (Token,SrcPos) -> P [(Token,SrcPos)]
        acceptToken tss (ts@(t,_)) =
            let tss' = ts : tss
            in
                case t of
                    EOF -> return (reverse tss')
                    _   -> scanner (acceptToken tss')
