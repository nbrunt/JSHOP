{-
******************************************************************************
*                                      JSHOP                                 *
*                                                                            *
*   Module:   CompUtils                                                      *
*   Purpose:  Compression utilities.  Various methods are employed including *
*             variable shrinking, string and number optimisation, and        *
*             partial evaluation.                                            *
*   Author:   Nick Brunt                                                     *
*                                                                            *
*                    Copyright (c) Nick Brunt, 2011 - 2012                   *
*              Subject to MIT License as stated in root directory            *
*                                                                            *
******************************************************************************
-}

-- | Compression utilities.  Various methods are employed including variable shrinking,
--   string and number optimisation, and partial evaluation.

module CompUtils where

-- Standard library imports
import Numeric (showHex)
import Data.Maybe

-- JSHOP module imports
import ParseTree
import CodeCompMonad

-- | Type synonum for the JS code compression monad
type JSCC a
    = CC String () a


-- | Higher-order helper function to handle Maybe types
genMaybe :: (a -> JSCC()) -> (Maybe a) -> JSCC()
genMaybe genFunc mbExpr
    = case mbExpr of
        Just expr -> genFunc expr
        Nothing   -> return ()

{- | Optimisation note:
    Literal numbers can be expressed in hexadecimal notation in JavaScript.
    Hex numbers begin with \"0x\" so are not always shorter.  To find the point
    at which it becomes shorter to express a number in hex, I wrote this function:

    > findPoint :: Integer -> IO ()
    > findPoint n = do
    >     let hex = "0x" ++ (showHex n "")
    >     if length (show n) > length hex
    >       then putStrLn $ hex ++ " (" ++ (show (length hex)) ++ ") is shorter than "
    >                       ++ show n ++ " (" ++ (show (length (show n))) ++ ")"
    >       else do
    >         putStrLn $ hex ++ " (" ++ (show (length hex)) ++ "), " ++ (show n)
    >                    ++ " (" ++ (show (length (show n))) ++ ")"
    >         findPoint (n+1)


    I ran it in ghci and this was the relevant result:

    > *Main> findPoint 999999999995
    > 0xe8d4a50ffb (12), 999999999995 (12)
    > 0xe8d4a50ffc (12), 999999999996 (12)
    > 0xe8d4a50ffd (12), 999999999997 (12)
    > 0xe8d4a50ffe (12), 999999999998 (12)
    > 0xe8d4a50fff (12), 999999999999 (12)
    > 0xe8d4a51000 (12) is shorter than 1000000000000 (13)

    The chances of there ever being a literal number this large expressed in a
    script is very low, but at least I've got it covered!  As far as I know, no
    other compressor does this.

    The maximum integer in JavaScript is 9007199254740992 so it is possible for this
    compression technique to take effect.
-}
compInt :: Integer -> String
compInt n = if n < 1000000000000 then show n
             else "0x" ++ showHex n ""


{- | Optimisation note:
    JavaScript strings can be wrapped in single or double quotes.  Escaping quotes
    requires an extra character (backslash), so it is sometimes possible to switch
    the type of quote used to wrap the string so that it is no longer necessary to
    escape.

    This function optimises strings with escaped quotes in them.
    For example:

    >    'te\'st'        -> "te'st"
    >    "te\"st"        -> 'te"st'
    >    "te'st\"in\"g"  -> 'tes\'st"in"g'
-}
compStr :: Maybe Char -> String -> String
compStr mbQ str =
    case mbQ of
        Nothing -> if length fullStr < length str then fullStr else str
        Just q  -> q:(genStrBody (init(tail str)) q) ++ [q]
    where
        origType  = head str
        altType   = if origType == '\'' then '"' else '\''
        qList     = getEscQ str
        qType     = if countElem origType qList > countElem altType qList
                     then altType
                     else origType
        strBody   = genStrBody (init(tail str)) qType
        fullStr   = qType:(strBody ++ [qType])

        genStrBody :: String -> Char -> String
        genStrBody [] _                 = []
        genStrBody ('\\':'\'':xs) '\''  = '\\':'\'':(genStrBody xs '\'')
        genStrBody ('\\':'\'':xs) qType = '\'':(genStrBody xs qType)
        genStrBody ('\'':xs) '\''       = '\\':'\'':(genStrBody xs '\'')
        genStrBody ('\'':xs) qType      = '\'':(genStrBody xs qType)
        genStrBody ('\\':'"':xs) '"'    = '\\':'"':(genStrBody xs '"')
        genStrBody ('\\':'"':xs) qType  = '"':(genStrBody xs qType)
        genStrBody ('"':xs) '"'         = '\\':'"':(genStrBody xs '"')
        genStrBody ('"':xs) qType       = '"':(genStrBody xs qType)
        genStrBody (x:xs) qType         = x:(genStrBody xs qType)

        getEscQ :: String -> [Char]
        getEscQ []              = []
        getEscQ ('\\':'\'':xs)  = '\'':(getEscQ xs)
        getEscQ ('\\':'"':xs)   = '"':(getEscQ xs)
        getEscQ (x:xs)          = getEscQ xs

        countElem :: Eq a => a -> [a] -> Int
        countElem i = length . filter (i==)


