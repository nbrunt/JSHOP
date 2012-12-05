--
--  Author: Mark Wassell
--
--  Created: 29 January 2007
--
--  Copyright (C) 2007 Mark Wassell
--
--  This library is free software; you can redistribute it and/or
--  modify it under the terms of the GNU Lesser General Public
--  License as published by the Free Software Foundation; either
--  version 2.1 of the License, or (at your option) any later version.
--
--  This library is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
--  Lesser General Public License for more details.
--
--  Specification of language comes from
--     Standard ECMA-262 3rd Edition - December 1999
--     JavaScript 1.5 Reference http://developer.mozilla.org/en/docs/Core_JavaScript_1.5_Reference
--     The JavaScript in JavaScript interpreter

{
module HJS.Parser.JavaScriptParser where

import Data.Char
import Control.Monad.State
import Control.Monad.Error

import HJS.Parser.Lexer
import HJS.Parser.LexerM
import HJS.Parser.JavaScript
import HJS.Parser.ParserMonad
}

%name jsprogram Program 
%name primexpr  PrimExpr

%monad { P }
%lexer { lexerM } { TokenEof }
%tokentype { Token }
%error { parseError }

%token 
      eof             { TokenEof } -- EOF
      int             { TokenInt $$ } -- LITINT
      ident           { TokenIdent $$ } -- ID
      string          { TokenStringLit $$ } -- LITSTR
      '='             { TokenROP "=" }
      '+'             { TokenROP "+" }
      '-'             { TokenROP "-" }
      '*'             { TokenROP "*" }
      '/'             { TokenROP "/" }
      '('             { TokenROP "(" }
      ')'             { TokenROP ")" }
      ','             { TokenROP "," }
      '\n'            { TokenNL }
      '?'             { TokenROP "?"}
      ':'             { TokenROP ":"}
      '||'            { TokenROP "||"}
      '&&'            { TokenROP "&&"}
      '|'             { TokenROP "|"}
      '^'             { TokenROP "^"}
      '&'             { TokenROP "&"}
      '=='            { TokenROP "=="}
      '!='            { TokenROP "!="}
      '==='           { TokenROP "==="}
      '!=='           { TokenROP "!=="}
      '<'             { TokenROP "<"}
      '<='            { TokenROP "<="}
      '>='            { TokenROP ">="}
      '>'             { TokenROP ">"}
      '<<'            { TokenROP "<<"}
      '>>'            { TokenROP ">>"}
      '>>>'           { TokenROP ">>>"}
      '!'             { TokenROP "!"}
      '~'             { TokenROP "~"}
      '++'            { TokenROP "++"}
      '--'            { TokenROP "--"}
      '.'             { TokenROP "."}
      '['             { TokenROP "["}
      ']'             { TokenROP "]"}
      '{'             { TokenROP "{"}
      '}'             { TokenROP "}"}
      delete          { TokenRID "delete" } --
      void            { TokenRID "void" } --
      typeof          { TokenRID "typeof" } --
      '%'             { TokenROP "%" }
      '*='            { TokenROP "*=" }
      '/='            { TokenROP "/=" }
      '%='            { TokenROP "%=" }
      '+='            { TokenROP "+=" }
      '-='            { TokenROP "-=" }
      instanceof      { TokenRID "instanceof" } --
      if              { TokenRID "if" } --
      else            { TokenRID "else" } --
      ';'             { TokenROP ";" }
      do              { TokenRID "do" } --
      while           { TokenRID "while" } --
      for             { TokenRID "for" } --
      this            { TokenRID "this" } --
      var             { TokenRID "var" } --
      const           { TokenRID "const" } -- Other
      function        { TokenRID "function" } --
      new             { TokenRID "new" } --
      try             { TokenRID "try" } --
      catch           { TokenRID "catch" } --
      finally         { TokenRID "finally" } --
      continue        { TokenRID "continue" } --
      break           { TokenRID "break" } --
      throw           { TokenRID "throw" } --
      return          { TokenRID "return" } --
      with            { TokenRID "with" } --
      switch          { TokenRID "switch"} --
      case            { TokenRID "case"} --
      default         { TokenRID "default"} --
      in              { TokenRID "in"} --
      regex           { TokenRegex $$ } -- REGEX
     
