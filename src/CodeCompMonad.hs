{-
******************************************************************************
*                                      JSHOP                                 *
*                                                                            *
*   Module:   CodeCompMonad                                                  *
*   Purpose:  Code Compression Monad                                         *
*   Authors:  Nick Brunt, Henrik Nilsson                                     *
*                                                                            *
*                   Based (loosely) on the HMTC equivalent                   *
*                 Copyright (c) Henrik Nilsson, 2006 - 2011                  *
*                      http://www.cs.nott.ac.uk/~nhn/                        *
*                                                                            *
*                         Revisions for JavaScript                           *
*                    Copyright (c) Nick Brunt, 2011 - 2012                   *
*              Subject to MIT License as stated in root directory            *
*                                                                            *
******************************************************************************
-}

-- | Code compression monad. This module provides an abstraction for
-- code compression computations with support for generation of distinct
-- names, e.g. for variables and functions.

module CodeCompMonad (
                -- * Code generation computation
    CC,         -- Abstract. Instances: Monad.
    emit,       -- i -> CC i x ()
    runCC,      -- CC i x a -> (a, [i], [x])
                -- ** Compression functions
    pop,        -- CC String () String
    showState,  -- CC String () ()
    regID,      -- String -> CC String () ()
    incScope,   -- CC String () ()
    decScope,   -- Bool -> CC String () ()
    resetScope, -- CC String () ()
    emitID      -- String -> CC String () ()
) where

-- Standard library imports
import Data.List

------------------------------------------------------------------------------
-- Code generator state
------------------------------------------------------------------------------

data CCState i x
    = CCS {
        identifiers   :: [(Identifier, (Int,Int))],
                                -- ^ List of identifiers and their scope and level
        currentScope  :: Int,   -- ^ Increment this every time we enter a new block
        currentLevel  :: Int,   -- ^ Increment this every time we enter a new block
                                --   Decrement it every time we leave a block
        divs  :: [[i]],         -- ^ Diversions
        sect  :: [i],           -- ^ Current section
        aux   :: [x]            -- ^ Auxiliary stream
    }
    deriving Show

data Identifier
    = Variable {
        origName :: String,
        compName :: String
    }
    deriving Show

------------------------------------------------------------------------------
-- Code generator computation
------------------------------------------------------------------------------

-- | Code generation computation. Parameterised on the type of instructions
-- and additional auxiliary information. One use of the auxiliary information
-- is for additional separate output sections by instantiating with suitable
-- disjoint union type.

-- For example, Either can be used to implement prefix and suffix sections:
-- emitPfx i = emitAux (Left i), emitSfx = emitAux (Right i)
newtype CC i x a = CC (CCState i x -> (a, CCState i x))

unCC :: CC i x a -> (CCState i x -> (a, CCState i x))
unCC (CC f) = f


