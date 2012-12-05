module Test where

import Control.Monad.Identity
import Control.Monad.Error
import Control.Monad.State

import Token
import Lexer
import LexerMonad
import AST
import ParseMonad
import Parser

parseProgram :: String -> Either String (Program, LexerState)
parseProgram str
    = runIdentity $ runErrorT $ runStateT parse (startState str)