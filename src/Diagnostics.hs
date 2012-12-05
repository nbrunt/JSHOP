{-
******************************************************************************
*                                      JSHOP                                 *
*                                                                            *
*   Module:   Diagnostics                                                    *
*   Purpose:  Diagnostic messages and computations (monad)                   *
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
******************************************************************************
-}

-- | Diagnostic messages and computations (monad)

module Diagnostics where

-- | Diagnostic computation. A computation with diagnostic output can
-- succeed or fail, and additionally yields a list of diagnostic messages.
newtype D a = D ([String] -> (Maybe a, [String]))

unD :: D a -> ([String] -> (Maybe a, [String]))
unD (D x) = x

instance Monad D where
    return a = D (\dms -> (Just a, dms))

    d >>= f = D (\dms ->
        case unD d dms of
            (Nothing, dms') -> (Nothing, dms')
            (Just a, dms')  -> unD (f a) dms')


-- | Runs a diagnostic computation. Returns:
--
-- (1) Result of the computation, if any.
--
-- (2) Sorted list of diagnostic messages.
runD :: D a -> (Maybe a, [String])
runD d = (ma, dms)
    where
        (ma, dms) = unD d []