{-
******************************************************************************
*                                      JSHOP                                 *
*                                                                            *
*   Module:   ParseMonad                                                     *
*   Purpose:  Monad for scanning and parsing                                 *
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

module ParseMonad where

-- Standard library imports
import Control.Monad.Identity
import Control.Monad.Error
import Control.Monad.State

-- JSHOP module imports
import Token
--import Lexer

data LexerMode
    = Normal
    | InComment
    | InRegex
    deriving Show

data LexerState
    = LS {rest        :: String,
          lineno      :: Int,
          mode        :: LexerMode,
          tr          :: [String], 
          nl          :: Bool,
          rest2       :: String,
          expectRegex :: Bool,
          lastToken   :: (Maybe Token)}
    deriving Show
    
startState str
    = LS {rest = str,
          lineno = 1,
          mode = Normal,
          tr = [],
          nl = False,
          rest2 = "",
          expectRegex = False,
          lastToken = Nothing}

type P = StateT LexerState (ErrorT String Identity)

getLineNo :: P Int
getLineNo = do
    s <- get
    return (lineno s)








{-
-- | Monad for scanning and parsing. 
-- The scanner and parser are both monadic, following the design outlined
-- in the Happy documentation on monadic parsers. The parse monad P
-- is built on top of the diagnostics monad D, additionally keeping track
-- of the input and current source code position, and exploiting that
-- the source code position is readily available to avoid having to pass
-- the position as an explicit argument.

module ParseMonad (
    -- The parse monad
    P (..),       -- Not abstract. Instances: Monad.
    unP,          -- :: P a -> (Int -> Int -> String -> D a)
    emitInfoP,    -- :: String -> P ()
    emitWngP,     -- :: String -> P ()
    emitErrP,     -- :: String -> P ()
    failP,        -- :: String -> P a
    getSrcPosP,   -- :: P SrcPos
    runP          -- :: String -> P a -> D a
) where

-- JSHOP module imports
import SrcPos
import Diagnostics

newtype P a = P (Int -> Int -> String -> D a)


unP :: P a -> (Int -> Int -> String -> D a)
unP (P x) = x


instance Monad P where

    return a = P (\_ _ _ -> return a)

    p >>= f = P (\l c s -> unP p l c s >>= \a -> unP (f a) l c s)


-- Liftings of useful computations from the underlying D monad, taking
-- advantage of the fact that source code positions are available.

-- | Emits an information message.
emitInfoP :: String -> P ()
emitInfoP msg = P (\l c _ -> emitInfoD (SrcPos l c) msg)


-- | Emits a warning message.
emitWngP :: String -> P ()
emitWngP msg = P (\l c _ -> emitWngD (SrcPos l c) msg)


-- | Emits an error message.
emitErrP :: String -> P ()
emitErrP msg = P (\l c _ -> emitErrD (SrcPos l c) msg)


-- | Emits an error message and fails.
failP :: String -> P a
failP msg = P (\l c _ -> failD (SrcPos l c) msg)


-- | Gets the current source code position.
getSrcPosP :: P SrcPos
getSrcPosP = P (\l c _ -> return (SrcPos l c))


-- | Runs parser (and scanner), yielding a result in the diagnostics monad D.
runP :: P a -> String -> D a
runP p s = unP p 1 1 s
-}