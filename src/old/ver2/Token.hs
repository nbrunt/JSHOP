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
*                                                                            *
******************************************************************************
-}

-- | Representation of tokens (lexical symbols).

module Token where

-- JSHOP module imports
import Name


-- | Token type.

data Token
    = WS                          -- ^ Whitespace
    | LitInt {liVal   :: Integer} -- ^ Integer literals
    | LitStr {lsVal   :: String}  -- ^ String literals
    | Id     {idName  :: String}  -- ^ Identifiers
    | Regex  {reStr   :: String}  -- ^ Regular expressions
    | ResId  {ridName :: String}  -- ^ Reserved identifier
    | ResOp  {ropName :: String}  -- ^ Reserved operator
    | Other  {oVal    :: String}  -- ^ Unknown other symbol
    | EOF                         -- ^ End of file (input) marker
    deriving (Eq, Show)
