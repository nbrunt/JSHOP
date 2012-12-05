{-
******************************************************************************
*                                      JSHOP                                 *
*                                                                            *
*   Module:   Analyser                                                       *
*   Purpose:  Analyses the Parse Tree before code compression to detect      *
*             variable declarations.                                         *
*   Author:   Nick Brunt                                                     *
*                                                                            *
*                    Copyright (c) Nick Brunt, 2011 - 2012                   *
*              Subject to MIT License as stated in root directory            *
*                                                                            *
******************************************************************************
-}

-- | Analyses the Parse Tree before code compression to detect variable declarations.

module Analyser where

-- JSHOP module imports
import Diagnostics
import ParseTree
import CodeCompMonad
import CompUtils


anMaybe :: (a -> JSCC()) -> (Maybe a) -> JSCC()
anMaybe anFunc mbExpr
    = case mbExpr of
        Just expr -> anFunc expr
        Nothing   -> return ()


-- | Source
anSrc :: Source -> JSCC()
anSrc (Statement stmt)     = anStmt stmt
anSrc (SFuncDecl funcDecl) = anFuncDecl funcDecl

anSrcSeq :: [Source] -> JSCC()
anSrcSeq x = mapM_ anSrc x


-- | Function declaration
anFuncDecl :: FuncDecl -> JSCC()
anFuncDecl (FuncDecl (Just id) formalParamList sources) = do
    regID id
    incScope
    anFormalParamList formalParamList
    anSrcSeq sources
    decScope False
anFuncDecl (FuncDecl Nothing formalParamList sources) = do
    incScope
    anFormalParamList formalParamList
    anSrcSeq sources
    decScope False

-- | Formal param list
anFormalParamList :: [String] -> JSCC()
anFormalParamList ids = mapM_ regID ids


-- | Statement
anStmt :: Statement -> JSCC()
anStmt (IfStmt ifStmt)          = anIfStmt ifStmt
anStmt (IterativeStmt itStmt)   = anItStmt itStmt
anStmt (ExprStmt expr)          = anExpr expr
anStmt (TryStmt tryStmt)        = anTryStmt tryStmt
anStmt (Switch switch)          = anSwitch switch
anStmt (VarStmt varDecls)       = anVarDeclList varDecls
anStmt (Block stmts)            = anStmtSeq stmts
anStmt (ReturnStmt (Just expr)) = anExpr expr
anStmt (WithStmt expr stmt)     = anExpr expr >> anStmt stmt
anStmt (LabelledStmt id stmt)   = regID id >> anStmt stmt
anStmt (ThrowExpr expr)         = anExpr expr
anStmt _                        = return ()

anStmtSeq :: [Statement] -> JSCC()
anStmtSeq s = mapM_ anStmt s


-- | If statement
anIfStmt :: IfStmt -> JSCC()
anIfStmt (IfElse expr stmtTrue stmtFalse) = do
    anExpr expr
    anStmt stmtTrue
    anStmt stmtFalse
anIfStmt (If expr stmt) = anExpr expr >> anStmt stmt


-- | Iterative statement
anItStmt :: IterativeStmt -> JSCC()
anItStmt (DoWhile stmt expr) = anStmt stmt >> anExpr expr
anItStmt (While expr stmt)   = anExpr expr >> anStmt stmt
anItStmt (For mbExpr mbExpr2 mbExpr3 stmt) = do
    anMaybe anExpr mbExpr
    anMaybe anExpr mbExpr2
    anMaybe anExpr mbExpr3
    anStmt stmt
anItStmt (ForVar varDecls mbExpr2 mbExpr3 stmt) = do
    anVarDeclList varDecls
    anMaybe anExpr mbExpr2
    anMaybe anExpr mbExpr3
    anStmt stmt
anItStmt (ForIn leftExpr expr stmt) = do
    anLeftExpr leftExpr
    anExpr expr
    anStmt stmt
