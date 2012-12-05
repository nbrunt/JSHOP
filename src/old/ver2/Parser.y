-- ******************************************************************************
-- *                                      JSHOP                                 *
-- *                                                                            *
-- *   Module:   Parser                                                         *
-- *   Purpose:  JavaScript Parser                                              *
-- *   Authors:  Nick Brunt, Henrik Nilsson                                     *
-- *                                                                            *
-- *                       Based on the HMTC equivalent                         *
-- *                 Copyright (c) Henrik Nilsson, 2006 - 2011                  *
-- *                      http://www.cs.nott.ac.uk/~nhn/                        *
-- *                                                                            *
-- *                         Revisions for JavaScript                           *
-- *                    Copyright (c) Nick Brunt, 2011 - 2012                   *
-- *                                                                            *
-- ******************************************************************************

{
-- | JavaScript parser

module Parser where

-- JSHOP module imports
import Token
import Lexer
import LexerMonad
import AST
import ParseMonad

--import SrcPos
--import Diagnostics
--import Name


--import PPAST

import Data.Char
import Control.Monad.State
import Control.Monad.Error

}

%name       parse
%monad      { P }
%lexer      { monadicLexer } { EOF }
%tokentype  { Token }
%error      { parseError }

%token
    LITINT      { LitInt $$ }
    LITSTR      { LitStr $$ }
    ID          { Id $$ }
    REGEX       { Regex $$ }
    BREAK       { ResId {ridName="break"} }
    CASE        { ResId {ridName="case"} }
    CATCH       { ResId {ridName="catch"} }
    CONTINUE    { ResId {ridName="continue"} }
    DEFAULT     { ResId {ridName="default"} }
    DELETE      { ResId {ridName="delete"} }
    DO          { ResId {ridName="do"} }
    ELSE        { ResId {ridName="else"} }
    FALSE       { ResId {ridName="false"} }
    FINALLY     { ResId {ridName="finally"} }
    FOR         { ResId {ridName="for"} }
    FUNCTION    { ResId {ridName="function"} }
    IF          { ResId {ridName="if"} }
    IN          { ResId {ridName="in"} }
    INSTANCEOF  { ResId {ridName="instanceof"} }
    NEW         { ResId {ridName="new"} }
    NULL        { ResId {ridName="null"} }
    RETURN      { ResId {ridName="return"} }
    SWITCH      { ResId {ridName="switch"} }
    THIS        { ResId {ridName="this"} }
    THROW       { ResId {ridName="throw"} }
    TRUE        { ResId {ridName="true"} }
    TRY         { ResId {ridName="try"} }
    TYPEOF      { ResId {ridName="typeof"} }
    VAR         { ResId {ridName="var"} }
    VOID        { ResId {ridName="void"} }
    WHILE       { ResId {ridName="while"} }
    WITH        { ResId {ridName="with"} }
    '.'         { ResOp {ropName="."} }
    '['         { ResOp {ropName="["} }
    ']'         { ResOp {ropName="]"} }
    '('         { ResOp {ropName="("} }
    ')'         { ResOp {ropName=")"} }
    '++'        { ResOp {ropName="++"} }
    '--'        { ResOp {ropName="--"} }
    '-'         { ResOp {ropName="-"} }
    '+'         { ResOp {ropName="+"} }
    '~'         { ResOp {ropName="~"} }
    '!'         { ResOp {ropName="!"} }
    '*'         { ResOp {ropName="*"} }
    '/'         { ResOp {ropName="/"} }
    '%'         { ResOp {ropName="%"} }
    '<<'        { ResOp {ropName="<<"} }
    '>>'        { ResOp {ropName=">>"} }
    '>>>'       { ResOp {ropName=">>>"} }
    '<'         { ResOp {ropName="<"} }
    '<='        { ResOp {ropName="<="} }
    '>'         { ResOp {ropName=">"} }
    '>='        { ResOp {ropName=">="} }
    '=='        { ResOp {ropName="=="} }
    '!='        { ResOp {ropName="!="} }
    '==='       { ResOp {ropName="==="} }
    '!=='       { ResOp {ropName="!=="} }
    '&'         { ResOp {ropName="&"} }
    '^'         { ResOp {ropName="^"} }
    '|'         { ResOp {ropName="|"} }
    '&&'        { ResOp {ropName="&&"} }
    '||'        { ResOp {ropName="||"} }
    '?'         { ResOp {ropName="?"} }
    ':'         { ResOp {ropName=":"} }
    '='         { ResOp {ropName="="} }
    '*='        { ResOp {ropName="*="} }
    '+='        { ResOp {ropName="+="} }
    '-='        { ResOp {ropName="-="} }
    '/='        { ResOp {ropName="/="} }
    '%='        { ResOp {ropName="%="} }
    ','         { ResOp {ropName=","} }
    ';'         { ResOp {ropName=";"} }
    '{'         { ResOp {ropName="{"} }
    '}'         { ResOp {ropName="}"} }
    OTHER       { Other $$ }
    EOF         { EOF }
    