%%

Start : Program { $1 }

--
-- A.1 Lexical Grammar
--


Literal : int { LitInt $1 }
	| string { LitString $1 }

{- Not exactly sure why putting %% works but it is important. 
   If not then it will lookahead using the normal lexer 
   and fail. I think %% discards this lookedahead to give 
   us a chance to switch the lexer. Also need to run 
   happy with -a option -}
RegExStart : '/'   {} -- %% lexRegex }
RegExEnd :   '/'   {}



RegEx : RegExStart regex  { $2 }


--
-- A.3 Expressions
--

PrimExpr :: { PrimExpr } 
      : this                    { This }
      | ident                   { Ident $1 }
      | Literal                 { Literal $1 }
      | RegEx                   { Regex $1 }
      | ArrayLit                { Array $1 }
      | ObjectLiteral           { Object $1 }
      | '(' Expr ')'            { Brack $2 }

ArrayLit : '[' ElementList ']'     { ArrSimple $2 }

ElementList : {- empty -} { [] }
	    | AssignE {  [$1] }
	    | ElementList ',' AssignE { $1 ++ [$3]}

ObjectLiteral : '{' '}'    { [] }
	      | '{' PropertyList '}' { $2 }

-- 'get' and 'put' covered in
-- http://developer.mozilla.org/en/docs/Core_JavaScript_1.5_Guide:Creating_New_Objects:Defining_Getters_and_Setters
-- Note that they are not reserved words

PropertyList : Property { [$1 ] }
	     | PropertyList ',' Property { $1 ++ [$3] }
            

Property:
	PropertyName ':' AssignE { Left ($1, $3 ) }
      | ident FuncDecl2 { Right $ GetterPutter $1 $2 }


PropertyName : ident  { PropNameId $1 }
	     | string { PropNameStr $1 }
	     | int    { PropNameInt $1 }

MemberExpr :: { MemberExpr } 
	   : PrimExpr                { MemPrimExpr $1 }
  	   | MemberExpr '[' Expr ']' { ArrayExpr $1 $3 }
	   | MemberExpr '.' ident    { MemberCall $1 $3 }
           | new MemberExpr Arguments { MemberNew $2 $3 }

NewExpr : MemberExpr            { MemberExpr $1 }
    |  new NewExpr              { NewNewExpr $2 }

CallExpr : MemberExpr Arguments  { CallMember $1 $2 }
    |      CallExpr Arguments    { CallCall $1 $2 }
    |      CallExpr '[' Expr ']' { CallSquare $1 $3 }
    |      CallExpr '.' ident    { CallDot $1 $3 }

Arguments : '(' ')'              { [] }
    |'(' ArgumentList ')'        { $2 }

ArgumentList : AssignE           { [$1] }
    |          ArgumentList ',' AssignE { $1 ++ [$3] }

LeftExpr : NewExpr              { NewExpr $1 }
    | CallExpr                  { CallExpr $1 }

PostFix : LeftExpr             { LeftExpr $1 }
 |         LeftExpr '++'          { PostInc $1 }
 |         LeftExpr '--'          { PostDec $1 }

UExpr :
      PostFix                    { PostFix $1 }
    | delete UExpr    { Delete $2 }
    | void   UExpr    { Void   $2 }
    | typeof UExpr    { TypeOf $2 }
    | '++' UExpr      { DoublePlus $2 }
    | '--' UExpr      { DoubleMinus $2 }
    | '+' UExpr       { UnaryPlus $2 }
    | '-' UExpr       { UnaryMinus $2 }
    | '!' UExpr       { Not $2 }
    | '~' UExpr       { BitNot $2 }

{-
MultExpr2 : MultExpr {% do 
                            st <- get
                            put st { expectRegex = False }
                            return $1 
                      }


DivOp : '/' {% do
                  st <- get
                  throwError (show st)
                  put st { expectRegex = True }
                  return ()
            }

-}