anItStmt (ForVarIn varDecls expr stmt) = do
    anVarDeclList varDecls
    anExpr expr
    anStmt stmt


-- | Try statement
anTryStmt :: TryStmt -> JSCC()
anTryStmt (TryBC stmts catchs) = anStmtSeq stmts >> anCatchSeq catchs
anTryStmt (TryBF stmts stmts2) = anStmtSeq stmts >> anStmtSeq stmts2
anTryStmt (TryBCF stmts catchs stmts2) = do
    anStmtSeq stmts
    anCatchSeq catchs
    anStmtSeq stmts2


-- | Catch
anCatch :: Catch -> JSCC()
anCatch (Catch id stmts)        = regID id >> anStmtSeq stmts
anCatch (CatchIf id stmts expr) = do
    regID id
    anExpr expr
    anStmtSeq stmts

anCatchSeq :: [Catch] -> JSCC()
anCatchSeq c = mapM_ anCatch c


-- | Switch
anSwitch :: Switch -> JSCC()
anSwitch (SSwitch expr caseBlock) = anExpr expr >> anCaseBlock caseBlock


-- | Case block
anCaseBlock :: CaseBlock -> JSCC()
anCaseBlock (CaseBlock caseClauses defaultClauses caseClauses2) = do
    anCaseClauseSeq caseClauses
    anDefaultClauseSeq defaultClauses
    anCaseClauseSeq caseClauses2


-- | Case clause
anCaseClause :: CaseClause -> JSCC()
anCaseClause (CaseClause expr stmts) = anExpr expr >> anStmtSeq stmts

anCaseClauseSeq :: [CaseClause] -> JSCC()
anCaseClauseSeq cc = mapM_ anCaseClause cc


-- | Default clause
anDefaultClause :: DefaultClause -> JSCC()
anDefaultClause (DefaultClause stmts) = anStmtSeq stmts

anDefaultClauseSeq :: [DefaultClause] -> JSCC()
anDefaultClauseSeq dc = mapM_ anDefaultClause dc


-- | Expression
anExpr :: Expression -> JSCC()
anExpr (Assignment assigns) = anAssignList assigns


-- | Var declaration
anVarDecl :: VarDecl -> JSCC()
anVarDecl (VarDecl id (Just assign)) = regID id >> anAssign assign
anVarDecl (VarDecl id Nothing)       = regID id

anVarDeclList :: [VarDecl] -> JSCC()
anVarDeclList vd = mapM_ anVarDecl vd


-- | Assignment
anAssign :: Assignment -> JSCC()
anAssign (CondExpr condExpr) = anCondExpr condExpr
anAssign (Assign leftExpr assignOp assign) = do
    anLeftExpr leftExpr
    anAssignOp assignOp
    anAssign assign
anAssign (AssignFuncDecl funcDecl) = anFuncDecl funcDecl

anAssignList :: [Assignment] -> JSCC()
anAssignList a = mapM_ anAssign a


-- | Left expression
anLeftExpr :: LeftExpr -> JSCC()
anLeftExpr (NewExpr newExpr)   = anNewExpr newExpr
anLeftExpr (CallExpr callExpr) = anCallExpr callExpr


-- | Assignment operator
anAssignOp :: AssignOp -> JSCC()
anAssignOp _ = return ()


-- | Conditional expression
anCondExpr :: CondExpr -> JSCC()
anCondExpr (LogOr logOr) = anLogOr logOr
anCondExpr (CondIf logOr assignTrue assignFalse) = do
    anLogOr logOr
    anAssign assignTrue
    anAssign assignFalse


-- | New expression
anNewExpr :: NewExpr -> JSCC()
anNewExpr (MemberExpr memberExpr) = anMemberExpr memberExpr
anNewExpr (NNewExpr newExpr)      = anNewExpr newExpr


