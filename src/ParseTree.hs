{-
******************************************************************************
*                                   JSHOP                                    *
*                                                                            *
*   Module:   ParseTree                                                      *
*   Purpose:  JavaScript Parse Tree                                          *
*   Author:   Nick Brunt                                                     *
*                                                                            *
*                    Copyright (c) Nick Brunt, 2011 - 2012                   *
*              Subject to MIT License as stated in root directory            *
*                                                                            *
*                           As defined in ECMA-262                           *
*                                                                            *
*                         Expressions - Page 40                              *
*                         Statements - Page 61                               *
*                         Function Definition - Page 71                      *
*                                                                            *
******************************************************************************
-}

-- | JavaScript Parse Tree. Representation of JavaScript programs after parsing.

module ParseTree where

-- | The Parse Tree is made up of a list of sources.
data Tree
    = Tree          [Source]
    deriving (Show, Eq)

-- | A source element can either be a statement or a function declaration.
data Source
    = Statement     Statement
    | SFuncDecl     FuncDecl
    deriving (Show, Eq)

-- | A function declation signature can contain a name and a list of args.
--   The body of the function is a list of sources.
data FuncDecl
    = FuncDecl      (Maybe String) [String] [Source]
    deriving (Show, Eq)

-- | A statement does not return a value and usually ends with a semicolon.
data Statement
    = EmptyStmt                             -- ^ A single semicolon
    | IfStmt        IfStmt                  -- ^ If statement
    | IterativeStmt IterativeStmt           -- ^ Iterative statement (while, for etc.)
    | ExprStmt      Expression              -- ^ Expression followed by a semicolon
    | Block         [Statement]             -- ^ List of statements ({...})
    | VarStmt       [VarDecl]               -- ^ Variable declaration (var ...)
    | TryStmt       TryStmt                 -- ^ Try catch finally
    | ContinueStmt  (Maybe String)          -- ^ Continue statement
    | BreakStmt     (Maybe String)          -- ^ Break statement
    | ReturnStmt    (Maybe Expression)      -- ^ Return statement
    | WithStmt      Expression Statement    -- ^ With statement
    | LabelledStmt  String Statement        -- ^ Labelled statement
    | Switch        Switch                  -- ^ Switch statement
    | ThrowExpr     Expression              -- ^ Throw an exception
    deriving (Show, Eq)

-- | An if statement with an optional else branch
data IfStmt
    = IfElse        Expression Statement Statement
    | If            Expression Statement
    deriving (Show, Eq)

-- | Itertive statements (loops)
data IterativeStmt
    = DoWhile       Statement Expression
    | While         Expression Statement
    | For           (Maybe Expression) (Maybe Expression) (Maybe Expression) Statement
    | ForVar        [VarDecl] (Maybe Expression) (Maybe Expression) Statement
    | ForIn         LeftExpr Expression Statement
    | ForVarIn      [VarDecl] Expression Statement
    deriving (Show, Eq)

-- | Try statement
data TryStmt
    = TryBC         [Statement] [Catch]
    | TryBF         [Statement] [Statement]
    | TryBCF        [Statement] [Catch] [Statement]
    deriving (Show, Eq)

-- | Catch
data Catch
    = Catch         String [Statement]
    | CatchIf       String [Statement] Expression
    deriving (Show, Eq)

-- | Switch statement
data Switch
    = SSwitch       Expression CaseBlock
    deriving (Show, Eq)

-- | A block of cases within a switch statement
data CaseBlock
    = CaseBlock     [CaseClause] [DefaultClause] [CaseClause]
    deriving (Show, Eq)

-- | An individual case clause
data CaseClause
    = CaseClause    Expression [Statement]
    deriving (Show, Eq)

-- | The default clause in a switch statement
data DefaultClause
    = DefaultClause [Statement]
    deriving (Show, Eq)

-- | An expression returns a value
data Expression
    = Assignment    [Assignment]
    deriving (Show, Eq)

-- | A variable declaration is made up of the identifier, and a possible assignment
data VarDecl
    = VarDecl       String (Maybe Assignment)
    deriving (Show, Eq)

-- | An assignment can be an expression or a function
data Assignment
    = CondExpr        CondExpr
    | Assign          LeftExpr AssignOp Assignment
    | AssignFuncDecl  FuncDecl
    deriving (Show, Eq)

-- | Left expression
data LeftExpr
    = NewExpr       NewExpr
    | CallExpr      CallExpr
    deriving (Show, Eq)

-- | Assignment operators
data AssignOp
    = AssignNormal
    | AssignOpMult
    | AssignOpDiv
    | AssignOpMod
    | AssignOpPlus
    | AssignOpMinus
    | AssignOpSLeft
    | AssignOpSRight
    | AssignOpSRight2
    | AssignOpAnd
    | AssignOpNot
    | AssignOpOr
    deriving (Show, Eq)

-- | Conditional expression (...?...:...)
data CondExpr
    = LogOr         LogOr
    | CondIf        LogOr Assignment Assignment
    deriving (Show, Eq)

-- | New expression
data NewExpr
    = MemberExpr    MemberExpr
    | NNewExpr      NewExpr
    deriving (Show, Eq)

