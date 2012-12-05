{-
******************************************************************************
*                                      JSHOP                                 *
*                                                                            *
*   Module:   Token                                                          *
*   Purpose:  Representation of tokens (lexical symbols)                     *
*   Authors:  Nick Brunt, Henrik Nilsson                                     *
*                                                                            *
*                       Based on the HMTC equivalent                         *
*                 Copyright (c) Henrik Nilsson, 2006 - 2011                  *
*                      http://www.cs.nott.ac.uk/~nhn/                        *
*                                                                            *
*                         Revisions for JavaScript                           *
*                    Copyright (c) Nick Brunt, 2011 - 2012                   *
*              Subject to MIT License as stated in root directory            *
*                                                                            *
******************************************************************************
-}

-- | Representation of tokens (lexical symbols).

module Token where

-- | Token type.
data Token
    = WS               -- ^ Whitespace
    | SLCom            -- ^ Single line comment (necessary for line counting - discarded after lexer)
    | LitInt   Integer -- ^ Integer literals
    | LitFloat Double  -- ^ Float literals (Using Haskell's Double for safety)
    | LitStr   String  -- ^ String literals
    | Id       String  -- ^ Identifiers
    | Regex    String  -- ^ Regular expressions
    | ResId    String  -- ^ Reserved identifier
    | ResOp    String  -- ^ Reserved operator
    | Other    String  -- ^ Unknown other symbol
    | EOF              -- ^ End of file (input) marker
    deriving (Eq, Show)