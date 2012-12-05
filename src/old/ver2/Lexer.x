-- ******************************************************************************
-- *                                      JSHOP                                 *
-- *                                                                            *
-- *   Module:   Lexer                                                          *
-- *   Purpose:  JavaScript Lexical Analyser                                    *
-- *   Authors:  Nick Brunt                                                     *
-- *                                                                            *
-- *                    Copyright (c) Nick Brunt, 2011 - 2012                   *
-- *                                                                            *
-- *                  The structure for this file was partially                 *
-- *                      determined from a Haskell lexer:                      *
-- *               http://darcs.haskell.org/alex/examples/haskell.x             *
-- *                                                                            *
-- ******************************************************************************

{
module Lexer where

import Token
}

%wrapper "basic"

-- Special characters
$whitechar = [ \t\n\r\f\v]
$spacechar = [ \t]
$special   = [\(\)\,\;\[\]\`\{\}]

$digit     = 0-9
$alpha     = [a-zA-Z]

-- Symbols are any of the following characters except (#) some special cases
$symbol    = [\!\#\$\%\&\*\+\.\/\<\=\>\?\@\\\^\|\-\~\,\;] # [$special \_\:\"\']

$graphic   = [$alpha $symbol $digit $special \:\"\'\,]

$octit	   = 0-7
$hexit     = [0-9 A-F a-f]
$nl        = [\n\r]

@sString   = $graphic # [\"] | " " | $nl
@dString   = $graphic # [\'] | " " | $nl

-- As stated in JavaScript Pocket Reference (O'Reilly, David Flanagan, 2nd edition), page 3
@reservedid =
          break|case|catch|continue|default|delete|do|else|false|finally|for|function|if|in|
          instanceof|new|null|return|switch|this|throw|true|try|typeof|var|void|while|with|
          -- reserved words for possible future extensions
          abstract|boolean|byte|char|class|const|debugger|double|enum|export|extends|final|
          float|implements|import|int|interface|long|native|package|private|protected|public|
          short|static|super|synchronized|throws|transient|volatile|
          -- and finally, let's hope not
          goto

-- As stated in JavaScript Pocket Reference (O'Reilly, David Flanagan, 2nd edition), pages 10 and 11
@reservedop =
          "." | "[" | "]" | "(" | ")" | "++" | "--" | "-" | "+" | "~" | "!" | "*" | "/" | "%" |
          "<<" | ">>" | ">>>" | "<" | "<=" | ">" | ">=" | "==" | "!=" | "===" | "!==" | "&" |
          "^" | "|" | "&&" | "||" | "?" | ":" | "=" | "*=" | "+=" | "-=" | "/=" | "%=" | "," |
          ";" | "{" | "}"

@decimal = $digit+

-- "Identifiers are composed of any number of letters and digits, and _ and $ characters.  The
--  first character of an identifier must not be a digit, however."
-- From JavaScript Pocket Reference (O'Reilly, David Flanagan, 2nd edition), page 2
$firstLetter = [$alpha \_ \$]
@id          = $firstLetter [$alpha $digit \_ \$]*

-- Capture any other unknown symbols
@other = $symbol

tokens :-
--  <0>  [^*/]/(\\[/\\]|[^*/])(\\.|[^/\n\\])*/[gim]*  { \s -> Other s }
  <0>  "//" [$spacechar $printable]* $nl     { \s -> WS }
  <0>  $white+                               { \s -> WS }
  <0>  @reservedid                           { \s -> ResId s }
  <0>  @reservedop                           { \s -> ResOp s }
  <0>  @decimal                              { \s -> LitInt (read s) }
  <0>  @id                                   { \s -> Id s }
  <0>  \" @sString* \"                       { \s -> LitStr s }
  <0>  \' @dString* \'                       { \s -> LitStr s }
  <0>  @other                                { \s -> Other s }

{
-- Each action has type :: String -> Token

main = do
  s <- getContents
  print (alexScanTokens s)

scanFile file = do
  input <- readFile file
  print (alexScanTokens input)
  
}