{-
******************************************************************************
*                                      JSHOP                                 *
*                                                                            *
*   Module:   ParseMonad                                                     *
*   Purpose:  Monad for storing Parser state                                 *
*   Author:   Nick Brunt                                                     *
*                                                                            *
*                    Copyright (c) Nick Brunt, 2011 - 2012                   *
*              Subject to MIT License as stated in root directory            *
*                                                                            *
******************************************************************************
-}

-- | Monad for storing Parser state

module ParseMonad where

-- Standard library imports
import Control.Monad.Identity
import Control.Monad.Error
import Control.Monad.State

-- JSHOP module imports
import Token

-- | Lexer state
data LexerState
    = LS {
        rest        :: String,        -- ^ The remaining input
        lineno      :: Int,           -- ^ Current line number
        nl          :: Bool,          -- ^ Newline flag
        rest2       :: String,        -- ^ For use with automatic semicolon insertion
        lastToken   :: (Maybe Token)  -- ^ The token just lexed
    }
    deriving Show

-- | The initial state of the lexer
startState :: String -> LexerState
startState str
    = LS {
        rest = str,
        lineno = 1,
        nl = False,
        rest2 = "",
        lastToken = Nothing
    }

-- | Parser monad incorporating the lexer state
type P = StateT LexerState (ErrorT String Identity)
