{-
******************************************************************************
*                                   JSHOP                                    *
*                                                                            *
*   Module:   CodeCompressor                                                 *
*   Purpose:  Generate and compress JavaScript from the Parse Tree           *
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
*                           As defined in ECMA-262                           *
*                                                                            *
*                         Expressions - Page 40                              *
*                         Statements - Page 61                               *
*                         Function Definition - Page 71                      *
*                                                                            *
******************************************************************************
-}

-- | Generate and compress JavaScript from the Parse Tree

module CodeCompressor where

-- Standard library imports
import Control.Monad (when)
import Data.Char (isDigit)
import Data.Array
import Data.Maybe

-- JSHOP module imports
import Diagnostics
import ParseTree
import CodeCompMonad
import Analyser
import CompUtils

------------------------------------------------------------------------------
-- Code generation functions
------------------------------------------------------------------------------

-- | Generates a JavaScript program from the Parse Tree
genCode :: Tree -> D [String]
genCode tree = do
    let (_, code, _) = runCC (run tree)
    return code


-- | Generate code to run a complete program
run :: Tree -> JSCC ()
run (Tree sources) = do
    anSrcSeq sources
    resetScope
    genSrcSeq sources


-- | Source
genSrc :: Source -> JSCC()
genSrc (Statement stmt)     = genStmt stmt
genSrc (SFuncDecl funcDecl) = genFuncDecl funcDecl

genSrcSeq :: [Source] -> JSCC()
genSrcSeq s = mapM_ genSrc s


-- | Function declaration
genFuncDecl :: FuncDecl -> JSCC()
genFuncDecl (FuncDecl (Just id) formalParamList sources) = do
    emit "function "
    id' <- emitID id
    emit id'
    incScope
    emit "("
    genFormalParamList formalParamList
    emit "){"
    genSrcSeq sources
    emit "}"
    -- showState
    decScope True
genFuncDecl (FuncDecl Nothing formalParamList sources) = do
    emit $ "function("
    incScope
    genFormalParamList formalParamList
    emit "){"
    genSrcSeq sources
    emit "}"
    -- showState
    decScope True


-- | Formal param list
genFormalParamList :: [String] -> JSCC()
genFormalParamList []   = emit ""
genFormalParamList [id] = do
    id' <- emitID id
    emit id'
genFormalParamList ids  = do
    genFormalParamList $ init ids
    emit ","
    ids' <- emitID $ last ids
    emit ids'


-- | Statement
genStmt :: Statement -> JSCC()
genStmt EmptyStmt                 = emit ";"
genStmt (IfStmt ifStmt)           = genIfStmt ifStmt
genStmt (IterativeStmt itStmt)    = genItStmt itStmt
genStmt (ExprStmt expr)           = do
    genExpr expr
    emit ";"
genStmt (TryStmt tryStmt)         = genTryStmt tryStmt
genStmt (Switch switch)           = genSwitch switch
genStmt (VarStmt varDecls)        = do
    emit "var "
    genVarDeclList varDecls
    emit ";"
genStmt (Block stmts)             = do
    emit "{"
    genStmtSeq stmts
    emit "}"
genStmt (ContinueStmt (Just id)) = do
    emit $ "continue "
    id' <- emitID id
    emit id'
    emit ";"
genStmt (ContinueStmt Nothing)
    = emit "continue;"
genStmt (BreakStmt (Just id)) = do
    emit "break "
    id' <- emitID id
    emit id'
    emit ";"
genStmt (BreakStmt Nothing)
    = emit "break;"
genStmt (ReturnStmt (Just expr)) = do
    emit "return "
    genExpr expr
    emit ";"
genStmt (ReturnStmt Nothing) = emit "return;"
genStmt (WithStmt expr stmt) = do
    emit "with("
    genExpr expr
    emit ")"
    genStmt stmt
genStmt (LabelledStmt id stmt) = do
    id' <- emitID id
    emit id'
    emit ":"
    genStmt stmt
genStmt (ThrowExpr expr) = do
    emit "throw "
    genExpr expr
    emit ";"

genStmtSeq :: [Statement] -> JSCC()
genStmtSeq []     = return ()
genStmtSeq (x:xs) = do
    genStmt x
    genStmtSeq xs