%%

-- Basic structure of a JS program

program :: { Program }
    : sources { Program $1 }

sources :: { [Source] }
    : source         { [$1] }
    | sources source { $1 ++ [$2] }

-- Possible source elements
source :: { Source }
    : statement { Statement $1 }
    | funcDecl  { SFuncDecl $1 }

funcDecl :: { FuncDecl }
    : FUNCTION funcDecl2
        { $2 }
    | FUNCTION '(' formalParamList ')' '{' funcBody '}'
        { FuncDecl Nothing $3 $6 }
    
funcDecl2 :: { FuncDecl }
    : ID '(' formalParamList ')' '{' funcBody '}'
        { FuncDecl (Just $1) $3 $6 }
    
formalParamList :: { [String] }
    : {- epsilon -} { [] }
    | ID            { [ $1 ] }
    | formalParamList ',' ID
        { $1 ++ [$3] }
    
funcBody :: { [Source] }
    : sources { $1 }


-- Grammar

statement :: { Statement }
    : ';'           { EmptyStmt }
    | ifStmt        { IfStmt $1}
    | iterativeStmt { IterativeStmt $1 }
    | exprStmt      { ExprStmt $1 }
    | block         { Block $1 }
    | varStmt       { VarStmt $1 }
    | tryStmt       { TryStmt $1 }
    | switchStmt    { Switch $1 }
    | CONTINUE ID ';'
        { ContinueStmt (Just $2) }
    | CONTINUE ';'
        { ContinueStmt Nothing }
    | BREAK ID ';'
        { BreakStmt (Just $2) }
    | BREAK ';'
        { BreakStmt Nothing }
    | RETURN exprSemi ';'
        { ReturnStmt (Just $2) }
    | RETURN ';'
        { ReturnStmt Nothing }
    | WITH '(' expression ')' statement
        { WithStmt $3 $5 }
    | ID ':' statement
        { LabelledStmt $1 $3 }
    | THROW exprSemi ';'
        { ThrowExpr $2 }

ifStmt :: { IfStmt }
    : IF '(' expression ')' statement ELSE statement
        { IfElse $3 $5 $7 }
    | IF '(' expression ')' statement
        { If $3 $5 }
        
iterativeStmt :: { IterativeStmt }
    : DO statement WHILE '(' expression ')' ';'
        { DoWhile $2 $5 }
    | WHILE '(' expression ')' statement
        { While $3 $5 }
    | FOR '(' optExpression ';' optExpression ';' optExpression ')' statement
        { For $3 $5 $7 $9 } 
    | FOR '(' VAR varDeclList ';' optExpression ';' optExpression ')' statement
        { ForVar $4 $6 $8 $10 } 
    | FOR '(' varDeclList ';' optExpression ';' optExpression ')' statement
        { ForVar $3 $5 $7 $9 } 
    | FOR '(' VAR varDeclList IN expression ')' statement
        { ForIn $4 $6 $8 } 
    | FOR '(' varDeclList IN expression ')' statement
        { ForIn $3 $5 $7 }
        
exprStmt :: { Expression }
    : exprSemi ';' { $1 }
    
exprSemi :: { Expression }
    : expression {%% \t -> autoSemiInsert t $1 }
    
block :: { [Statement] }
    : '{' stmtList '}' { $2 }
    
stmtList :: { [Statement] }
    : {- epsilon -} { [] }
    | statement { [$1] }
    | stmtList statement { $1 ++ [$2] }

varStmt :: { [VarDecl] }
    : VAR varDeclList { $2 }
  
tryStmt :: { TryStmt }
    : TRY block catchList
        { TryBC $2 $3 }
    | TRY block finally
        { TryBF $2 $3 }
    | TRY block catchList finally
        { TryBCF $2 $3 $4 }
        
catchList :: { [Catch] }
    : catch           { [$1] }
    | catchList catch { $1 ++ [$2 ] }