{- | Optimisation note:
    This function partially evaluates literal sums.
    For example:

    >    1 + 2            becomes 3
    >    -34.3 + 23.784   becomes -10.516
    >    34 * 12 / a      becomes 408/a

    KNOWN BUG:  Double arithmetic sometimes throws up silly results due to
    precision errors.

    > E.g. 0.2 + 0.1 gives 0.30000000000000004

    In these cases, the original sum will be displayed (if it is shorter).
    This is not ideal as 0.3 would be shorter still.  This is a documented bug:
    http://hackage.haskell.org/trac/ghc/ticket/5856
-}
peSimpCalc :: (PrimaryExpr -> JSCC()) -- ^ genPrimExpr function
           -> Maybe PrimaryExpr       -- ^ First operand
           -> Maybe PrimaryExpr       -- ^ Second operand
           -> Char                    -- ^ Operator
           -> JSCC (Maybe PrimaryExpr)
peSimpCalc gen (Just (ExpLiteral a)) (Just (ExpLiteral b)) op = do
    pop -- operator
    pop -- first operand
    let (x, mbY) = simpCalcLit a b op
    if litLength x > origLength then do
        genLiteral a
        emit [op]
        genLiteral b
        return Nothing
     else if isJust mbY then do
        genLiteral x
        emit [op]
        genLiteral $ fromJust mbY
        return Nothing
     else return $ Just (ExpLiteral x)
    where
        origLength  = litLength a + litLength b + 1  -- The 1 is the op

        litLength :: Literal -> Int
        litLength (LNull)    = 4 -- null
        litLength (LBool _)  = 2 -- !0 or !1
        litLength (LInt x)   = length $ show x
        litLength (LFloat x) = length $ dropPrefix $ show $ roundIfInt x
        litLength (LStr s)   = length s
peSimpCalc gen Nothing (Just (ExpLiteral b)) _
    = genLiteral b >> return Nothing
peSimpCalc gen _ (Just b) _
    = gen b >> return Nothing
peSimpCalc _ _ _ _
    = return Nothing


simpCalcLit :: Literal -> Literal -> Char -> (Literal, Maybe Literal)
simpCalcLit (LInt a)   (LInt b)   op
    = (LFloat (calcInt a b op), Nothing)
simpCalcLit (LInt a) (LFloat b) op
    = (LFloat (calcDouble (fromInteger a) b op), Nothing)
simpCalcLit (LFloat a) (LInt b) op
    = (LFloat (calcDouble a (fromInteger b) op), Nothing)
simpCalcLit (LFloat a) (LFloat b) op
    = (LFloat (calcDouble a b op), Nothing)
simpCalcLit (LStr a)   (LStr b)  '+'
    = (LStr (concatStr a b), Nothing)
simpCalcLit a b op
    = (a, Just b)

calcInt :: Integer -> Integer -> Char -> Double
calcInt x y '%' = fromInteger $ x `mod` y
calcInt x y op  = calcDouble (fromInteger x) (fromInteger y) op

calcDouble :: Double -> Double -> Char -> Double
calcDouble x y op = case op of
    '+' -> x + y
    '-' -> x - y
    '*' -> x * y
    '/' -> x / y
    _   -> 0

-- | Two literal strings can be concatenated, however their quote types may
--   be different.  This function sorts it all out!
concatStr :: String -> String -> String
concatStr x@('\'':xs)  ('\'':ys)   = init x ++ ys
concatStr x@('"':xs)   ('"':ys)    = init x ++ ys
concatStr x@('"':xs)   y@('\'':ys) = init x ++ (tail $ compStr (Just '"') y)
concatStr x@('\'':xs)  y@('"':ys)  = init x ++ (tail $ compStr (Just '\'') y)
concatStr x y = x ++ y

-- | Ints written as Doubles have \".0\" at the end, which is a waste of
--   chars, hence this function.
roundIfInt :: (RealFrac a, Integral b) => a -> Either a b
roundIfInt n = if isInt n then Right (round n) else Left n
    where
        isInt :: RealFrac a => a -> Bool
        isInt x = x == fromInteger (round x)

-- | Removes the first word from a string.  Useful for removing Eithers
--   or Maybes e.g. \"Left \", \"Right \", \"Just\", \"LInt\" etc.
dropPrefix :: String -> String
dropPrefix str = tail $ dropWhile (/=' ') str


{- | Literal

    Optimisation note (literal bools):
    True can be represented as 1 in JavaScript, however if you simply put 1, it will
    be assumed to be an integer.  Adding ! evaluates it as a boolean expression.
    Consequently, true can be expressed as \"not false\" and false can be
    expressed as \"not true\".
-}
genLiteral :: Literal -> JSCC()
genLiteral (LNull)        = emit "null"
genLiteral (LBool True)   = emit "!0"
genLiteral (LBool False)  = emit "!1"
genLiteral (LInt int)     = emit $ compInt int
genLiteral (LFloat float) = emit $ dropPrefix $ show $ roundIfInt float
genLiteral (LStr str)     = emit $ compStr Nothing str