-- | Call expression
anCallExpr :: CallExpr -> JSCC()
anCallExpr (CallMember memberExpr assigns) = anMemberExpr memberExpr >> anAssignList assigns
anCallExpr (CallCall callExpr assigns) = anCallExpr callExpr >> anAssignList assigns
anCallExpr (CallSquare callExpr expr) = anCallExpr callExpr >> anExpr expr
anCallExpr (CallDot callExpr id) = anCallExpr callExpr


-- | Member expression
anMemberExpr :: MemberExpr -> JSCC()
anMemberExpr (MemExpression primExpr)    = anPrimExpr primExpr
anMemberExpr (FuncExpr funcDecl)         = anFuncDecl funcDecl
anMemberExpr (ArrayExpr memberExpr expr) = anMemberExpr memberExpr >> anExpr expr
anMemberExpr (MemberNew memberExpr assigns) = anMemberExpr memberExpr >> anAssignList assigns
anMemberExpr (MemberCall memberExpr id)  = anMemberExpr memberExpr


-- | Primary expressions
anPrimExpr :: PrimaryExpr -> JSCC()
anPrimExpr (ExpArray arrayLit) = anArrayLit arrayLit
anPrimExpr (ExpObject objLit)  = anObjLit objLit
anPrimExpr (ExpBrackExp expr)  = anExpr expr
anPrimExpr _                   = return ()


-- | Array literal
anArrayLit :: ArrayLit -> JSCC()
anArrayLit (ArraySimp elementList) = anElementList elementList

anElementList :: [Assignment] -> JSCC()
anElementList a = mapM_ anAssign a

-- | Object literal
anObjLit :: [(PropName, Assignment)] -> JSCC()
anObjLit []        = return ()
anObjLit propList  = anPropList propList

anPropList :: [(PropName, Assignment)] -> JSCC()
anPropList p = mapM_ anProp p

anProp :: (PropName, Assignment) -> JSCC()
anProp (propName, assign) = anPropName propName >> anAssign assign


-- | Property name
anPropName :: PropName -> JSCC()
anPropName _ = return ()


-- | Logical or
anLogOr :: LogOr -> JSCC()
anLogOr (LogAnd logAnd)        = anLogAnd logAnd
anLogOr (LOLogOr logOr logAnd) = anLogOr logOr >> anLogAnd logAnd


-- | Logical and
anLogAnd :: LogAnd -> JSCC()
anLogAnd (BitOR bitOr)           = anBitOr bitOr
anLogAnd (LALogAnd logAnd bitOr) = anLogAnd logAnd >> anBitOr bitOr


-- | Bitwise or
anBitOr :: BitOR -> JSCC()
anBitOr (BitXOR bitXor)        = anBitXor bitXor
anBitOr (BOBitOR bitOr bitXor) = anBitOr bitOr >> anBitXor bitXor


-- | Bitwise xor
anBitXor :: BitXOR -> JSCC()
anBitXor (BitAnd bitAnd)          = anBitAnd bitAnd
anBitXor (BXBitXOR bitXor bitAnd) = anBitXor bitXor >> anBitAnd bitAnd


-- | Bitwise and
anBitAnd :: BitAnd -> JSCC()
anBitAnd (EqualExpr equalExpr)       = anEqualExpr equalExpr
anBitAnd (BABitAnd bitAnd equalExpr) = anBitAnd bitAnd >> anEqualExpr equalExpr


-- | Equality operators
anEqualExpr :: EqualExpr -> JSCC()
anEqualExpr (RelExpr relExpr)              = anRelExpr relExpr
anEqualExpr (Equal equalExpr relExpr)      = anEqualExpr equalExpr >> anRelExpr relExpr
anEqualExpr (NotEqual equalExpr relExpr)   = anEqualExpr equalExpr >> anRelExpr relExpr
anEqualExpr (EqualTo equalExpr relExpr)    = anEqualExpr equalExpr >> anRelExpr relExpr
anEqualExpr (NotEqualTo equalExpr relExpr) = anEqualExpr equalExpr >> anRelExpr relExpr