-- | If statement
genIfStmt :: IfStmt -> JSCC()
genIfStmt ifStmt@(IfElse expr
    (ExprStmt (Assignment [Assign leftExprTrue assignOpTrue assignTrue]))
    (ExprStmt (Assignment [Assign leftExprFalse assignOpFalse assignFalse])))
    = if leftExprTrue == leftExprFalse then
          genTernaryCond expr leftExprTrue assignOpTrue assignTrue assignFalse
       else
          genIfElse ifStmt
genIfStmt ifStmt@(IfElse expr
    (Block [ExprStmt (Assignment [Assign leftExprTrue assignOpTrue assignTrue])])
    (Block [ExprStmt (Assignment [Assign leftExprFalse assignOpFalse assignFalse])]))
    = if leftExprTrue == leftExprFalse then
          genTernaryCond expr leftExprTrue assignOpTrue assignTrue assignFalse
       else
          genIfElse ifStmt
genIfStmt ifStmt@(IfElse _ _ _) = genIfElse ifStmt
genIfStmt (If expr stmt) = do
    emit "if("
    genExpr expr
    emit ")"
    genStmt stmt

--  | Optimisation note:
--     If the true or false statements are blocks (surrounded by braces), no
--     spaces are needed around the else keyword.
genIfElse :: IfStmt -> JSCC()
genIfElse (IfElse expr stmtTrue stmtFalse) = do
    emit "if("
    genExpr expr
    emit ")"
    genStmt stmtTrue
    blockSpace stmtTrue
    emit "else"
    blockSpace stmtFalse
    genStmt stmtFalse
    where
        blockSpace :: Statement -> JSCC()
        blockSpace (Block _) = return ()
        blockSpace _         = emit " "

-- | Ternary conditional
genTernaryCond :: Expression  -- ^ Condition
               -> LeftExpr    -- ^ Left side of assignment
               -> AssignOp    -- ^ Assignment operator
               -> Assignment  -- ^ Assignment if true
               -> Assignment  -- ^ Assignment if false
               -> JSCC()
genTernaryCond expr leftExpr assignOp assignTrue assignFalse = do
    leftExpr' <- genLeftExpr leftExpr
    genMaybe genPrimExpr leftExpr'
    genAssignOp assignOp
    genExpr expr
    emit "?"
    genAssign assignTrue
    emit ":"
    genAssign assignFalse
    emit ";"


-- | Iterative statement
genItStmt :: IterativeStmt -> JSCC()
genItStmt (DoWhile stmt expr) = do
    emit "do "
    genStmt stmt
    emit " while("
    genExpr expr
    emit ");"
genItStmt (While expr stmt) = do
    emit "while("
    genExpr expr
    emit ")"
    genStmt stmt
genItStmt (For mbExpr mbExpr2 mbExpr3 stmt) = do
    emit "for("
    genMaybe genExpr mbExpr
    emit ";"
    genMaybe genExpr mbExpr2
    emit ";"
    genMaybe genExpr mbExpr3
    emit ")"
    genStmt stmt
genItStmt (ForVar varDecls mbExpr2 mbExpr3 stmt) = do
    emit "for(var "
    genVarDeclList varDecls
    emit ";"
    genMaybe genExpr mbExpr2
    emit ";"
    genMaybe genExpr mbExpr3
    emit ")"
    genStmt stmt
genItStmt (ForIn leftExpr expr stmt) = do
    emit "for("
    leftExpr' <- genLeftExpr leftExpr
    genMaybe genPrimExpr leftExpr'
    emit " in "
    genExpr expr
    emit ")"
    genStmt stmt
genItStmt (ForVarIn varDecls expr stmt) = do
    emit "for(var "
    genVarDeclList varDecls
    emit " in "
    genExpr expr
    emit ")"
    genStmt stmt


-- | Try statement
genTryStmt :: TryStmt -> JSCC()
genTryStmt (TryBC stmts catchs) = do
    emit "try{"
    genStmtSeq stmts
    emit "}"
    genCatchSeq catchs
genTryStmt (TryBF stmts stmts2) = do
    emit "try{"
    genStmtSeq stmts
    emit "}finally{"
    genStmtSeq stmts2
    emit "}"
genTryStmt (TryBCF stmts catchs stmts2) = do
    emit "try{"
    genStmtSeq stmts
    emit "}"
    genCatchSeq catchs
    emit "finally{"
    genStmtSeq stmts2
    emit "}"


