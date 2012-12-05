module ModRegex where

import Text.Regex.PCRE
import Data.Array((!))

{- | Replaces every occurance of the given regexp with the replacement string.

In the replacement string, @\"\\1\"@ refers to the first substring;
@\"\\2\"@ to the second, etc; and @\"\\0\"@ to the entire match.
@\"\\\\\\\\\"@ will insert a literal backslash.

This does not advance if the regex matches an empty string.  This
misfeature is here to match the behavior of the the original
Text.Regex API.

MODIFIED VERSION OF ORIGINAL subRegex FUNCTION IN Text.Regex
http://hackage.haskell.org/packages/archive/regex-compat/latest/doc/html/src/Text-Regex.html#subRegex

MODIFICATIONS
-------------
  - Changed order of arguments to suit chaining
  - Changed type of pattern input to reduce repetition of "pcreMkRegex" in main program
-}

pcreSubRegex :: String                         -- ^ Search pattern
             -> String                         -- ^ Replacement text
             -> String                         -- ^ Input string
             -> String                         -- ^ Output string
pcreSubRegex _ _ "" = ""
pcreSubRegex regexp repl inp =
  let compile _i str [] = \ _m ->  (str++)
      compile i str (("\\",(off,len)):rest) =
        let i' = off+len
            pre = take (off-i) str
            str' = drop (i'-i) str
        in if null str' then \ _m -> (pre ++) . ('\\':)
             else \  m -> (pre ++) . ('\\' :) . compile i' str' rest m
      compile i str ((xstr,(off,len)):rest) =
        let i' = off+len
            pre = take (off-i) str
            str' = drop (i'-i) str
            x = read xstr
        in if null str' then \ m -> (pre++) . ((fst (m!x))++)
             else \ m -> (pre++) . ((fst (m!x))++) . compile i' str' rest m
      compiled :: MatchText String -> String -> String
      compiled = compile 0 repl findrefs where
        -- bre matches a backslash then capture either a backslash or some digits
        bre = pcreMkRegex "\\\\(\\\\|[0-9]+)"
        findrefs = map (\m -> (fst (m!1),snd (m!0))) (matchAllText bre repl)
      go _i str [] = str
      go i str (m:ms) =
        let (_,(off,len)) = m!0
            i' = off+len
            pre = take (off-i) str
            str' = drop (i'-i) str
        in if null str' then pre ++ (compiled m "")
             else pre ++ (compiled m (go i' str' ms))
  in go 0 inp (matchAllText (pcreMkRegex regexp) inp)
      
-- | Makes a regular expression with the default options (multi-line,
-- case-sensitive).  The syntax of regular expressions is
-- otherwise that of @egrep@ (i.e. POSIX \"extended\" regular
-- expressions).

-- MODIFIED VERSION OF ORIGINAL mkRegex FUNCTION IN Text.Regex
-- http://hackage.haskell.org/packages/archive/regex-compat/latest/doc/html/src/Text-Regex.html#mkRegex
pcreMkRegex :: String -> Regex
pcreMkRegex s = makeRegexOpts opt defaultExecOpt s
  where opt = (defaultCompOpt + compCaseless)