catch :: { Catch }
    : CATCH '(' ID ')' block
        { Catch $3 $5 }
    | CATCH '(' ID IF expression ')' block
        { CatchIf $3 $7 $5}
        
finally :: { [Statement] }
    : FINALLY block { $2 }
  
switchStmt :: { Switch }
    : SWITCH '(' expression ')' caseBlock
        { SSwitch $3 $5 }
    
caseBlock :: { CaseBlock }
    : '{' caseClauses '}'
        { CaseBlock $2 [] [] }
    | '{' caseClauses defaultClause caseClauses '}'
        { CaseBlock $2 [$3] $4 }

caseClauses :: { [CaseClause] }
    : {- epsilon -}           { [] }
    | caseClause              { [$1] }
    | caseClauses caseClause  { $1 ++ [$2] }

caseClause :: { CaseClause }
    : CASE expression ':' stmtList
        { CaseClause $2 $4 }

defaultClause :: { DefaultClause }
    : DEFAULT ':' stmtList
        { DefaultClause $3 }

expression :: { Expression }
    : assignment { Assignment $1 }

optExpression :: { Maybe Expression }
    : {- epsilon -} { Nothing }
    | expression    { Just $1 }
    
varDeclList :: { [VarDecl] }
    : varDecl { [$1] }
    | varDeclList ',' varDecl
        { $1 ++ [$3] }

varDecl :: { VarDecl }
    : ID initialiser { VarDecl $1 $2 }

initialiser :: { Maybe Assignment }
    : {- epsilon -}  { Nothing }
    | '=' assignment { Just $2 }
    
assignment :: { Assignment }
    : leftExpr assignOp assignment
        { Assign $1 $2 $3 }
	  | condExpr { CondExpr  $1 }
    | funcDecl { AssignFuncDecl $1 }
    
leftExpr :: { LeftExpr }
    : newExpr  { NewExpr $1 }
    | callExpr { CallExpr $1 }
  
assignOp :: { AssignOp }
    : '*='  { AssignOpMult }
    | '/='  { AssignOpDiv }
    | '%='  { AssignOpMod }
    | '+='  { AssignOpPlus }
    | '-='  { AssignOpMinus }
    | '='   { AssignNormal }
    
condExpr :: { CondExpr }
    : logOr { LogOr $1 }
    | logOr '?' assignment ':' assignment
        { CondIf $1 $3 $5 }
        
newExpr :: { NewExpr }
    : memberExpr  { MemberExpr $1 }
    | NEW newExpr { NewNewExpr $2 }
    
callExpr :: { CallExpr }
    : memberExpr arguments
        { CallMember $1 $2 }
    | callExpr arguments
        { CallCall $1 $2 }
    | callExpr '[' expression ']'
        { CallSquare $1 $3 }
    | callExpr '.' ID
        { CallDot $1 $3 }
        
memberExpr :: { MemberExpr } 
    : primaryExpr
        { MemExpression $1 }
    | memberExpr '[' expression ']'
        { ArrayExpr $1 $3 }
    | memberExpr '.' ID
        { MemberCall $1 $3 }
    | NEW memberExpr arguments
        { MemberNew $2 $3 }
        
arguments :: { [Assignment] }
    : '(' ')'  { [] }
    | '(' argumentList ')'
        { $2 }

argumentList :: { [Assignment] }
    : assignment  { [$1] }
    | argumentList ',' assignment
        { $1 ++ [$3] }
        
primaryExpr :: { PrimaryExpr }
    : LITINT          { ExpLitInt $1 }
    | LITSTR          { ExpLitStr $1 }
    | ID              { ExpId $1 }
    | THIS            { ExpThis }
    | regex           { ExpRegex $1 }
    | arrayLit        { ExpArray $1 }
    | objectLit       { ExpObject $1 }
    | '(' expression ')'
        { ExpBrackExp $2 }
        
regex :: { String }
    : regexStart REGEX { $2 }
    
{- Not exactly sure why putting %% works but it is important. 
   If not then it will lookahead using the normal lexer 
   and fail. I think %% discards this lookedahead to give 
   us a chance to switch the lexer. Also need to run 
   happy with -a option -}
regexStart :: { String }
    : '/' { "Test" } -- %% lexRegex }

{-regexEnd :: { String }
    : '/' {} -}
    
arrayLit :: { ArrayLit }
    : '[' elementList ']'
        { ArraySimp $2 }
      