-- | Catch
genCatch :: Catch -> JSCC()
genCatch (Catch id stmts) = do
    emit "catch("
    id' <- emitID id
    emit id'
    emit "){"
    genStmtSeq stmts
    emit "}"
-- Not in ECMA-262
-- http://code.google.com/p/jslibs/wiki/JavascriptTips#Exceptions_Handling_/_conditional_catch_(try_catch_if)
genCatch (CatchIf id stmts expr) = do
    emit "catch("
    id' <- emitID id
    emit id'
    emit " if "
    genExpr expr
    emit "){"
    genStmtSeq stmts
    emit "}"

genCatchSeq :: [Catch] -> JSCC()
genCatchSeq c = mapM_ genCatch c


-- | Switch
genSwitch :: Switch -> JSCC()
genSwitch (SSwitch expr caseBlock) = do
    emit "switch("
    genExpr expr
    emit ")"
    genCaseBlock caseBlock


-- | Case block
genCaseBlock :: CaseBlock -> JSCC()
genCaseBlock (CaseBlock caseClauses defaultClauses caseClauses2) = do
    emit "{"
    genCaseClauseSeq caseClauses
    genDefaultClauseSeq defaultClauses
    genCaseClauseSeq caseClauses2
    emit "}"


-- | Case clause
genCaseClause :: CaseClause -> JSCC()
genCaseClause (CaseClause expr stmts) = do
    emit "case "
    genExpr expr
    emit ":"
    genStmtSeq stmts

genCaseClauseSeq :: [CaseClause] -> JSCC()
genCaseClauseSeq cc = mapM_ genCaseClause cc


-- | Default clause
genDefaultClause :: DefaultClause -> JSCC()
genDefaultClause (DefaultClause stmts) = do
    emit "default:"
    genStmtSeq stmts

genDefaultClauseSeq :: [DefaultClause] -> JSCC()
genDefaultClauseSeq dc = mapM_ genDefaultClause dc


-- | Expression
genExpr :: Expression -> JSCC()
genExpr (Assignment assigns) = genAssignList assigns


-- | Var declaration
genVarDecl :: VarDecl -> JSCC()
genVarDecl (VarDecl id (Just assign)) = do
    id' <- emitID id
    emit id'
    emit "="
    genAssign assign
genVarDecl (VarDecl id Nothing) = do
    id' <- emitID id
    emit id'

genVarDeclList :: [VarDecl] -> JSCC()
genVarDeclList []         = emit ""
genVarDeclList [varDecl]  = genVarDecl varDecl
genVarDeclList varDecls   = do
    genVarDeclList $ init varDecls
    emit ","
    genVarDecl $ last varDecls


-- | Assignment
genAssign :: Assignment -> JSCC()
genAssign (CondExpr condExpr) = do
    condExpr' <- genCondExpr condExpr
    genMaybe genPrimExpr condExpr'
genAssign (Assign leftExpr assignOp assign) = do
    leftExpr' <- genLeftExpr leftExpr
    genMaybe genPrimExpr leftExpr'
    genAssignOp assignOp
    genAssign assign
genAssign (AssignFuncDecl funcDecl) = do
    genFuncDecl funcDecl

genAssignList :: [Assignment] -> JSCC()
genAssignList []      = return ()
genAssignList [x]     = genAssign x
genAssignList (x:xs)  = do
    genAssign x
    emit ","
    genAssignList xs


-- | Left expression
genLeftExpr :: LeftExpr -> JSCC (Maybe PrimaryExpr)
genLeftExpr (NewExpr newExpr)   = do
    newExpr' <- genNewExpr newExpr
    return newExpr'
genLeftExpr (CallExpr callExpr) = do
    genCallExpr callExpr
    return Nothing


-- | Assignment operator
genAssignOp :: AssignOp -> JSCC()
genAssignOp AssignNormal    = emit "="
genAssignOp AssignOpMult    = emit "*="
genAssignOp AssignOpDiv     = emit "/="
genAssignOp AssignOpMod     = emit "%="
genAssignOp AssignOpPlus    = emit "+="
genAssignOp AssignOpMinus   = emit "-="
genAssignOp AssignOpSLeft   = emit "<<="
genAssignOp AssignOpSRight  = emit ">>="
genAssignOp AssignOpSRight2 = emit ">>>="
genAssignOp AssignOpAnd     = emit "&="
genAssignOp AssignOpNot     = emit "^="
genAssignOp AssignOpOr      = emit "|="


