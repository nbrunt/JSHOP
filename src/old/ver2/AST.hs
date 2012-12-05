{-
******************************************************************************
*                                      JSHOP                                 *
*                                                                            *
*   Module:   AST                                                            *
*   Purpose:  JavaScript Abstract Syntax Tree                                *
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

-- | JavaScript Abstract Syntax Tree. Representation of JavaScript programs
-- after parsing.

module AST where

    {-
    AST (..),         -- Not abstract. Instances: HasSrcPos.
    Command (..),     -- Not abstract. Instances: HasSrcPos.
    Expression (..),  -- Not abstract. Instances: HasSrcPos.
    Declaration (..), -- Not abstract. Instances: HasSrcPos.
    TypeDenoter (..)  -- Not abstract. Instances: HasSrcPos.
    -}


-- JSHOP module imports
--import Name
--import SrcPos

-- Note on Naming Conventions for Constructors and Field Labels
--
-- In Haskell, two (or more) datatypes that are in scope simultaneoulsy
-- must not have any constructors or field labels in common. However,
-- different constructors of the same type may have common field names,
-- provided the fields all have the same type. This is very different
-- from records in languages like Pascal or C, and from objects in OO
-- languages like Java, where sharing names across different records or
-- objects are both possible and common.
--
-- To avoid name clashes, while still making it possible to use similar
-- names for similar things in different type declarations, some simple
-- naming conventins have been adopted:
--
--   * Constructors get prefix which is an abbreviation of the name of
--     the data type. E.g. for 'Command', the prefix is 'Cmd', and a
--     typical constructor name is 'CmdAssign', and for 'TypeDenoter',
--     te prefix is 'TD'.
--
--   * Field names that are common to one or more constructors, get the
--     same prefix as the constructor, but in lower-case.
--
--   * Field names that are specific to a contructor get a lower-case
--     prefix that is an abbreviation of the constructor. E.g. the
--     prefix for 'CmdAssign' is 'ca', and one of its fields is 'caVar'.

-- | Abstract syntax for the syntactic category Program
--data AST = AST { astCmd :: Command }


data Program
    = Program       [Source]
    deriving Show
    
data Source
    = Statement     Statement
    | SFuncDecl     FuncDecl 
    deriving Show
    
data FuncDecl
    = FuncDecl      (Maybe String) [String] [Source]
    deriving Show
    
data Statement
    = EmptyStmt
    | IfStmt        IfStmt
    | IterativeStmt IterativeStmt
    | ExprStmt      Expression
    | Block         [Statement]
    | VarStmt       [VarDecl]
    | TryStmt       TryStmt
    | ContinueStmt  (Maybe String)
    | BreakStmt     (Maybe String)
    | ReturnStmt    (Maybe Expression)
    | WithStmt      Expression Statement
    | LabelledStmt  String Statement
    | Switch        Switch
    | ThrowExpr     Expression
    deriving Show
    
data IfStmt
    = IfElse        Expression Statement Statement
    | If            Expression Statement
--    | If2           Expression
--    | If3
    deriving Show

data IterativeStmt
    = DoWhile       Statement Expression 
    | While         Expression Statement
    | For           (Maybe Expression) (Maybe Expression) (Maybe Expression) Statement 
    | ForVar        [VarDecl] (Maybe Expression) (Maybe Expression) Statement 
    | ForIn         [VarDecl] Expression Statement 
--    | It2           Expression 
    deriving Show

data TryStmt
    = TryBC         [Statement] [Catch]
    | TryBF         [Statement] [Statement]
    | TryBCF        [Statement] [Catch] [Statement]
    deriving Show
    
data Catch
    = Catch         String [Statement]
    | CatchIf       String [Statement] Expression
    deriving Show
    
data Switch
    = SSwitch       Expression CaseBlock
    deriving Show
    
data CaseBlock
    = CaseBlock     [CaseClause] [DefaultClause] [CaseClause]
    deriving Show
    
data CaseClause
    = CaseClause    Expression [Statement]
    deriving Show
    
data DefaultClause
    = DefaultClause [Statement]
    deriving Show
    
data Expression
    = Assignment    Assignment 
    deriving Show
    
data VarDecl
    = VarDecl       String (Maybe Assignment)
    deriving Show
    
-- | Abstract syntax for the syntactic category Assignment
data Assignment
    = CondExpr        CondExpr
    | Assign          LeftExpr AssignOp Assignment 
    | AssignFuncDecl  FuncDecl
    deriving Show
    
data LeftExpr
    = NewExpr       NewExpr 
    | CallExpr      CallExpr
    deriving Show
    
data AssignOp
    = AssignNormal
    | AssignOpMult 
    | AssignOpDiv
    | AssignOpMod
    | AssignOpPlus 
    | AssignOpMinus
    deriving Show
    
data CondExpr
    = LogOr         LogOr 
    | CondIf        LogOr Assignment Assignment
    deriving Show
    
data NewExpr
    = MemberExpr    MemberExpr 
    | NewNewExpr    NewExpr
    deriving Show
    
data CallExpr
    = CallMember    MemberExpr [Assignment]
    | CallCall      CallExpr [Assignment]
    | CallSquare    CallExpr Expression
    | CallDot       CallExpr String
    deriving Show
    
data MemberExpr
    = MemExpression PrimaryExpr 
    | ArrayExpr     MemberExpr Expression
    | MemberNew     MemberExpr [Assignment]      
		| MemberCall    MemberExpr String
		deriving Show
    
-- | Abstract syntax for the syntactic category PrimaryExpr
data PrimaryExpr
    -- | Literal integer
    = ExpLitInt     Integer
    -- | Literal strings
    | ExpLitStr     String
    -- | Identifier
    | ExpId         String
    -- | Bracketed expression
    | ExpBrackExp   Expression
    -- | This (current object)
    | ExpThis
    -- | Regular PrimaryExpr
    | ExpRegex      String
    -- | Arrays
    | ExpArray      ArrayLit
    -- | Objects
    | ExpObject     [(PropName, Assignment)]
    deriving Show
    
-- | Abstract syntax for the syntactic category Array Literal
data ArrayLit
    -- | Simple array
    = ArraySimp     [Assignment]
    deriving Show

data PropName
    = PropNameId    String
    | PropNameStr   String
    | PropNameInt   Integer
	  deriving Show
    
data LogOr
    = LogAnd        LogAnd 
	  | LOLogOr       LogOr LogAnd
	  deriving Show
    
data LogAnd
    = BitOR         BitOR 
	  | LALogAnd      LogAnd BitOR
	  deriving Show
    
data BitOR
    = BitXOR        BitXOR
	  | BOBitOR       BitOR BitXOR
	  deriving Show
    
data BitXOR
    = BitAnd        BitAnd 
	  | BXBitXOR      BitXOR BitAnd
	  deriving Show
    
data BitAnd
    = EqualExpr     EqualExpr 
	  | BABitAnd      BitAnd EqualExpr
	  deriving Show
    
data EqualExpr
    = RelExpr       RelExpr
	  | Equal         EqualExpr RelExpr
	  | NotEqual      EqualExpr RelExpr
	  | EqualTo       EqualExpr RelExpr
	  | NotEqualTo    EqualExpr RelExpr
    deriving Show
    
data RelExpr
    = ShiftExpr     ShiftExpr 
	  | LessThan      RelExpr ShiftExpr
	  | GreaterThan   RelExpr ShiftExpr
	  | LessEqual     RelExpr ShiftExpr
	  | GreaterEqual  RelExpr ShiftExpr
	  | InstanceOf    RelExpr ShiftExpr
	  | InObject      RelExpr ShiftExpr 
	  deriving Show

data ShiftExpr
    = AddExpr       AddExpr 
	  | ShiftLeft     ShiftExpr AddExpr
	  | ShiftRight    ShiftExpr AddExpr
	  | ShiftRight2   ShiftExpr AddExpr
	  deriving Show
    
data AddExpr
    = MultExpr      MultExpr 
    | Plus          AddExpr MultExpr
    | Minus         AddExpr MultExpr
    deriving Show
    
data MultExpr
    = UnaryExpr     UnaryExpr
    | Times         MultExpr UnaryExpr
    | Div           MultExpr UnaryExpr 
    | Mod           MultExpr UnaryExpr
    deriving Show
    
data UnaryExpr
    = PostFix       PostFix
    | Delete        UnaryExpr
    | Void          UnaryExpr
    | TypeOf        UnaryExpr
    | PlusPlus      UnaryExpr 
    | MinusMinus    UnaryExpr 
    | UnaryPlus     UnaryExpr
    | UnaryMinus    UnaryExpr
    | Not           UnaryExpr
    | BitNot        UnaryExpr
    deriving Show
    
data PostFix
    = LeftExpr      LeftExpr
	  | PostInc       LeftExpr
	  | PostDec       LeftExpr
	  deriving Show

{-
instance HasSrcPos AST where
    srcPos = cmdSrcPos . astCmd
-}

-- | Abstract syntax for the syntactic category Command

-- For generality, the variable being assigned to, the procedure being
-- called, and the function being applied (currently only operators) are
-- represented by expressions as opposed to just an identifier (for
-- variables, procedures, and functions) or an operator. Consider
-- assignment to an array element, for example, where the RHS (e.g. x[i])
-- really is an expression that gets evaluated to a memory reference
-- (sink). Also, this arrangement facilitates error reporting, as a
-- variable expression has an associated source position, whereas names,
-- currently represented by strings, have not.
{- 
data Command
   -- | Assignment
    = CmdAssign {
          caVar     :: PrimaryExpr,    -- ^ Assigned variable
          caVal     :: PrimaryExpr,    -- ^ Right-hand-side expression
          cmdSrcPos :: SrcPos
      }
    -- | Procedure call
    | CmdCall {
          ccProc    :: PrimaryExpr,    -- ^ Called procedure
          ccArgs    :: [PrimaryExpr],  -- ^ Arguments
          cmdSrcPos :: SrcPos
      }
    -- | Command sequence (block)
    | CmdSeq {
          csCmds    :: [Command],     -- ^ Commands
          cmdSrcPos :: SrcPos
      }
{- Original version
    -- | Conditional command
    | CmdIf {
          ciCond    :: PrimaryExpr, -- ^ Condition
          ciThen    :: Command,    -- ^ Then-branch
          ciElse    :: Command,    -- ^ Else-branch
          cmdSrcPos :: SrcPos
      }
-}
    -- Extended version
    | CmdIf {
          ciCondThens :: [(PrimaryExpr, [Command])], -- ^ Conditional branches
          ciElse      :: [Command],                 -- ^ Optional else-branch
          cmdSrcPos   :: SrcPos
      }
    -- | While-loop
    | CmdWhile {
          cwCond    :: PrimaryExpr,      -- ^ Loop-condition
          cwBody    :: Command,         -- ^ Loop-body
          cmdSrcPos :: SrcPos
      }
    -- | Repeat-loop
{-    | CmdRepeat {
          crBody    :: Command,         -- ^ Loop-body
          crCond    :: PrimaryExpr,      -- ^ Loop-condition
          cmdSrcPos :: SrcPos
      }
-}
{-
    -- | Let-command
    | CmdLet {
          clDecls   :: [Declaration],   -- ^ Declarations
          clBody    :: Command,         -- ^ Let-body
          cmdSrcPos :: SrcPos
      }
-}
-}

{-
instance HasSrcPos Command where
    srcPos = cmdSrcPos
-}

{-
    -- | Variable reference
    | ExpVar {
          evVar     :: Name,          -- ^ Name of referenced variable
          expSrcPos :: SrcPos
      }
    -- | Function or n-ary operator application
    | ExpApp {
          eaFun     :: PrimaryExpr,    -- ^ Applied function or operator
          eaArgs    :: [PrimaryExpr],  -- ^ Arguments
          expSrcPos :: SrcPos
      }
    -- | Conditional expression
    | ExpCond {
          ecCond    :: PrimaryExpr,    -- ^ Condition
          ecTrue    :: PrimaryExpr,    -- ^ Value if condition true
          ecFalse   :: PrimaryExpr,    -- ^ Value if condition false
          expSrcPos :: SrcPos
      }
-}

{-
instance HasSrcPos PrimaryExpr where
    srcPos = expSrcPos
-}

-- | Abstract syntax for the syntactic category Declaration
--data Declaration
{-
{-
    -- | Constant declaration
    = DeclConst {
          dcConst    :: Name,         -- ^ Name of defined constant
          dcType     :: TypeDenoter,  -- ^ Type of defined constant
          dcVal      :: PrimaryExpr,   -- ^ Value of defined constant
          declSrcPos :: SrcPos
      }
-}
    -- | Variable declaration
    = DeclVar {
          dvVar       :: Name,            -- ^ Name of declared variable
          dvType     :: TypeDenoter,      -- ^ Type of declared variable
          dvMbVal    :: Maybe PrimaryExpr, -- ^ Initial value of declared
                                          -- varible, if any
          declSrcPos :: SrcPos
      }
-}

{-
instance HasSrcPos Declaration where
    srcPos = declSrcPos
-}

-- | Abstract syntax for the syntactic category TypeDenoter

-- Right now, the only types are simple base types like Integer and Bool.
-- If MiniTriangle were extended to allow users to express e.g. function
-- types, then this data declaration would have to be extended.
--data TypeDenoter
{-
    -- | Base Type
    = TDBaseType {
          tdbtName :: Name,  -- ^ Name of the base type
          tdSrcPos :: SrcPos
      }
-}

{-
instance HasSrcPos TypeDenoter where
    srcPos = tdSrcPos
-}