elementList :: { [Assignment] }
    : {- epsilon -} { [] }
    | assignment    { [$1] }
    | elementList ',' assignment
        { $1 ++ [$3]}
      
objectLit :: { [(PropName, Assignment)] }
    : '{' '}' { [] }
	  | '{' propertyList '}' { $2 }
    
propertyList :: { [(PropName, Assignment)] }
    : property { [$1] }
    | propertyList ',' property { $1 ++ [$3] }

property :: { (PropName, Assignment) }
    : propertyName ':' assignment
        { ($1, $3) }

propertyName :: { PropName }
    : ID      { PropNameId $1 }
	  | LITSTR  { PropNameStr $1 }
    | LITINT  { PropNameInt $1 }

logOr :: { LogOr }
    : logAnd { LogAnd $1 }
    | logOr '||' logAnd
        { LOLogOr $1 $3 }
        
logAnd :: { LogAnd }
    : bitOR { BitOR $1 }
    | logAnd '&&' bitOR
        { LALogAnd $1 $3 }
        
bitOR :: { BitOR }
    : bitXOR { BitXOR $1 }
    | bitOR '|' bitXOR
        { BOBitOR $1 $3 }
        
bitXOR :: { BitXOR }
    : bitAnd { BitAnd $1 }
    | bitXOR '^' bitAnd
        { BXBitXOR $1 $3 }
        
bitAnd :: { BitAnd }
    : equalExpr { EqualExpr $1 }
    | bitAnd '&' equalExpr
        { BABitAnd $1 $3 }
        
equalExpr :: { EqualExpr }
    : relExpr { RelExpr $1 }
    | equalExpr '==' relExpr
        { Equal $1 $3 }
    | equalExpr '!=' relExpr
        { NotEqual $1 $3 }
    | equalExpr '===' relExpr
        { EqualTo $1 $3 }
    | equalExpr '!==' relExpr
        { NotEqualTo $1 $3 }
        
relExpr :: { RelExpr }
    : shiftExpr { ShiftExpr $1 }
    | relExpr '<' shiftExpr
        { LessThan $1 $3 }
    | relExpr '>' shiftExpr
        { GreaterThan $1 $3 }
    | relExpr '<=' shiftExpr
        { LessEqual $1 $3 }
    | relExpr '>=' shiftExpr
        { GreaterEqual $1 $3 }
    | relExpr INSTANCEOF shiftExpr
        { InstanceOf $1 $3 }
    | relExpr IN shiftExpr
        { InObject $1 $3 }
        
shiftExpr :: { ShiftExpr }
    : addExpr { AddExpr $1 }
    | shiftExpr '<<' addExpr
        { ShiftLeft $1 $3 }
    | shiftExpr '>>' addExpr
        { ShiftRight $1 $3 }
    | shiftExpr '>>>' addExpr
        { ShiftRight2 $1 $3 }
        
addExpr :: { AddExpr }
    : multExpr { MultExpr $1 }
    | addExpr '+' multExpr
        { Plus $1 $3 }
    | addExpr '-' multExpr
        { Minus $1 $3 }
        
multExpr :: { MultExpr }
    : unaryExpr { UnaryExpr $1 }
    | multExpr '*' unaryExpr
        { Times $1 $3 }
    | multExpr '/' unaryExpr
        {Div $1 $3 }
    | multExpr '%' unaryExpr
        { Mod $1 $3 }
       
unaryExpr :: { UnaryExpr }
    : postFix          { PostFix $1 }
    | DELETE unaryExpr { Delete $2 }
    | VOID unaryExpr   { Void   $2 }
    | TYPEOF unaryExpr { TypeOf $2 }
    | '++' unaryExpr   { PlusPlus $2 }
    | '--' unaryExpr   { MinusMinus $2 }
    | '+' unaryExpr    { UnaryPlus $2 }
    | '-' unaryExpr    { UnaryMinus $2 }
    | '!' unaryExpr    { Not $2 }
    | '~' unaryExpr    { BitNot $2 }
    
postFix :: { PostFix }
    : leftExpr      { LeftExpr $1 }
    | leftExpr '++' { PostInc $1 }
    | leftExpr '--' { PostDec $1 }
  
  
{

parseError :: Token -> P a
parseError tok = do 
                  s <- get
   	          throwError ("parse error" ++ " tok = " ++ show tok ++ " rest =< " ++ (rest s) ++ "> lnum = " ++ show (lineno s) ++ " mode = " ++ show (mode s) ++ show (tr s))


}