-- | Conditional expression
genCondExpr :: CondExpr -> JSCC (Maybe PrimaryExpr)
genCondExpr (LogOr logOr) = do
    logOr' <- genLogOr logOr
    return logOr'
genCondExpr (CondIf logOr assignTrue assignFalse) = do
    logOr' <- genLogOr logOr
    genMaybe genPrimExpr logOr'
    emit "?"
    genAssign assignTrue
    emit ":"
    genAssign assignFalse
    return Nothing


-- | New expression
genNewExpr :: NewExpr -> JSCC (Maybe PrimaryExpr)
genNewExpr (MemberExpr memberExpr)  = do
    memberExpr' <- genMemberExpr memberExpr
    return memberExpr'
genNewExpr (NNewExpr newExpr)       = do
    emit "new "
    newExpr' <- genNewExpr newExpr
    genMaybe genPrimExpr newExpr'
    return Nothing


-- | Call expression
genCallExpr :: CallExpr -> JSCC()
genCallExpr (CallMember memberExpr assigns) = do
    memberExpr' <- genMemberExpr memberExpr
    genMaybe genPrimExpr memberExpr'
    emit "("
    genAssignList assigns
    emit ")"
genCallExpr (CallCall callExpr assigns) = do
    genCallExpr callExpr
    emit "("
    genAssignList assigns
    emit ")"
genCallExpr (CallSquare callExpr expr) = do
    genCallExpr callExpr
    emit "["
    genExpr expr
    emit "]"
genCallExpr (CallDot callExpr id) = do
    genCallExpr callExpr
    emit "."
    id' <- emitID id
    emit id'


-- | Member expression
genMemberExpr :: MemberExpr -> JSCC (Maybe PrimaryExpr)
genMemberExpr (MemExpression primExpr)    = do
    primExpr' <- retPrimExpr primExpr
    return primExpr'
genMemberExpr (FuncExpr funcDecl)         = do
    genFuncDecl funcDecl
    return Nothing
genMemberExpr (ArrayExpr memberExpr expr) = do
    memberExpr' <- genMemberExpr memberExpr
    genMaybe genPrimExpr memberExpr'
    emit "["
    genExpr expr
    emit "]"
    return Nothing
genMemberExpr (MemberNew memberExpr assigns) = do
    emit "new "
    memberExpr' <- genMemberExpr memberExpr
    genMaybe genPrimExpr memberExpr'
    emit "("
    genAssignList assigns
    emit ")"
    return Nothing
genMemberExpr (MemberCall memberExpr id) = do
    memberExpr' <- genMemberExpr memberExpr
    genMaybe genPrimExpr memberExpr'
    emit "."
    -- Do not shorten this.  Could be referring to an external object.
    emit id
    return Nothing


-- | Primary expressions
genPrimExpr :: PrimaryExpr -> JSCC()
genPrimExpr (ExpLiteral lit)    = genLiteral lit
genPrimExpr (ExpId id)          = do
    id' <- emitID id
    emit id'
genPrimExpr ExpThis             = emit "this"
genPrimExpr (ExpRegex regex)    = emit regex
genPrimExpr (ExpArray arrayLit) = genArrayLit arrayLit
genPrimExpr (ExpObject objLit)  = genObjLit objLit
genPrimExpr (ExpBrackExp (Assignment [CondExpr (LogOr (LogAnd (BitOR (BitXOR (BitAnd (EqualExpr (RelExpr (ShiftExpr (AddExpr (MultExpr (UnaryExpr (PostFix (LeftExpr (NewExpr (MemberExpr (MemExpression primExpr))))))))))))))))]))
    = genPrimExpr primExpr -- Only one primary expression, don't emit brackets.
                           -- Yes, it's convoluted, but it's the simplest way.
genPrimExpr (ExpBrackExp expr)  = do
    emit "("
    genExpr expr
    emit ")"

retPrimExpr :: PrimaryExpr -> JSCC (Maybe PrimaryExpr)
retPrimExpr (ExpLiteral lit) = do
    lit' <- retLiteral lit
    return $ Just $ ExpLiteral lit'
retPrimExpr primExpr         = return $ Just primExpr

retLiteral :: Literal -> JSCC Literal
retLiteral lit = return lit


-- | Array literal
genArrayLit :: ArrayLit -> JSCC()
genArrayLit (ArraySimp elementList) = do
    emit "["
    genElementList elementList
    emit "]"

