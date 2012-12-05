{
module HJS.Parser.Lexer where
}

%wrapper "basic"


$whitechar = [ \t\n\r\f\v]
$spacechar = [ \t]
$special   = [\(\)\,\;\[\]\`\{\}]

$ascdigit  = 0-9
$unidigit  = [] -- TODO
$digit     = [$ascdigit $unidigit]

$ascsymbol = [\!\#\$\%\&\*\+\.\/\<\=\>\?\@\\\^\|\-\~\,\;]
$unisymbol = [] -- TODO
$symbol    = [$ascsymbol $unisymbol] # [$special \_\:\"\']

$large     = [A-Z \xc0-\xd6 \xd8-\xde]
$small     = [a-z \xdf-\xf6 \xf8-\xff \_]
$alpha     = [$small $large]

$graphic   = [$small $large $symbol $digit $special \:\"\'\,]

$octit	   = 0-7
$hexit     = [0-9 A-F a-f]
$nl        = [\n\r]

@stringdouble  = $graphic # [\"] | " " | $nl
@stringsingle  = $graphic # [\'] | " " | $nl

@reservedid = 
	break|else|new|var|case|finally|return|void|catch|for|switch|while|
	continue|function|this|with|default|if|throw|delete|in|try|do|instanceof|typeof|
	abstract|enum|int|short|
	boolean|export|interface|static|
	byte|extends|long|super|
	char|final|native|synchronized|
	class|float|package|throws|
	const|goto|private|transient|
	debugger|implements|protected|volatile|
	double|import|public

@reservedop =
	"==" | "=" | "+=" | "-=" | "++" | "--" | ";" | ":" | "?" | "," | "." |
	"!" | "*" | "/" | "(" | ")" | "{" | "}" | "[" | "]" | "^" | "&" | "&&" |
	"<=" | ">=" | "<" | ">" | "-" | "%" | "*=" | "/=" | "%=" | "+" |
  	"===" | "!==" | "!=" | "&&" | "||" | "|" | "<<" | ">>" | ">>>" | "~"

@decimal     = $digit+

@id  = $alpha [$alpha $digit \_]*

tokens :-
  <0>  "//" [$spacechar $printable]* $nl                    { \s -> TokenWhite }
  <0>  $white+			             { \s -> TokenWhite }
  <0>  @reservedid                           { \s -> TokenRID s }
  <0>  @reservedop                           { \s -> TokenROP s }
  <0>  @decimal                              { \s -> TokenInt $ read s}
  <0>  @id                                   { \s -> TokenIdent s }
  <0>  \" @stringdouble* \"		             { \s -> TokenStringLit s  }
  <0>  \' @stringsingle* \'		             { \s -> TokenStringLit s  }

{
-- Each right-hand side has type :: String -> Token


data Token
      = 
        TokenWhite  
      | TokenInt Int
      | TokenIdent String
      | TokenStringLit String
      | TokenNL
      | TokenRegex String
      | TokenEof
      | TokenRID String
      | TokenROP String
 deriving (Show,Eq)


}