-- | Call expression
data CallExpr
    = CallMember    MemberExpr [Assignment]
    | CallCall      CallExpr [Assignment]
    | CallSquare    CallExpr Expression
    | CallDot       CallExpr String
    deriving (Show, Eq)

-- | Member expression
data MemberExpr
    = MemExpression PrimaryExpr
    | FuncExpr      FuncDecl
    | ArrayExpr     MemberExpr Expression
    | MemberNew     MemberExpr [Assignment]
		| MemberCall    MemberExpr String
		deriving (Show, Eq)

-- | Primary expressions
data PrimaryExpr
    = ExpLiteral    Literal
    | ExpId         String
    | ExpBrackExp   Expression
    | ExpThis
    | ExpRegex      String
    | ExpArray      ArrayLit
    | ExpObject     [(PropName, Assignment)]
    deriving (Show, Eq)

-- | Literals
data Literal
    = LNull                 -- ^ null
    | LBool       Bool      -- ^ true or false
    | LInt        Integer
    | LFloat      Double
    | LStr        String    -- ^ \"string\" or \'string\'
    deriving (Show, Eq)

-- | Array literals
data ArrayLit
    = ArraySimp     [Assignment]
    deriving (Show, Eq)

-- | Property names
data PropName
    = PropNameId    String
    | PropNameStr   String
    | PropNameInt   Integer
	  deriving (Show, Eq)

-- | Logical or
data LogOr
    = LogAnd        LogAnd
	  | LOLogOr       LogOr LogAnd      -- ^ ||
	  deriving (Show, Eq)

-- | Logical and
data LogAnd
    = BitOR         BitOR
	  | LALogAnd      LogAnd BitOR      -- ^ &&
	  deriving (Show, Eq)

-- | Bitwise or
data BitOR
    = BitXOR        BitXOR
	  | BOBitOR       BitOR BitXOR      -- ^ |
	  deriving (Show, Eq)

-- | Bitwise xor
data BitXOR
    = BitAnd        BitAnd
	  | BXBitXOR      BitXOR BitAnd     -- ^ ^
	  deriving (Show, Eq)

-- | Bitwise and
data BitAnd
    = EqualExpr     EqualExpr
	  | BABitAnd      BitAnd EqualExpr  -- ^ &
	  deriving (Show, Eq)

-- | Equals expressions
data EqualExpr
    = RelExpr       RelExpr
	  | Equal         EqualExpr RelExpr -- ^ ==
	  | NotEqual      EqualExpr RelExpr -- ^ !=
	  | EqualTo       EqualExpr RelExpr -- ^ ===
	  | NotEqualTo    EqualExpr RelExpr -- ^ !==
    deriving (Show, Eq)

-- | Relative expressions
data RelExpr
    = ShiftExpr     ShiftExpr
	  | LessThan      RelExpr ShiftExpr -- ^ <
	  | GreaterThan   RelExpr ShiftExpr -- ^ \>
	  | LessEqual     RelExpr ShiftExpr -- ^ <=
	  | GreaterEqual  RelExpr ShiftExpr -- ^ \>=
	  | InstanceOf    RelExpr ShiftExpr -- ^ instanceof
	  | InObject      RelExpr ShiftExpr -- ^ in
	  deriving (Show, Eq)

-- | Shift expressions
data ShiftExpr
    = AddExpr       AddExpr
	  | ShiftLeft     ShiftExpr AddExpr -- ^ <<
	  | ShiftRight    ShiftExpr AddExpr -- ^ \>\>
	  | ShiftRight2   ShiftExpr AddExpr -- ^ \>\>\>
	  deriving (Show, Eq)

-- | Additive expressions
data AddExpr
    = MultExpr      MultExpr
    | Plus          AddExpr MultExpr  -- ^ +
    | Minus         AddExpr MultExpr  -- ^ \-
    deriving (Show, Eq)

-- | Multiplicative expressions
data MultExpr
    = UnaryExpr     UnaryExpr
    | Times         MultExpr UnaryExpr  -- ^ \*
    | Div           MultExpr UnaryExpr  -- ^ /
    | Mod           MultExpr UnaryExpr  -- ^ %
    deriving (Show, Eq)

-- | Unary expressions
data UnaryExpr
    = PostFix       PostFix
    | Delete        UnaryExpr   -- ^ delete a
    | Void          UnaryExpr   -- ^ void a
    | TypeOf        UnaryExpr   -- ^ typeof a
    | PlusPlus      UnaryExpr   -- ^ ++a
    | MinusMinus    UnaryExpr   -- ^ \-\-a
    | UnaryPlus     UnaryExpr   -- ^ +a
    | UnaryMinus    UnaryExpr   -- ^ \-a
    | Not           UnaryExpr   -- ^ !a
    | BitNot        UnaryExpr   -- ^ ~a
    deriving (Show, Eq)

-- | Post fix operators
data PostFix
    = LeftExpr      LeftExpr
	  | PostInc       LeftExpr    -- ^ a++
	  | PostDec       LeftExpr    -- ^ a\-\-
	  deriving (Show, Eq)