genElementList :: [Assignment] -> JSCC()
genElementList []       = emit ""
genElementList [assign] = genAssign assign
genElementList assigns  = do
    genElementList $ init assigns
    emit ","
    genAssign $ last assigns


-- | Object literal
genObjLit :: [(PropName, Assignment)] -> JSCC()
genObjLit []        = emit "{}"
genObjLit propList  = do
    emit "{"
    genPropList propList
    emit "}"

genPropList :: [(PropName, Assignment)] -> JSCC()
genPropList [prop]  = genProp prop
genPropList props   = do
    genPropList $ init props
    emit ","
    genProp $ last props

genProp :: (PropName, Assignment) -> JSCC()
genProp (propName, assign) = do
    genPropName propName
    emit ":"
    genAssign assign


-- | Property name
genPropName :: PropName -> JSCC()
genPropName (PropNameId id)   = emit id
genPropName (PropNameStr str) = emit str
genPropName (PropNameInt int) = emit $ show int


-- | Logical or
genLogOr :: LogOr -> JSCC (Maybe PrimaryExpr)
genLogOr (LogAnd logAnd)        = do
    logAnd' <- genLogAnd logAnd
    return logAnd'
genLogOr (LOLogOr logOr logAnd) = do
    logOr' <- genLogOr logOr
    genMaybe genPrimExpr logOr'
    emit "||"
    logAnd' <- genLogAnd logAnd
    genMaybe genPrimExpr logAnd'
    return Nothing


-- | Logical and
genLogAnd :: LogAnd -> JSCC (Maybe PrimaryExpr)
genLogAnd (BitOR bitOr)           = do
    bitOr' <- genBitOr bitOr
    return bitOr'
genLogAnd (LALogAnd logAnd bitOr) = do
    logAnd' <- genLogAnd logAnd
    genMaybe genPrimExpr logAnd'
    emit "&&"
    bitOr' <- genBitOr bitOr
    genMaybe genPrimExpr bitOr'
    return Nothing


-- | Bitwise or
genBitOr :: BitOR -> JSCC (Maybe PrimaryExpr)
genBitOr (BitXOR bitXor)        = do
    bitXor' <- genBitXor bitXor
    return bitXor'
genBitOr (BOBitOR bitOr bitXor) = do
    bitOr' <- genBitOr bitOr
    genMaybe genPrimExpr bitOr'
    emit "|"
    bitXor' <- genBitXor bitXor
    genMaybe genPrimExpr bitXor'
    return Nothing


-- | Bitwise xor
genBitXor :: BitXOR -> JSCC (Maybe PrimaryExpr)
genBitXor (BitAnd bitAnd)           = do
    bitAnd' <- genBitAnd bitAnd
    return bitAnd'
genBitXor (BXBitXOR bitXor bitAnd)  = do
    bitXor' <- genBitXor bitXor
    genMaybe genPrimExpr bitXor'
    emit "^"
    bitAnd' <- genBitAnd bitAnd
    genMaybe genPrimExpr bitAnd'
    return Nothing


-- | Bitwise and
genBitAnd :: BitAnd -> JSCC (Maybe PrimaryExpr)
genBitAnd (EqualExpr equalExpr)       = do
    equalExpr' <- genEqualExpr equalExpr
    return equalExpr'
genBitAnd (BABitAnd bitAnd equalExpr) = do
    bitAnd' <- genBitAnd bitAnd
    genMaybe genPrimExpr bitAnd'
    emit "&"
    equalExpr' <- genEqualExpr equalExpr
    genMaybe genPrimExpr equalExpr'
    return Nothing


-- | Equality operators
genEqualExpr :: EqualExpr -> JSCC (Maybe PrimaryExpr)
genEqualExpr (RelExpr relExpr) = do
    relExpr' <- genRelExpr relExpr
    return relExpr'
genEqualExpr (Equal equalExpr relExpr) = do
    equalExpr' <- genEqualExpr equalExpr
    genMaybe genPrimExpr equalExpr'
    emit "=="
    relExpr' <- genRelExpr relExpr
    genMaybe genPrimExpr relExpr'
    return Nothing
genEqualExpr (NotEqual equalExpr relExpr) = do
    equalExpr' <- genEqualExpr equalExpr
    genMaybe genPrimExpr equalExpr'
    emit "!="
    relExpr' <- genRelExpr relExpr
    genMaybe genPrimExpr relExpr'
    return Nothing