MultExpr : UExpr                {UExpr $1 }
       | MultExpr '*' UExpr     { Times $1 $3 }
       | MultExpr '/' UExpr    {Div $1 $3 }
       | MultExpr '%' UExpr     { Mod $1 $3 }


AddExpr  : MultExpr { MultExpr $1 }
    | AddExpr '+' MultExpr { Plus $1 $3 }
    | AddExpr '-' MultExpr { Minus $1 $3 }

ShiftE : AddExpr { AddExpr $1 }
      | ShiftE '<<' AddExpr { ShiftLeft $1 $3 }
      | ShiftE '>>' AddExpr { ShiftRight $1 $3 }
      | ShiftE '>>>' AddExpr {ShiftRight2 $1 $3 }

RelE : ShiftE { ShiftE $1 }
    | RelE '<' ShiftE  {  LessThan $1 $3 }
    | RelE '>' ShiftE  {  GreaterThan $1 $3 }
    | RelE '<=' ShiftE  {  LessEqual $1 $3 }
    | RelE '>=' ShiftE  {  GreaterEqual $1 $3 }
    | RelE instanceof ShiftE  {  InstanceOf $1 $3 }
    | RelE in ShiftE  {  InObject $1 $3 }  -- JavaScript 1.4



EqualE : RelE { RelE $1 }
       | EqualE  '==' RelE { Equal $1 $3 }
       | EqualE  '!=' RelE { NotEqual $1 $3 }
       | EqualE  '===' RelE { Equal2 $1 $3 }
       | EqualE  '!==' RelE { NotEqual $1 $3 }


BitAnd : EqualE { EqualE $1 }
       | BitAnd '&' EqualE { BABitAnd $1 $3 }

BitXOR :  BitAnd { BitAnd $1 }
       | BitXOR '^' BitAnd { BXBitXOR $1 $3 }

BitOR : BitXOR { BitXOR $1 }
      | BitOR '|' BitXOR { BOBitOR $1 $3 }

LogAnd : BitOR { BitOR $1  }
       | LogAnd '&&' BitOR { LALogAnd $1 $3 }

LogOr : LogAnd { LogAnd $1 }
      | LogOr '||' LogAnd { LOLogOr $1 $3 }

CondE : LogOr { LogOr $1 }
     |  LogOr '?' AssignE ':' AssignE  { CondIf $1 $3 $5 }

AssignOp : '*='            { AssignOpMult }
      | '/='               { AssignOpDiv }
      | '%='               { AssignOpMod }
      | '+='               { AssignOpPlus }
      | '-='               { AssignOpMinus }
      | '='                { AssignNormal }

--  CondE                     { CondE  $1 }

AssignE :
           LeftExpr AssignOp AssignE      { Assign $1 $2 $3 }
	 | CondE                          { CondE  $1 }
         | FuncDecl                       { AEFuncDecl $1 } -- Not In spec.

Expr : AssignE  { AssignE $1 }

--
-- A.4 Statements
--

Stmt :  
        Block      { Block $1 }
    |   VarStmt    { VarStmt $1 }
    |   ';'        { EmptyStmt }
    |   ExprStmt   { ExprStmt $1 }
    |	IfStmt     { IfStmt $1}
    |   ItStmt     { ItStmt $1 }
    |   continue ident ';' { ContStmt $ Just $2 }
    |   continue ';' { ContStmt Nothing }
    |   break ident ';'     { BreakStmt $ Just $2 }
    |   break ';'     { BreakStmt Nothing }
    |   return ExprSemi ';' { ReturnStmt $ Just $2 }
    |   return  ';' { ReturnStmt Nothing }
    |   with '(' Expr ')' Stmt   { WithStmt $3 $5 }
    |   ident ':' Stmt  { LabelledStmt $1 $3 }
    |   SwitchStmt      { Switch $1 }
    |   throw ExprSemi ';' { ThrowExpr $2 }
    |   TryStmt    { TryStmt $1 }

Block : '{' StmtList '}' { $2 }


StmtList  : {- empty -} { [] }
    | Stmt  { [$1] }
    | StmtList Stmt { $1 ++ [$2] }