instance Monad (CC i x) where
    return a = CC $ \ccs -> (a, ccs)

    cc >>= f = CC $ \ccs ->
        let (a, ccs') = unCC cc ccs
        in unCC (f a) ccs'


-- | Return current state
get :: CC i x (CCState i x)
get = CC $ \ccs -> (ccs, ccs)


-- | Store given state
put :: (CCState i x) -> CC i x ()
put ccs = CC $ \ccs' -> ((), ccs)


-- | Pops the last item off the stack and returns it
pop :: CC String () String
pop = do
    ccs@(CCS {sect=(s:ss)}) <- get
    put $ ccs{sect=ss}
    return s


-- | Emit instruction
emit :: i -> CC i x ()
emit i = CC $ \ccs -> ((), ccs {sect = i : sect ccs})


-- | Increment the current scope and level
incScope :: CC String () ()
incScope = do
    ccs@(CCS {currentScope = cs, currentLevel = cl}) <- get
    put $ ccs {currentScope = cs+1, currentLevel = cl+1}


-- | Decrement the current scope.  Depending on the forget flag, forget all identifiers
--   from the previous scope.
decScope :: Bool -> CC String () ()
decScope forget = do
    ccs@(CCS {identifiers = ids, currentScope = cs, currentLevel = cl}) <- get
    let ids' = if forget then forgetScopes ids cs cl
                else ids
    put $ ccs {identifiers = ids', currentScope = cs, currentLevel = cl-1}
    where
        forgetScopes :: [(Identifier, (Int,Int))] -> Int -> Int -> [(Identifier, (Int,Int))]
        forgetScopes [] _ _ = []
        forgetScopes (x:xs) s l = if fst (snd x) <= s && snd (snd x) == l then
                                      forgetScopes xs s l
                                   else x:(forgetScopes xs s l)


-- | Reset the current scope and level to 0
resetScope :: CC String () ()
resetScope = CC $ \ccs -> ((), ccs {currentScope = 0, currentLevel = 0})


-- | Show the current code compression state
showState :: CC String () ()
showState = do
    emit "\n\n"
    CC $ \ccs -> ((), ccs {sect = (ppCCS ccs) : sect ccs})
    emit "\n\n"


-- | Register the given identifier as a known id
regID :: String -> CC String () ()
regID id = do
    ccs@(CCS {identifiers = ids, currentScope = cs, currentLevel = cl}) <- get
    put $ ccs {
        identifiers = ((Variable {
            origName = id,
            compName = ""
        }),(cs,cl)):ids
    }


-- | Given an id, scope and level, generate a compressed id
newID :: String                 -- ^ Original ID
      -> Int                    -- ^ Scope of original ID
      -> Int                    -- ^ Level of original ID
      -> CC String () String    -- ^ Return the compressed ID
newID origID s l = do
    ccs@(CCS {identifiers = ids, currentScope = cs, currentLevel = cl}) <- get
    -- Maybe remove l' <= cl condition.
    let usedIDs = [compName i | (i,(s',l')) <- ids, s' <= cs, l' <= cl] -- only from same scope or lower
    let compID = if l == 0 then -- 0 = global
                    origID
                  else
                    genID usedIDs genIDList
    let ids' = updateCompID origID s l compID ids
    put $ ccs {identifiers = ids'}
    return compID
    where
        updateCompID :: String -> Int -> Int -> String -> [(Identifier, (Int,Int))] -> [(Identifier, (Int,Int))]
        updateCompID _      _ _ _      [] = []
        updateCompID origID s l compID ((id,(s',l')):ids)
            = if origName id == origID && s' == s && l' == l then
                  ((Variable {origName = origID, compName = compID}), (s,l)):ids
               else
                  (id,(s',l')):(updateCompID origID s l compID ids)

        genID :: [String] -> [String] -> String
        genID [] idList        = head idList
        genID usedIDs (id:ids) = if elem id usedIDs then genID usedIDs ids
                                  else id


{- |
    Given the original ID, looks up the compressed ID.

    If there is no compressed ID, an attempt is made to create one.

    If the original ID is a library function or a global, the original is emitted.
-}
emitID :: String -> CC String () String
emitID origID = do
    ccs@(CCS {identifiers = ids, currentScope = cs, currentLevel = cl}) <- get
    let mbCompID = findCompID origID ids cs cl
    case mbCompID of
        Just (compID, (s,l)) -> if compID /= "" then
                                    return compID
                                 else do
                                    -- Generate new name
                                    compID' <- newID origID s l
                                    return compID'
        Nothing -> do
            -- Must be either a library function, or global var
            put $ ccs {
                identifiers = ((Variable {
                    origName = origID,
                    compName = origID
                }),(0,0)):ids
            }
            return origID
    where
        findCompID :: String -> [(Identifier, (Int,Int))] -> Int -> Int -> Maybe (String, (Int,Int))
        findCompID origID [] _ _                  = Nothing
        findCompID origID ((ids, (s,l)):xs) cs cl =
            if s <= cs && l <= cl && origID == (origName ids) then
                Just (compName ids, (s,l))
             else
                findCompID origID xs cs cl


-- | Run a code generation computation
runCC :: CC i x a -> (a, [i], [x])
runCC cc =
    let
        (a, ccs') = unCC cc ccs0
    in
        (a, joinSects (sect ccs' : divs ccs'), reverse (aux ccs'))
    where
        ccs0 = CCS {
            identifiers = [],
            currentScope = 0,
            currentLevel = 0,
            divs = [],
            sect = [],
            aux = []
        }


joinSects :: [[i]] -> [i]
joinSects []     = []
joinSects (s:ss) = jsAux (joinSects ss) s
    where
        jsAux is []      = is
        jsAux is (i:ris) = jsAux (i:is) ris


-- | Generates an infinite list of all possible identifier names
genIDList :: [String]
genIDList = [c:s | s <- "":allStrings, c <- firstChar] \\ reservedIDs
    where
        firstChar   = ['a'..'z']++['A'..'Z']++['_'] -- Technically the first char can be a '$' but this is
        -- monopolised by jQuery so I'll leave it out for simplicity
        -- Note: To make all var names unique, I could use a special character... Maybe 'λ'?
        -- Unfortunately this is not valid ASCII so it makes reading and writing files very difficult!
        alph        = ['a'..'z']++['A'..'Z']++['0'..'9']++['$','_']
        allStrings  = [c:s | s <- "":allStrings, c <- alph]
        reservedIDs = ["if","in","do","int","for","new","try","var"]
        -- There are obviously more, but none shorter than 4 letters.  A longer list would
        -- decrease performance unnecessarily.  Variables longer than 3 letters should never
        -- arise.
        -- >  length $ takeWhile (\xs -> length xs < 4) genIDList
        -- >  220525


-- | Pretty print the Code Compression state
ppCCS :: (CCState String ()) -> String
ppCCS (CCS {identifiers = ids, currentScope = cs, currentLevel = cl, divs = ds, sect = ss, aux = as})
    = "\n----------- CC State -----------\n\n"
    ++ "Current Scope: " ++ show cs ++ "\n\n"
    ++ "Current Level: " ++ show cl ++ "\n\n"
    ++ "Identifiers:\n" ++ ppIds ids ++ "\n\n"
    ++ "Divs: " ++ show ds ++ "\n\n"
    ++ "Sect: " ++ show ss ++ "\n\n"
    ++ "Aux: " ++ show as ++ "\n\n"
    ++ "---------------------------------\n"

-- | Pretty print the identifier list
ppIds :: [(Identifier, (Int,Int))] -> String
ppIds [] = ""
ppIds ((id,(s,l)):ids) = "  S" ++ show s ++ " L" ++ show l ++ ": " ++ show id ++ "\n" ++ ppIds ids