genEqualExpr (EqualTo equalExpr relExpr) = do
    equalExpr' <- genEqualExpr equalExpr
    genMaybe genPrimExpr equalExpr'
    emit "==="
    relExpr' <- genRelExpr relExpr
    genMaybe genPrimExpr relExpr'
    return Nothing
genEqualExpr (NotEqualTo equalExpr relExpr) = do
    equalExpr' <- genEqualExpr equalExpr
    genMaybe genPrimExpr equalExpr'
    emit "!=="
    relExpr' <- genRelExpr relExpr
    genMaybe genPrimExpr relExpr'
    return Nothing


-- | Relational operators
genRelExpr :: RelExpr -> JSCC (Maybe PrimaryExpr)
genRelExpr (ShiftExpr shiftExpr) = do
    shiftExpr' <- genShiftExpr shiftExpr
    return shiftExpr'
genRelExpr (LessThan relExpr shiftExpr) = do
    relExpr' <- genRelExpr relExpr
    genMaybe genPrimExpr relExpr'
    emit "<"
    shiftExpr' <- genShiftExpr shiftExpr
    genMaybe genPrimExpr shiftExpr'
    return Nothing
genRelExpr (GreaterThan relExpr shiftExpr) = do
    relExpr' <- genRelExpr relExpr
    genMaybe genPrimExpr relExpr'
    emit ">"
    shiftExpr' <- genShiftExpr shiftExpr
    genMaybe genPrimExpr shiftExpr'
    return Nothing
genRelExpr (LessEqual relExpr shiftExpr) = do
    relExpr' <- genRelExpr relExpr
    genMaybe genPrimExpr relExpr'
    emit "<="
    shiftExpr' <- genShiftExpr shiftExpr
    genMaybe genPrimExpr shiftExpr'
    return Nothing
genRelExpr (GreaterEqual relExpr shiftExpr) = do
    relExpr' <- genRelExpr relExpr
    genMaybe genPrimExpr relExpr'
    emit ">="
    shiftExpr' <- genShiftExpr shiftExpr
    genMaybe genPrimExpr shiftExpr'
    return Nothing
genRelExpr (InstanceOf relExpr shiftExpr) = do
    relExpr' <- genRelExpr relExpr
    genMaybe genPrimExpr relExpr'
    emit " instanceof "
    shiftExpr' <- genShiftExpr shiftExpr
    genMaybe genPrimExpr shiftExpr'
    return Nothing
genRelExpr (InObject relExpr shiftExpr) = do
    relExpr' <- genRelExpr relExpr
    genMaybe genPrimExpr relExpr'
    emit " in "
    shiftExpr' <- genShiftExpr shiftExpr
    genMaybe genPrimExpr shiftExpr'
    return Nothing


-- | Shift operators
genShiftExpr :: ShiftExpr -> JSCC (Maybe PrimaryExpr)
genShiftExpr (AddExpr addExpr) = do
    addExpr' <- genAddExpr addExpr
    return addExpr'
genShiftExpr (ShiftLeft shiftExpr addExpr) = do
    shiftExpr' <- genShiftExpr shiftExpr
    genMaybe genPrimExpr shiftExpr'
    emit "<<"
    addExpr' <- genAddExpr addExpr
    genMaybe genPrimExpr addExpr'
    return Nothing
genShiftExpr (ShiftRight shiftExpr addExpr) = do
    shiftExpr' <- genShiftExpr shiftExpr
    genMaybe genPrimExpr shiftExpr'
    emit ">>"
    addExpr' <- genAddExpr addExpr
    genMaybe genPrimExpr addExpr'
    return Nothing
genShiftExpr (ShiftRight2 shiftExpr addExpr) = do
    shiftExpr' <- genShiftExpr shiftExpr
    genMaybe genPrimExpr shiftExpr'
    emit ">>>"
    addExpr' <- genAddExpr addExpr
    genMaybe genPrimExpr addExpr'
    return Nothing


-- | Additive operators
genAddExpr :: AddExpr -> JSCC (Maybe PrimaryExpr)
genAddExpr (MultExpr multExpr) = do
    multExpr' <- genMultExpr multExpr
    return multExpr'
genAddExpr (Plus addExpr multExpr) = do
    a <- genAddExpr addExpr
    if isJust a then genPrimExpr $ fromJust a else emit ""
    emit "+"
    b <- genMultExpr multExpr
    res <- peSimpCalc genPrimExpr a b '+'
    return res