VarStmt : var VarDeclList { $2 }
	| const VarDeclList { $2 }  -- No mention of usage of const in spec. Is it same as 'var' or just a no-op?



TryStmt : try Block CatchList { TryBC $2 $3 }
	| try Block Finally { TryBF $2 $3 }
	| try Block CatchList Finally { TryBCF $2 $3 $4 }

CatchList : Catch { [$1] }
	  | CatchList Catch { $1 ++ [$2 ] }

Catch : catch '(' ident ')' Block            { Catch $3 $5 }
      | catch '(' ident if Expr ')' Block  { CatchIf $3 $7 $5}  -- JS 1.5

Finally : finally Block { $2 }

ExprSemi : Expr {%% \t -> autoSemiInsert t $1 } 


ExprStmt : ExprSemi ';' { $1 }

IfStmt : if '(' Expr ')' Stmt else Stmt { IfElse $3 $5 $7 }
       | if '(' Expr ')' Stmt           { IfOnly $3 $5 }

ItStmt :
          do Stmt while '(' Expr ')' ';'           { DoWhile $2 $5    }
       | while '(' Expr ')' Stmt                   { While $3 $5      }
       | for '(' ExprOpt ';' ExprOpt ';' ExprOpt ')' Stmt   { For $3 $5 $7 $9  } 
       | for '(' var VarDeclList ';' ExprOpt ';' ExprOpt ')' Stmt   { ForVar $4 $6 $8 $10  } 
       | for '('     VarDeclList ';' ExprOpt ';' ExprOpt ')' Stmt   { ForVar $3 $5 $7 $9  } 
       | for '(' var VarDeclList in Expr  ')' Stmt   { ForIn $4 $6 $8  } 
       | for '('     VarDeclList in Expr  ')' Stmt   { ForIn $3 $5 $7  }


ExprOpt : {- empty -} { Nothing } -- Change to OptExpression and change exprOpt to optExpression in parser
    | Expr { Just $1 }

VarDeclList : VarDecl    { [$1] }
    |         VarDeclList ',' VarDecl { $1 ++ [$3] }

VarDecl : ident Initialiser { VarDecl $1 $2 }

Initialiser : {- empty -} { Nothing }
    | '=' AssignE { Just $2 }


SwitchStmt : switch '(' Expr ')' CaseBlock { SSwitch $3 $5 }

CaseBlock : '{' CaseClauses '}'                     { CaseBlock $2 [] [] }
    | '{' CaseClauses DefaultClause CaseClauses '}' { CaseBlock $2 [$3] $4 }

CaseClauses : {- empty -} { [] }
    | CaseClause          { [$1] }
    | CaseClauses CaseClause { $1 ++ [$2] }

CaseClause : case Expr ':' StmtList { CaseClause $2 $4 }

DefaultClause : default ':' StmtList { DefaultClause $3 }

--
-- A.5 Function and Programs
--


FuncDecl : 
	 function FuncDecl2 { $2 }
       | function  '(' FormalParamList ')' '{' FuncBody '}' { FuncDecl Nothing $3 $6 }

FuncDecl2 : ident '(' FormalParamList ')' '{' FuncBody '}' { FuncDecl (Just $1) $3 $6 }


FormalParamList : {- empty -} { [] }
    | ident                      { [ $1 ] }
    | FormalParamList ',' ident  { $1 ++ [$3] }

FuncBody : SourceElements { $1 }

Program : SourceElements { JSProgram $1 }

SourceElements : SourceElement { [$1] }
    | SourceElements SourceElement { $1 ++ [$2] }

SourceElement : Stmt  { Stmt $1 }
    | FuncDecl { SEFuncDecl $1 }


{

main = getContents >>= print . jsprogram . lexer

parseError :: Token -> P a
parseError tok = do 
                  s <- get
   	          throwError ("parse error" ++ " tok = " ++ show tok ++ " rest=<" ++ (rest s) ++ "> lnum = " ++ show (lineno s) ++ " mode= " ++ show (mode s) ++ show (tr s))

}