-- | Relational operators
anRelExpr :: RelExpr -> JSCC()
anRelExpr (ShiftExpr shiftExpr)            = anShiftExpr shiftExpr
anRelExpr (LessThan relExpr shiftExpr)     = anRelExpr relExpr >> anShiftExpr shiftExpr
anRelExpr (GreaterThan relExpr shiftExpr)  = anRelExpr relExpr >> anShiftExpr shiftExpr
anRelExpr (LessEqual relExpr shiftExpr)    = anRelExpr relExpr >> anShiftExpr shiftExpr
anRelExpr (GreaterEqual relExpr shiftExpr) = anRelExpr relExpr >> anShiftExpr shiftExpr
anRelExpr (InstanceOf relExpr shiftExpr)   = anRelExpr relExpr >> anShiftExpr shiftExpr
anRelExpr (InObject relExpr shiftExpr)     = anRelExpr relExpr >> anShiftExpr shiftExpr


-- | Shift operators
anShiftExpr :: ShiftExpr -> JSCC()
anShiftExpr (AddExpr addExpr)               = anAddExpr addExpr
anShiftExpr (ShiftLeft shiftExpr addExpr)   = anShiftExpr shiftExpr >> anAddExpr addExpr
anShiftExpr (ShiftRight shiftExpr addExpr)  = anShiftExpr shiftExpr >> anAddExpr addExpr
anShiftExpr (ShiftRight2 shiftExpr addExpr) = anShiftExpr shiftExpr >> anAddExpr addExpr


-- | Additive operators
anAddExpr :: AddExpr -> JSCC()
anAddExpr (MultExpr multExpr)      = anMultExpr multExpr
anAddExpr (Plus addExpr multExpr)  = anAddExpr addExpr >> anMultExpr multExpr
anAddExpr (Minus addExpr multExpr) = anAddExpr addExpr >> anMultExpr multExpr


-- | Multiplicative operators
anMultExpr :: MultExpr -> JSCC()
anMultExpr (UnaryExpr unaryExpr)      = anUnaryExpr unaryExpr
anMultExpr (Times multExpr unaryExpr) = anMultExpr multExpr >> anUnaryExpr unaryExpr
anMultExpr (Div multExpr unaryExpr)   = anMultExpr multExpr >> anUnaryExpr unaryExpr
anMultExpr (Mod multExpr unaryExpr)   = anMultExpr multExpr >> anUnaryExpr unaryExpr


-- | Unary operators
anUnaryExpr :: UnaryExpr -> JSCC()
anUnaryExpr (PostFix postFix)       = anPostFix postFix
anUnaryExpr (Delete unaryExpr)      = anUnaryExpr unaryExpr
anUnaryExpr (Void unaryExpr)        = anUnaryExpr unaryExpr
anUnaryExpr (TypeOf unaryExpr)      = anUnaryExpr unaryExpr
anUnaryExpr (PlusPlus unaryExpr)    = anUnaryExpr unaryExpr
anUnaryExpr (MinusMinus unaryExpr)  = anUnaryExpr unaryExpr
anUnaryExpr (UnaryPlus unaryExpr)   = anUnaryExpr unaryExpr
anUnaryExpr (UnaryMinus unaryExpr)  = anUnaryExpr unaryExpr
anUnaryExpr (Not unaryExpr)         = anUnaryExpr unaryExpr
anUnaryExpr (BitNot unaryExpr)      = anUnaryExpr unaryExpr


-- | Post fix
anPostFix :: PostFix -> JSCC()
anPostFix (LeftExpr leftExpr) = anLeftExpr leftExpr
anPostFix (PostInc leftExpr)  = anLeftExpr leftExpr
anPostFix (PostDec leftExpr)  = anLeftExpr leftExpr