genAddExpr (Minus addExpr multExpr) = do
    a <- genAddExpr addExpr
    if isJust a then genPrimExpr $ fromJust a else emit ""
    emit "-"
    b <- genMultExpr multExpr
    res <- peSimpCalc genPrimExpr a b '-'
    return res


-- | Multiplicative operators
genMultExpr :: MultExpr -> JSCC (Maybe PrimaryExpr)
genMultExpr (UnaryExpr unaryExpr) = do
    unaryExpr' <- genUnaryExpr unaryExpr
    return unaryExpr'
genMultExpr (Times multExpr unaryExpr) = do
    a <- genMultExpr multExpr
    if isJust a then genPrimExpr $ fromJust a else emit ""
    emit "*"
    b <- genUnaryExpr unaryExpr
    res <- peSimpCalc genPrimExpr a b '*'
    return res
genMultExpr (Div multExpr unaryExpr) = do
    a <- genMultExpr multExpr
    if isJust a then genPrimExpr $ fromJust a else emit ""
    emit "/"
    b <- genUnaryExpr unaryExpr
    res <- peSimpCalc genPrimExpr a b '/'
    return res
genMultExpr (Mod multExpr unaryExpr) = do
    a <- genMultExpr multExpr
    if isJust a then genPrimExpr $ fromJust a else emit ""
    emit "%"
    b <- genUnaryExpr unaryExpr
    res <- peSimpCalc genPrimExpr a b '%'
    return res


-- | Unary operators
--
--   Spaces are removed in cleanup function along with semicolons
genUnaryExpr :: UnaryExpr -> JSCC (Maybe PrimaryExpr)
genUnaryExpr (PostFix postFix) = do
    postFix' <- genPostFix postFix
    return postFix'
genUnaryExpr (Delete unaryExpr) = do
    emit "delete "
    unaryExpr' <- genUnaryExpr unaryExpr
    genMaybe genPrimExpr unaryExpr'
    return Nothing
genUnaryExpr (Void unaryExpr) = do
    emit "void "
    unaryExpr' <- genUnaryExpr unaryExpr
    genMaybe genPrimExpr unaryExpr'
    return Nothing
genUnaryExpr (TypeOf unaryExpr) = do
    emit "typeof "
    unaryExpr' <- genUnaryExpr unaryExpr
    genMaybe genPrimExpr unaryExpr'
    return Nothing
genUnaryExpr (PlusPlus unaryExpr) = do
    emit " ++"
    unaryExpr' <- genUnaryExpr unaryExpr
    genMaybe genPrimExpr unaryExpr'
    return Nothing
genUnaryExpr (MinusMinus unaryExpr) = do
    emit " --"
    unaryExpr' <- genUnaryExpr unaryExpr
    genMaybe genPrimExpr unaryExpr'
    return Nothing
genUnaryExpr (UnaryPlus unaryExpr) = do
    emit "+"
    unaryExpr' <- genUnaryExpr unaryExpr
    genMaybe genPrimExpr unaryExpr'
    return Nothing
genUnaryExpr (UnaryMinus unaryExpr) = do
    emit "-"
    unaryExpr' <- genUnaryExpr unaryExpr
    genMaybe genPrimExpr unaryExpr'
    return Nothing
genUnaryExpr (Not unaryExpr) = do
    emit "!"
    unaryExpr' <- genUnaryExpr unaryExpr
    genMaybe genPrimExpr unaryExpr'
    return Nothing
genUnaryExpr (BitNot unaryExpr) = do
    emit "~"
    unaryExpr' <- genUnaryExpr unaryExpr
    genMaybe genPrimExpr unaryExpr'
    return Nothing


-- | Post fix
genPostFix :: PostFix -> JSCC (Maybe PrimaryExpr)
genPostFix (LeftExpr leftExpr) = do
    leftExpr' <- genLeftExpr leftExpr
    return leftExpr'
genPostFix (PostInc leftExpr)  = do
    leftExpr' <- genLeftExpr leftExpr
    genMaybe genPrimExpr leftExpr'
    emit "++ "
    return Nothing
genPostFix (PostDec leftExpr)  = do
    leftExpr' <- genLeftExpr leftExpr
    genMaybe genPrimExpr leftExpr'
    emit "-- "
    return Nothing